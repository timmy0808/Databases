from __future__ import annotations
import json, uuid
from db import sqlserver_connection, postgres_connection
from config import settings

TABLES=[
('clinical.Patient','clinical.patient',['PatientId','ExternalPatientKey','BirthYear','BloodType','CreatedAt','UpdatedAt'],['patient_id','external_patient_key','birth_year','blood_type','created_at','updated_at']),
('clinical.Donor','clinical.donor',['DonorId','ExternalDonorKey','DonorType','BloodType','CreatedAt','UpdatedAt'],['donor_id','external_donor_key','donor_type','blood_type','created_at','updated_at']),
('clinical.TransplantCase','clinical.transplant_case',['TransplantCaseId','PatientId','DonorId','OrganType','CaseStatus','TransplantDate','CreatedAt','UpdatedAt'],['transplant_case_id','patient_id','donor_id','organ_type','case_status','transplant_date','created_at','updated_at']),
('clinical.DiagnosticResult','clinical.diagnostic_result',['DiagnosticResultId','TransplantCaseId','ResultType','ResultValue','ResultUnit','IsAbnormal','DiagnosticPayload','RecordedAt','UpdatedAt'],['diagnostic_result_id','transplant_case_id','result_type','result_value','result_unit','is_abnormal','diagnostic_payload','recorded_at','updated_at'])]

def convert(v, col):
    if v is None:return None
    if col in {'patient_id','donor_id','transplant_case_id','diagnostic_result_id'}: return uuid.UUID(str(v))
    if col=='diagnostic_payload': return json.loads(v) if isinstance(v,str) else v
    if col=='is_abnormal': return bool(v)
    return v

def main():
    total=0
    with sqlserver_connection() as src, postgres_connection() as tgt:
        run_id=tgt.execute("INSERT INTO migration.migration_run(migration_type) VALUES ('full_load') RETURNING migration_run_id").fetchone()[0]
        for src_table,tgt_table,src_cols,tgt_cols in TABLES:
            cur=src.cursor(); cur.execute(f"SELECT {','.join(src_cols)} FROM {src_table}")
            placeholders=','.join(['%s']*len(tgt_cols)); updates=','.join(f"{c}=EXCLUDED.{c}" for c in tgt_cols[1:])
            sql=f"INSERT INTO {tgt_table} ({','.join(tgt_cols)}) VALUES ({placeholders}) ON CONFLICT ({tgt_cols[0]}) DO UPDATE SET {updates}"
            while True:
                rows=cur.fetchmany(settings.batch_size)
                if not rows: break
                data=[tuple(convert(v,c) for v,c in zip(row,tgt_cols)) for row in rows]
                with tgt.cursor() as pc: pc.executemany(sql,data)
                total+=len(data); tgt.commit(); print(f'{tgt_table}: {total} total rows')
        tgt.execute("UPDATE migration.migration_run SET completed_at=CURRENT_TIMESTAMP,status='completed',rows_processed=%s WHERE migration_run_id=%s",(total,run_id)); tgt.commit()
    print(f'Full load complete: {total} rows.')

if __name__=='__main__': main()
