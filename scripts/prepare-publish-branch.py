"""Prepare a fast-forward deployment commit; never push or rewrite history.

The deployment branch contains checked main source plus its generated manifest.
This lets main require PR checks without exempting an app or creating credentials.
"""
import json
from pathlib import Path
import subprocess
import sys

MANIFEST = "app/routing/manifest.json"
BRANCH = "connect-cloud"


def git(*args, check=True):
    return subprocess.run(["git", *args], check=check, text=True, capture_output=True)


def prepare(head):
    manifest = Path(MANIFEST).read_bytes()
    record = json.loads(manifest)
    if record["packages"]["powerkit"]["description"].get("RemoteSha") != head:
        raise RuntimeError("The generated manifest must pin the selected main commit.")
    git("fetch", "origin", "main")
    if git("rev-parse", "origin/main").stdout.strip() != head:
        raise RuntimeError("Main moved while the manifest was building; publish its newer run instead.")
    exists = git("ls-remote", "--exit-code", "--heads", "origin", BRANCH, check=False).returncode
    if exists not in (0, 2):
        raise RuntimeError("Could not inspect the deployment branch; nothing was published.")
    # Remove only the generated manifest in this disposable CI checkout,
    # before switching branches. The bytes above are restored below. Main
    # doesn't track it (it is in .gitignore there); an older main did.
    if git("ls-files", "--error-unmatch", MANIFEST, check=False).returncode == 0:
        git("restore", "--", MANIFEST)
    else:
        Path(MANIFEST).unlink()
    if exists == 0:
        git("fetch", "origin", f"{BRANCH}:refs/remotes/origin/{BRANCH}")
        git("switch", "-c", BRANCH, f"origin/{BRANCH}")
        merged = git("merge", "--no-ff", "--no-commit", head, check=False)
        conflicts = git("diff", "--name-only", "--diff-filter=U").stdout.splitlines()
        if merged.returncode and conflicts != [MANIFEST]:
            raise RuntimeError("Deployment source did not merge cleanly; nothing was published.")
    else:
        git("switch", "-c", BRANCH, head)
    Path(MANIFEST).write_bytes(manifest)
    git("add", "--force", MANIFEST)
    merging = git("rev-parse", "--verify", "--quiet", "MERGE_HEAD", check=False).returncode == 0
    changed = git("diff", "--cached", "--quiet", check=False).returncode != 0
    if merging or changed:
        git("commit", "-m", f"Publish checked main {head[:12]} to Connect Cloud")
    git("diff", "--exit-code", head, "HEAD", "--", ".", f":(exclude){MANIFEST}")
    return git("rev-parse", "HEAD").stdout.strip()


if __name__ == "__main__":
    print(prepare(sys.argv[1]))
