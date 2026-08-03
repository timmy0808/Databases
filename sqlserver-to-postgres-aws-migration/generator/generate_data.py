from __future__ import annotations
import argparse, json, random, uuid
from datetime import datetime, timezone, timedelta
from faker import Faker
from db import sqlserver_connection

fake=Faker()
BLOOD=['A+','A-','B+','B-','AB+','AB-','O+','O-']
ORGANS=['kidney','heart','liver','lung','pancreas']
TESTS=[('creatinine','mg/dL',0.4,5.0),('donor_specific_antibody','MFI',0,20000),('tacrolimus','ng/mL',1,20),('alt','U/L',5,250)]

def main():
    p=argparse.ArgumentParser(); p.add_argument('--cases',type=int,default=100); p.add_argument('--results',type=int,default=1000)
    a=p.parse_args()
    with sqlserver_connection() as conn:
        c=conn.cursor(); cases=[]
        for i in range(a.cases):
            pid=str(uuid.uuid4()); did=str(uuid.uuid4()); cid=str(uuid.uuid4())
            c.execute("INSERT INTO clinical.Patient(PatientId,ExternalPatientKey,BirthYear,BloodType) VALUES (?,?,?,?)", pid,f'PAT-{i:06d}',random.randint(1940,2005),random.choice(BLOOD))
            c.execute("INSERT INTO clinical.Donor(DonorId,ExternalDonorKey,DonorType,BloodType) VALUES (?,?,?,?)", did,f'DON-{i:06d}',random.choice(['living','deceased']),random.choice(BLOOD))
            c.execute("INSERT INTO clinical.TransplantCase(TransplantCaseId,PatientId,DonorId,OrganType,TransplantDate) VALUES (?,?,?,?,?)", cid,pid,did,random.choice(ORGANS),fake.date_between(start_date='-5y',end_date='today'))
            cases.append(cid)
        for _ in range(a.results):
            test,unit,low,high=random.choice(TESTS); value=round(random.uniform(low,high),6); abnormal=value>(low+(high-low)*0.8)
            payload=json.dumps({'instrument':random.choice(['LambdaOne','LabSim-A','LabSim-B']),'quality_score':round(random.uniform(.8,1),4),'flag': 'high' if abnormal else 'normal'})
            recorded=datetime.now(timezone.utc)-timedelta(days=random.randint(0,365),minutes=random.randint(0,1440))
            c.execute("""INSERT INTO clinical.DiagnosticResult(DiagnosticResultId,TransplantCaseId,ResultType,ResultValue,ResultUnit,IsAbnormal,DiagnosticPayload,RecordedAt)
                         VALUES (?,?,?,?,?,?,?,?)""",str(uuid.uuid4()),random.choice(cases),test,value,unit,int(abnormal),payload,recorded)
        conn.commit()
    print(f'Generated {a.cases} cases and {a.results} diagnostic results.')

if __name__=='__main__': main()
