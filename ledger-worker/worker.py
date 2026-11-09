import logging
import os
import signal
import sys
import time

import psycopg
import redis

logging.basicConfig(
    stream=sys.stdout,
    level=os.environ.get("LOG_LEVEL", "INFO"),
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
log = logging.getLogger("ledger-worker")

DB_SETTINGS = {
    "host": os.environ["POSTGRES_HOST"],
    "port": os.environ["POSTGRES_PORT"],
    "dbname": os.environ["POSTGRES_DB"],
    "user": os.environ["POSTGRES_USER"],
    "password": os.environ["POSTGRES_PASSWORD"],
}
QUEUE = os.environ["REDIS_QUEUE"]
RETRY_DELAY_SECONDS = 2

running = True


def stop(signum, frame):
    global running
    running = False


def rejection_reason(accounts, from_account, to_account, amount, currency):
    if accounts[from_account]["currency"] != currency or accounts[to_account]["currency"] != currency:
        return "currency mismatch"
    if accounts[from_account]["balance"] < amount:
        return "insufficient funds"
    return None


def process_payment(payment_id):
    # Leaving this block commits the transaction, or rolls it back on an exception.
    with psycopg.connect(**DB_SETTINGS) as conn:
        payment = conn.execute(
            """
            SELECT from_account, to_account, amount, currency, status
            FROM payments WHERE id = %s FOR UPDATE
            """,
            (payment_id,),
        ).fetchone()
        if payment is None:
            log.warning("Payment %s not found, skipping", payment_id)
            return

        from_account, to_account, amount, currency, status = payment
        if status != "pending":
            log.info("Payment %s is already %s, skipping", payment_id, status)
            return

        # A consistent lock order stops two workers from deadlocking on the same accounts.
        rows = conn.execute(
            "SELECT id, balance, currency FROM accounts WHERE id = ANY(%s) ORDER BY id FOR UPDATE",
            ([from_account, to_account],),
        ).fetchall()
        accounts = {row[0]: {"balance": row[1], "currency": row[2]} for row in rows}

        reason = rejection_reason(accounts, from_account, to_account, amount, currency)
        if reason is None:
            conn.execute(
                "UPDATE accounts SET balance = balance - %s WHERE id = %s",
                (amount, from_account),
            )
            conn.execute(
                "UPDATE accounts SET balance = balance + %s WHERE id = %s",
                (amount, to_account),
            )
            new_status = "completed"
        else:
            new_status = "rejected"

        conn.execute(
            "UPDATE payments SET status = %s, processed_at = now() WHERE id = %s",
            (new_status, payment_id),
        )

    if reason is None:
        log.info("Payment %s completed", payment_id)
    else:
        log.info("Payment %s rejected: %s", payment_id, reason)


def main():
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    queue_client = redis.Redis(
        host=os.environ["REDIS_HOST"],
        port=int(os.environ["REDIS_PORT"]),
        decode_responses=True,
    )
    log.info("Ledger worker started, queue=%s", QUEUE)

    while running:
        try:
            item = queue_client.brpop(QUEUE, timeout=1)
        except redis.RedisError as error:
            log.warning("Redis is unavailable: %s", error)
            time.sleep(RETRY_DELAY_SECONDS)
            continue

        if item is None:
            continue

        payment_id = int(item[1])
        try:
            process_payment(payment_id)
        except psycopg.OperationalError as error:
            log.warning("Database is unavailable, requeueing payment %s: %s", payment_id, error)
            queue_client.rpush(QUEUE, payment_id)
            time.sleep(RETRY_DELAY_SECONDS)
        except Exception:
            log.exception("Failed to process payment %s", payment_id)

    log.info("Ledger worker stopped")


if __name__ == "__main__":
    main()
