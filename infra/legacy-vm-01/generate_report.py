#!/usr/bin/python3
# payments report for finance
import configparser
import datetime
import logging
import os

import psycopg2

CONFIG = "/opt/reports/etc/settings.ini"


def main():
    cfg = configparser.RawConfigParser()
    cfg.read(CONFIG)
    logging.basicConfig(
        filename=cfg.get("logging", "file"),
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
    )
    logging.info("report started")
    conn = psycopg2.connect(
        host=cfg.get("database", "host"),
        port=cfg.get("database", "port"),
        dbname=cfg.get("database", "dbname"),
        user=cfg.get("database", "user"),
        password=cfg.get("database", "password"),
    )
    cur = conn.cursor()
    cur.execute(
        "SELECT status, count(*), coalesce(sum(amount), 0) FROM payments "
        "WHERE created_at > now() - interval '1 day' GROUP BY status ORDER BY status"
    )
    rows = cur.fetchall()
    conn.close()

    name = datetime.datetime.now().strftime("report-%Y%m%d-%H%M.txt")
    path = os.path.join(cfg.get("output", "dir"), name)
    with open(path, "w") as out:
        out.write("FinSim payments, last 24 hours\n")
        for status, count, amount in rows:
            out.write("%-10s %8d %14s\n" % (status, count, amount))
    logging.info("report written to %s", path)


if __name__ == "__main__":
    main()
