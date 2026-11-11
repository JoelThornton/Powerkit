"""Create an exact checked-source deployment commit without changing the checkout.

The deployment history is preserved as a parent; only the generated manifest
differs from checked main. Temporary package setup files and local edits never
enter the snapshot. This script never pushes or updates a branch.
"""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

MANIFEST = "app/routing/manifest.json"
BRANCH = "connect-cloud"


def git(*args, check=True, **kwargs):
    result = subprocess.run(["git", *args], text=True, capture_output=True, **kwargs)
    if check and result.returncode:
        raise RuntimeError(f"git {' '.join(args)} failed: {result.stderr.strip()}")
    return result


def prepare(head):
    record = json.loads(Path(MANIFEST).read_bytes())
    if record["packages"]["powerkit"]["description"].get("RemoteSha") != head:
        raise RuntimeError("The generated manifest must pin the selected main commit.")
    git("fetch", "origin", "main")
    if git("rev-parse", "origin/main").stdout.strip() != head:
        raise RuntimeError("Main moved while the manifest was building; publish its newer run instead.")
    exists = git("ls-remote", "--exit-code", "--heads", "origin", BRANCH, check=False).returncode
    if exists not in (0, 2):
        raise RuntimeError("Could not inspect the deployment branch; nothing was published.")
    previous = None
    if exists == 0:
        git("fetch", "origin", f"{BRANCH}:refs/remotes/origin/{BRANCH}")
        previous = git("rev-parse", f"origin/{BRANCH}").stdout.strip()
    # Build the tree from the checked commit, never the build's working tree
    # or normal index. renv/setup tools may have modified tracked files.
    blob = git("hash-object", "-w", "--", MANIFEST).stdout.strip()
    with tempfile.TemporaryDirectory(prefix="powerkit-publish-index-") as folder:
        env = dict(os.environ, GIT_INDEX_FILE=str(Path(folder) / "index"))
        git("read-tree", head, env=env)
        git("update-index", "--add", "--cacheinfo", f"100644,{blob},{MANIFEST}", env=env)
        tree = git("write-tree", env=env).stdout.strip()
    if previous and git("rev-parse", f"{previous}^{{tree}}").stdout.strip() == tree:
        if git("merge-base", "--is-ancestor", head, previous, check=False).returncode == 0:
            return previous
    parents = [previous, head] if previous and previous != head else [head]
    args = ["commit-tree", tree]
    for parent in parents:
        args.extend(["-p", parent])
    published = git(*args, input=f"Publish checked main {head[:12]} to Connect Cloud\n").stdout.strip()
    git("diff", "--exit-code", head, published, "--", ".", f":(exclude){MANIFEST}")
    return published


if __name__ == "__main__":
    print(prepare(sys.argv[1]))
