import logging
import os
import sys
from decimal import Decimal

import psycopg
import redis
import uvicorn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from uvicorn.config import LOGGING_CONFIG

logging.basicConfig(
    stream=sys.stdout,
    level=os.environ.get("LOG_LEVEL", "INFO"),
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
log = logging.getLogger("payments-api")

DB_SETTINGS = {
    "host": os.environ["POSTGRES_HOST"],
    "port": os.environ["POSTGRES_PORT"],
    "dbname": os.environ["POSTGRES_DB"],
    "user": os.environ["POSTGRES_USER"],
    "password": os.environ["POSTGRES_PASSWORD"],
}
QUEUE = os.environ["REDIS_QUEUE"]
queue_client = redis.Redis(
    host=os.environ["REDIS_HOST"],
    port=int(os.environ["REDIS_PORT"]),
    decode_responses=True,
)

MAX_ACCOUNT_ID = 2**31 - 1
PAYMENT_COLUMNS = "id, from_account, to_account, amount, currency, status"

app = FastAPI(title="FinSim Payments API")


class PaymentRequest(BaseModel):
    from_account: int = Field(gt=0, le=MAX_ACCOUNT_ID)
    to_account: int = Field(gt=0, le=MAX_ACCOUNT_ID)
    amount: Decimal = Field(gt=0, max_digits=14, decimal_places=2)
    currency: str = Field(pattern="^[A-Z]{3}$")


def payment_to_dict(row):
    return {
        "id": row[0],
        "from_account": row[1],
        "to_account": row[2],
        # Money is returned as a string so JSON floats cannot change the value.
        "amount": str(row[3]),
        "currency": row[4],
        "status": row[5],
    }


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/payments", status_code=201)
def create_payment(payment: PaymentRequest):
    if payment.from_account == payment.to_account:
        raise HTTPException(status_code=422, detail="from_account and to_account must differ")

    try:
        with psycopg.connect(**DB_SETTINGS) as conn:
            row = conn.execute(
                f"""
                INSERT INTO payments (from_account, to_account, amount, currency, status)
                VALUES (%s, %s, %s, %s, 'pending')
                RETURNING {PAYMENT_COLUMNS}
                """,
                (payment.from_account, payment.to_account, payment.amount, payment.currency),
            ).fetchone()
    except psycopg.errors.ForeignKeyViolation:
        raise HTTPException(status_code=404, detail="Account not found")

    queue_client.lpush(QUEUE, row[0])
    log.info("Payment %s created and queued", row[0])
    return payment_to_dict(row)


@app.get("/payments/{payment_id}")
def get_payment(payment_id: int):
    with psycopg.connect(**DB_SETTINGS) as conn:
        row = conn.execute(
            f"SELECT {PAYMENT_COLUMNS} FROM payments WHERE id = %s",
            (payment_id,),
        ).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Payment not found")
    return payment_to_dict(row)


@app.get("/accounts/{account_id}/balance")
def get_balance(account_id: int):
    with psycopg.connect(**DB_SETTINGS) as conn:
        row = conn.execute(
            "SELECT balance, currency FROM accounts WHERE id = %s",
            (account_id,),
        ).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Account not found")
    return {"account_id": account_id, "balance": str(row[0]), "currency": row[1]}


if __name__ == "__main__":
    # Uvicorn sends its own server logs to stderr by default.
    LOGGING_CONFIG["handlers"]["default"]["stream"] = "ext://sys.stdout"
    uvicorn.run(app, host="0.0.0.0", port=8000)
