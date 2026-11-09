import logging
import os
import random
import signal
import sys
import threading

import requests

logging.basicConfig(
    stream=sys.stdout,
    level=os.environ.get("LOG_LEVEL", "INFO"),
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
log = logging.getLogger("load-generator")

API_URL = os.environ.get("API_URL", "http://nginx").rstrip("/")
ENABLED = os.environ.get("ENABLED", "true").strip().lower() in ("1", "true", "yes", "on")
RPS = float(os.environ.get("RPS", "1"))
ACCOUNT_COUNT = 10
REQUEST_TIMEOUT_SECONDS = 5
MAX_REMEMBERED_PAYMENTS = 100

stop_event = threading.Event()
payment_ids = []


def random_payment():
    from_account, to_account = random.sample(range(1, ACCOUNT_COUNT + 1), 2)
    # Most payments are small; a few are large or in another currency, so some get rejected.
    amount = round(random.uniform(1, 200), 2)
    if random.random() < 0.05:
        amount = round(random.uniform(20000, 50000), 2)
    currency = "EUR" if random.random() < 0.05 else "USD"
    return {
        "from_account": from_account,
        "to_account": to_account,
        "amount": amount,
        "currency": currency,
    }


def create_payment():
    response = requests.post(
        f"{API_URL}/payments", json=random_payment(), timeout=REQUEST_TIMEOUT_SECONDS
    )
    log.info("POST /payments -> %s", response.status_code)
    if response.status_code == 201:
        payment_ids.append(response.json()["id"])
        del payment_ids[:-MAX_REMEMBERED_PAYMENTS]


def read_payment():
    if not payment_ids:
        create_payment()
        return
    payment_id = random.choice(payment_ids)
    response = requests.get(f"{API_URL}/payments/{payment_id}", timeout=REQUEST_TIMEOUT_SECONDS)
    log.info("GET /payments/%s -> %s", payment_id, response.status_code)


def read_balance():
    account_id = random.randint(1, ACCOUNT_COUNT)
    response = requests.get(
        f"{API_URL}/accounts/{account_id}/balance", timeout=REQUEST_TIMEOUT_SECONDS
    )
    log.info("GET /accounts/%s/balance -> %s", account_id, response.status_code)


def send_random_request():
    action = random.choices([create_payment, read_payment, read_balance], weights=[70, 20, 10])[0]
    try:
        action()
    except requests.RequestException as error:
        log.warning("Request failed: %s", error)


def handle_stop(signum, frame):
    stop_event.set()


def main():
    signal.signal(signal.SIGTERM, handle_stop)
    signal.signal(signal.SIGINT, handle_stop)

    if not ENABLED:
        log.info("Load generator is disabled (ENABLED=false), idling")
        stop_event.wait()
        return

    if RPS <= 0:
        log.error("RPS must be greater than 0, got %s", RPS)
        sys.exit(1)

    interval = 1 / RPS
    log.info("Load generator started: RPS=%s, target=%s", RPS, API_URL)
    while not stop_event.wait(interval):
        send_random_request()


if __name__ == "__main__":
    main()
