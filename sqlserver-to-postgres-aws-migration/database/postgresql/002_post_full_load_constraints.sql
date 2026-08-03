ALTER TABLE clinical.transplant_case
    ADD CONSTRAINT fk_transplant_case_patient
    FOREIGN KEY (patient_id) REFERENCES clinical.patient(patient_id) NOT VALID,
    ADD CONSTRAINT fk_transplant_case_donor
    FOREIGN KEY (donor_id) REFERENCES clinical.donor(donor_id) NOT VALID;

ALTER TABLE clinical.diagnostic_result
    ADD CONSTRAINT fk_diagnostic_result_case
    FOREIGN KEY (transplant_case_id)
    REFERENCES clinical.transplant_case(transplant_case_id) NOT VALID;

ALTER TABLE clinical.transplant_case VALIDATE CONSTRAINT fk_transplant_case_patient;
ALTER TABLE clinical.transplant_case VALIDATE CONSTRAINT fk_transplant_case_donor;
ALTER TABLE clinical.diagnostic_result VALIDATE CONSTRAINT fk_diagnostic_result_case;

ANALYZE clinical.patient;
ANALYZE clinical.donor;
ANALYZE clinical.transplant_case;
ANALYZE clinical.diagnostic_result;
ANALYZE audit.audit_event;
