"""One report for a scheduled validation run: every test that failed, erred
or did not run, from the summary.txt of each part's validation-results
artifact (downloaded into one folder per artifact). Written to the run's
summary page on GitHub, so a red night says what needs looking at.

    python3 scripts/validation-report.py <folder of downloaded artifacts>
"""
import os
import pathlib
import sys

ATTENTION = ("FAIL ", "ERROR ", "NOT RUN ")


def report(root):
    parts = sorted(pathlib.Path(root).glob("*/summary.txt"))
    lines = ["## Validation: tests that need attention", ""]
    found = []
    totals = []
    for summary in parts:
        name = summary.parent.name
        for line in summary.read_text(encoding="utf-8").splitlines():
            if line.startswith("Totals:"):
                totals.append(f"- {name}: {line[len('Totals: '):]}")
            if line.startswith(ATTENTION):
                found.append(f"- {name}: {line.strip()}")
    if not parts:
        lines.append("No part saved a summary: the run stopped before any validation finished. Open the failed jobs.")
    elif found:
        lines += found
    else:
        lines.append("None: every test that ran passed or was skipped for a placeholder.")
    lines += ["", "### Totals by part", ""] + (totals or ["- none"])
    return "\n".join(lines) + "\n", bool(found) or not parts


if __name__ == "__main__":
    text, attention = report(sys.argv[1] if len(sys.argv) > 1 else "validation-artifacts")
    print(text)
    out = os.environ.get("GITHUB_STEP_SUMMARY")
    if out:
        with open(out, "a", encoding="utf-8") as f:
            f.write(text)
