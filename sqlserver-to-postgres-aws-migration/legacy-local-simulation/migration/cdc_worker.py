from __future__ import annotations
import argparse, json, time, uuid
from db import sqlserver_connection, postgres_connection
from config import settings

CONSUMER='diagnostic-result-worker'

def apply_change(src,tgt,change_id,op,key):
    if op=='D':
        tgt.execute('DELETE FROM clinical.diagnostic_result WHERE diagnostic_result_id=%s',(uuid.UUID(key),)); return
    row=src.cursor().execute("""SELECT DiagnosticResultId,TransplantCaseId,ResultType,ResultValue,ResultUnit,IsAbnormal,DiagnosticPayload,RecordedAt,UpdatedAt
                              FROM clinical.DiagnosticResult WHERE DiagnosticResultId=?""",key).fetchone()
    if not row:return
    vals=(uuid.UUID(str(row[0])),uuid.UUID(str(row[1])),row[2],row[3],row[4],bool(row[5]),json.loads(row[6]) if row[6] else None,row[7],row[8])
    tgt.execute("""INSERT INTO clinical.diagnostic_result(diagnostic_result_id,transplant_case_id,result_type,result_value,result_unit,is_abnormal,diagnostic_payload,recorded_at,updated_at)
                   VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
                   ON CONFLICT(diagnostic_result_id) DO UPDATE SET
                   transplant_case_id=EXCLUDED.transplant_case_id,result_type=EXCLUDED.result_type,result_value=EXCLUDED.result_value,
                   result_unit=EXCLUDED.result_unit,is_abnormal=EXCLUDED.is_abnormal,diagnostic_payload=EXCLUDED.diagnostic_payload,
                   recorded_at=EXCLUDED.recorded_at,updated_at=EXCLUDED.updated_at,version_number=clinical.diagnostic_result.version_number+1""",vals)

def cycle(limit=500):
    with sqlserver_connection() as src, postgres_connection() as tgt:
        last=tgt.execute("SELECT last_change_id FROM migration.cdc_checkpoint WHERE consumer_name=%s",(CONSUMER,)).fetchone()
        last=last[0] if last else 0
        rows=src.cursor().execute("SELECT TOP (?) ChangeId,OperationType,PrimaryKeyValue FROM migration.ChangeQueue WHERE ChangeId>? ORDER BY ChangeId",limit,last).fetchall()
        for cid,op,key in rows:
            apply_change(src,tgt,cid,op,key); last=cid
        if rows:
            tgt.execute("""INSERT INTO migration.cdc_checkpoint(consumer_name,last_change_id) VALUES (%s,%s)
                           ON CONFLICT(consumer_name) DO UPDATE SET last_change_id=EXCLUDED.last_change_id,updated_at=CURRENT_TIMESTAMP""",(CONSUMER,last)); tgt.commit()
            src.cursor().execute("UPDATE migration.ChangeQueue SET Processed=1,ProcessedAt=SYSUTCDATETIME() WHERE ChangeId<=?",last); src.commit()
        return len(rows)

def main():
    p=argparse.ArgumentParser(); p.add_argument('--once',action='store_true'); a=p.parse_args()
    while True:
        n=cycle(); print(f'Applied {n} CDC changes.')
        if a.once: break
        time.sleep(settings.cdc_poll_seconds)

if __name__=='__main__': main()
