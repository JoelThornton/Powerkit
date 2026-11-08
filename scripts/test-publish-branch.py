import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("publisher", Path(__file__).with_name("prepare-publish-branch.py"))
publisher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(publisher)


class PublishingTests(unittest.TestCase):
    def test_first_publish_then_update_preserves_history_and_exact_main_source(self):
        original = Path.cwd()
        with tempfile.TemporaryDirectory(prefix="powerkit-publish-check-") as folder:
            folder = Path(folder).resolve()
            def run(where, *args):
                return subprocess.check_output(["git", "-C", str(where), *args], text=True, stderr=subprocess.DEVNULL).strip()
            origin, source = folder / "origin.git", folder / "source"
            origin.mkdir(); source.mkdir()
            run(origin, "init", "--bare")
            run(source, "init", "-b", "main")
            run(source, "config", "user.name", "Fixture")
            run(source, "config", "user.email", "fixture@example.invalid")
            (source / "app/routing").mkdir(parents=True)
            (source / publisher.MANIFEST).write_text("{}")
            (source / "app/routing/app.R").write_text("checked source one")
            run(source, "add", "."); run(source, "commit", "-m", "First checked source")
            run(source, "remote", "add", "origin", str(origin)); run(source, "push", "origin", "main")
            previous = None
            try:
                # 1: main tracks a manifest (as it did before 8 November 2026);
                # 2: main stops tracking it and ignores it; 3: main without it.
                for i in (1, 2, 3):
                    if i == 2:
                        (source / "app/routing/app.R").write_text("checked source two")
                        run(source, "rm", "-q", publisher.MANIFEST)
                        (source / ".gitignore").write_text(publisher.MANIFEST + "\n")
                        run(source, "add", ".gitignore")
                        run(source, "commit", "-am", "Next checked source"); run(source, "push", "origin", "main")
                    if i == 3:
                        (source / "app/routing/app.R").write_text("checked source three")
                        run(source, "commit", "-am", "Third checked source"); run(source, "push", "origin", "main")
                    head = run(source, "rev-parse", "HEAD")
                    clone = folder / f"runner{i}"
                    subprocess.run(["git", "clone", "--branch", "main", str(origin), str(clone)], check=True, capture_output=True)
                    run(clone, "config", "user.name", "Fixture")
                    run(clone, "config", "user.email", "fixture@example.invalid")
                    os.chdir(clone)
                    record = {"packages": {"powerkit": {"description": {"RemoteSha": head}}}}
                    Path(publisher.MANIFEST).write_text(json.dumps(record))
                    if i >= 2:
                        old = run(source, "rev-parse", "HEAD^")
                        record["packages"]["powerkit"]["description"]["RemoteSha"] = old
                        Path(publisher.MANIFEST).write_text(json.dumps(record))
                        with self.assertRaisesRegex(RuntimeError, "Main moved"):
                            publisher.prepare(old)
                        record["packages"]["powerkit"]["description"]["RemoteSha"] = head
                        Path(publisher.MANIFEST).write_text(json.dumps(record))
                    published = publisher.prepare(head)
                    self.assertEqual(Path("app/routing/app.R").read_text(), f"checked source {['one', 'two', 'three'][i - 1]}")
                    self.assertEqual(json.loads(Path(publisher.MANIFEST).read_text()), {"packages": {"powerkit": {"description": {"RemoteSha": head}}}})
                    self.assertEqual(run(clone, "ls-files", publisher.MANIFEST), publisher.MANIFEST)
                    if previous:
                        run(clone, "merge-base", "--is-ancestor", previous, published)
                    run(clone, "diff", "--exit-code", head, "HEAD", "--", ".", f":(exclude){publisher.MANIFEST}")
                    run(clone, "push", "origin", f"HEAD:{publisher.BRANCH}")
                    self.assertEqual(run(origin, "rev-parse", "main"), head)
                    previous = published
                    # A mismatched engine pin must fail before branch changes.
                    record["packages"]["powerkit"]["description"]["RemoteSha"] = "wrong"
                    Path(publisher.MANIFEST).write_text(json.dumps(record))
                    with self.assertRaisesRegex(RuntimeError, "must pin"):
                        publisher.prepare(head)
            finally:
                os.chdir(original)


if __name__ == "__main__":
    unittest.main()
