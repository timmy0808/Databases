from pathlib import Path
import re
from db import sqlserver_connection, postgres_connection

ROOT=Path(__file__).resolve().parents[1]

def run_sqlserver_file(path: Path, database: str):
    text=path.read_text(encoding="utf-8")
    batches=re.split(r"^\s*GO\s*$", text, flags=re.MULTILINE|re.IGNORECASE)
    with sqlserver_connection(database) as conn:
        cur=conn.cursor()
        for batch in batches:
            if batch.strip(): cur.execute(batch)
        conn.commit()


def main():
    run_sqlserver_file(ROOT/'database/sqlserver/001_create_database.sql', 'master')
    run_sqlserver_file(ROOT/'database/sqlserver/002_source_schema.sql', 'TransplantDiagnostics')
    with postgres_connection() as conn:
        conn.execute((ROOT/'database/postgresql/001_target_schema.sql').read_text())
        conn.commit()
    print('Source and target schemas created.')

if __name__=='__main__': main()
