from __future__ import annotations
import json
from pathlib import Path
from db import sqlserver_connection, postgres_connection

MAP=[('clinical.Patient','clinical.patient'),('clinical.Donor','clinical.donor'),('clinical.TransplantCase','clinical.transplant_case'),('clinical.DiagnosticResult','clinical.diagnostic_result')]

def main():
    report={'tables':[],'passed':True}
    with sqlserver_connection() as s, postgres_connection() as p:
        for st,pt in MAP:
            sc=s.cursor().execute(f'SELECT COUNT_BIG(*) FROM {st}').fetchone()[0]
            pc=p.execute(f'SELECT COUNT(*) FROM {pt}').fetchone()[0]
            ok=sc==pc; report['tables'].append({'source':st,'target':pt,'source_count':sc,'target_count':pc,'status':'PASS' if ok else 'FAIL'}); report['passed'] &= ok
        orphan=p.execute("SELECT COUNT(*) FROM clinical.diagnostic_result d LEFT JOIN clinical.transplant_case c ON c.transplant_case_id=d.transplant_case_id WHERE c.transplant_case_id IS NULL").fetchone()[0]
        invalid_json=p.execute("SELECT COUNT(*) FROM clinical.diagnostic_result WHERE diagnostic_payload IS NOT NULL AND NOT pg_input_is_valid(diagnostic_payload, 'jsonb')").fetchone()[0]
        report['business_checks']={'orphan_diagnostics':orphan,'invalid_json':invalid_json}; report['passed'] &= orphan==0 and invalid_json==0
    out=Path('reports'); out.mkdir(exist_ok=True); (out/'validation-report.json').write_text(json.dumps(report,indent=2,default=str))
    for r in report['tables']: print(f"{r['source']:<35} {r['source_count']:>8} -> {r['target_count']:<8} {r['status']}")
    print('Overall:', 'PASS' if report['passed'] else 'FAIL')
    raise SystemExit(0 if report['passed'] else 1)

if __name__=='__main__': main()
