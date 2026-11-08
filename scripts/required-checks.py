"""Aggregate actual job outcomes; dependency skips must not become green CI."""
import json
import os


def accepted(kind, needs):
    if kind == "app":
        result = lambda n: needs.get(n, {}).get("result")
        if "changes" not in needs:
            return all(result(n) == "success" for n in ("image", "app-tests", "browser-tests"))
        if result("changes") != "success" or result("image") != "success":
            return False
        docs_only = needs["changes"].get("outputs", {}).get("docs_only")
        if docs_only == "true":
            return result("docs-tests") == "success" and all(result(n) == "skipped" for n in ("app-tests", "browser-tests"))
        if docs_only == "false":
            return result("docs-tests") == "skipped" and all(result(n) == "success" for n in ("app-tests", "browser-tests"))
        return False
    if kind != "engine" or needs.get("changes", {}).get("result") != "success":
        return False
    changed = needs["changes"].get("outputs", {}).get("engine")
    expected = "success" if changed == "true" else "skipped" if changed == "false" else None
    return expected is not None and all(needs.get(n, {}).get("result") == expected
        for n in ("image", "R-CMD-check", "engine-tests"))


if __name__ == "__main__":
    if not accepted(os.environ["CHECK_KIND"], json.loads(os.environ["NEEDS_JSON"])):
        raise SystemExit("Required checks did not all complete successfully; dependency skips are not passes.")
    print("Required checks passed, or a change detector explicitly found nothing they test changed.")
