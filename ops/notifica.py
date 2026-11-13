#!/usr/bin/env python3
"""Email a Filippo quando l'articolo settimanale non va a buon fine.

    ops/notifica.py --failed-unit matteobertacca-articolo.service   # lo usa matteobertacca-avviso@.service
    ops/notifica.py --test                                          # prova la configurazione

Legge dall'ambiente (systemd: EnvironmentFile=%h/.secrets/matteobertacca.env; a mano: direnv).
Si salvano con `erin secret set matteobertacca <KEY>`:

    ALERT_EMAIL     dove arrivano gli avvisi, ed è anche l'account Gmail che li manda
    SMTP_PASSWORD   una password per le app di Google per quell'account
    SMTP_HOST       facoltativo, default smtp.gmail.com (porta 465, TLS)

Solo libreria standard, così funziona con il Python di sistema anche se node_modules è rotto.
"""
from __future__ import annotations

import argparse
import os
import smtplib
import ssl
import subprocess
import sys
from datetime import datetime
from email.message import EmailMessage
from email.utils import formatdate, make_msgid
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LOG_DIR = ROOT / "ops" / "logs"
SITE = "https://matteobertacca.com/"


def tail(path: Path, lines: int = 60) -> str:
    try:
        return "\n".join(path.read_text(encoding="utf-8", errors="replace").splitlines()[-lines:])
    except OSError:
        return f"({path} non leggibile)"


def journal(unit: str, lines: int = 30) -> str:
    try:
        out = subprocess.run(["journalctl", "--user", "-u", unit, "-n", str(lines), "--no-pager", "-o", "short-iso"],
                             capture_output=True, text=True, timeout=30)
        return out.stdout.strip() or out.stderr.strip()
    except (OSError, subprocess.SubprocessError) as exc:
        return f"(journalctl non riuscito: {exc})"


def failure_message(unit: str) -> tuple[str, str]:
    logs = sorted(LOG_DIR.glob("articolo-*.log"), key=lambda p: p.stat().st_mtime)
    log = logs[-1] if logs else None
    body = "\n".join([
        f"{unit} non è andato a buon fine il {datetime.now().astimezone():%d/%m/%Y alle %H:%M}.",
        "",
        "L'articolo di questa settimana non è stato pubblicato: lo script annulla tutte le modifiche",
        "quando qualcosa va storto, quindi il sito è com'era prima.",
        "",
        "Per riprovare, sulla macchina: systemctl --user start matteobertacca-articolo.service",
        "(oppure chiedilo a Claude nella sessione erinos-matteobertacca).",
        "",
        f"Sito: {SITE}",
        f"Log: {log or LOG_DIR}",
        "",
        f"--- ultime righe di {log.name if log else 'log'} ---",
        tail(log) if log else "(nessun log trovato)",
        "",
        f"--- journalctl --user -u {unit} ---",
        journal(unit),
    ])
    return "matteobertacca.com: articolo della settimana non pubblicato", body


def send(subject: str, body: str) -> None:
    to = os.environ.get("ALERT_EMAIL")
    password = os.environ.get("SMTP_PASSWORD")
    if not to or not password:
        sys.exit("ALERT_EMAIL o SMTP_PASSWORD mancanti: erin secret set matteobertacca ALERT_EMAIL / SMTP_PASSWORD")
    msg = EmailMessage()
    # Nome del mittente senza punti: «matteobertacca.com» sembrava un altro dominio e Gmail ha rifiutato
    # la copia inoltrata (550 5.7.30, DKIM). Date e Message-ID esplicite per lo stesso motivo.
    msg["From"] = f"Sito Matteo Bertacca <{to}>"
    msg["To"] = to
    msg["Subject"] = subject
    msg["Date"] = formatdate(localtime=True)
    msg["Message-ID"] = make_msgid(domain=to.split("@")[-1])
    msg.set_content(body)
    with smtplib.SMTP_SSL(os.environ.get("SMTP_HOST", "smtp.gmail.com"), 465,
                          context=ssl.create_default_context(), timeout=30) as smtp:
        smtp.login(to, password)
        smtp.send_message(msg)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--failed-unit")
    ap.add_argument("--test", action="store_true")
    args = ap.parse_args()
    if args.test:
        send("matteobertacca.com: prova degli avvisi",
             "Se leggi questa email, gli avvisi dell'articolo settimanale funzionano.")
    elif args.failed_unit:
        send(*failure_message(args.failed_unit))
    else:
        ap.error("serve --failed-unit o --test")
    print("email inviata")


if __name__ == "__main__":
    main()
