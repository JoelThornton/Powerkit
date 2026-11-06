import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("gates", Path(__file__).with_name("required-checks.py"))
gates = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gates)


class GateTests(unittest.TestCase):
    def test_app_requires_every_dependency(self):
        needs = {k: {"result": "success"} for k in ("image", "app-tests", "browser-tests")}
        self.assertTrue(gates.accepted("app", needs))
        for key in needs:
            for status in ("failure", "cancelled", "skipped"):
                changed = {k: dict(v) for k, v in needs.items()}
                changed[key]["result"] = status
                self.assertFalse(gates.accepted("app", changed))

    def test_engine_skips_are_allowed_only_after_successful_no_change_detection(self):
        needs = {k: {"result": "skipped"} for k in ("image", "R-CMD-check", "engine-tests")}
        needs["changes"] = {"result": "success", "outputs": {"engine": "false"}}
        self.assertTrue(gates.accepted("engine", needs))
        needs["changes"]["outputs"]["engine"] = "true"
        self.assertFalse(gates.accepted("engine", needs))
        for key in ("image", "R-CMD-check", "engine-tests"):
            needs[key]["result"] = "success"
        self.assertTrue(gates.accepted("engine", needs))
        needs["changes"]["result"] = "failure"
        self.assertFalse(gates.accepted("engine", needs))


if __name__ == "__main__":
    unittest.main()
