import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def test_dms_task_is_full_load_and_cdc_in_terraform():
    text = (ROOT / "terraform" / "dms.tf").read_text()
    assert 'migration_type            = "full-load-and-cdc"' in text

def test_validation_enabled():
    settings = json.loads((ROOT / "dms" / "tasks" / "task-settings.json").read_text())
    assert settings["ValidationSettings"]["EnableValidation"] is True
    assert settings["ValidationSettings"]["ValidationMode"] == "ROW_LEVEL"

def test_required_schemas_selected():
    mapping = json.loads((ROOT / "dms" / "tasks" / "table-mappings.json").read_text())
    selected = {
        r["object-locator"]["schema-name"]
        for r in mapping["rules"]
        if r["rule-type"] == "selection"
    }
    assert {"clinical", "audit"}.issubset(selected)

def test_target_prep_does_not_replace_converted_schema():
    settings = json.loads((ROOT / "dms" / "tasks" / "task-settings.json").read_text())
    assert settings["FullLoadSettings"]["TargetTablePrepMode"] == "DO_NOTHING"
