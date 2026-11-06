"""Aggregate actual job outcomes; dependency skips must not become green CI."""
import json
import os


def accepted(kind, needs):
    if kind == "app":
        return all(needs.get(n, {}).get("result") == "success" for n in ("image", "app-tests", "browser-tests"))
    if kind != "engine" or needs.get("changes", {}).get("result") != "success":
        return False
    changed = needs["changes"].get("outputs", {}).get("engine")
    expected = "success" if changed == "true" else "skipped" if changed == "false" else None
    return expected is not None and all(needs.get(n, {}).get("result") == expected
        for n in ("image", "R-CMD-check", "engine-tests"))


if __name__ == "__main__":
    if not accepted(os.environ["CHECK_KIND"], json.loads(os.environ["NEEDS_JSON"])):
        raise SystemExit("Required checks did not all complete successfully; dependency skips are not passes.")
    print("Required checks passed, or the engine change detector explicitly found no engine changes.")
