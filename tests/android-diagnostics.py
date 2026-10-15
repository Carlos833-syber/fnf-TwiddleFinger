#!/usr/bin/env python3
"""Verify the real diagnostic journal across independent Haxe processes."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


class AndroidDiagnosticsTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="twiddle-diagnostics-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        target = self.root / "source/backend/AndroidDiagnosticStore.hx"
        target.parent.mkdir(parents=True)
        shutil.copyfile(REPO / "source/backend/AndroidDiagnosticStore.hx", target)
        (self.root / "source/Test.hx").write_text("""
import backend.AndroidDiagnosticStore;
class Test {
    static function main() {
        var store = new AndroidDiagnosticStore(Sys.getEnv('TEST_STORAGE'));
        switch (Sys.getEnv('TEST_MODE')) {
            case 'loading':
                store.begin('Lendo chart');
                for (i in 0...20) store.checkpoint('Imagem ' + i);
                store.checkpoint('Imagem 19');
            case 'read':
                Sys.print(store.previous == null ? 'NONE' : store.previous);
            case 'success':
                store.begin('Lendo chart');
                store.finish();
                store.checkpoint('Nao deve criar arquivo');
            case 'error':
                store.begin('Iniciando script');
                store.fail('Null Object Reference', 'PlayState.hx line 123');
                store.checkpoint('Nao deve sobrescrever erro');
            default: throw 'Unknown test mode';
        }
    }
}
""", encoding="utf-8")

    def run_mode(self, mode, storage=None):
        env = dict(os.environ, TEST_MODE=mode,
                   TEST_STORAGE=str(storage or self.root / "private"))
        result = subprocess.run(
            ["haxe", "-cp", "source", "-main", "Test", "--interp"],
            cwd=self.root, env=env, capture_output=True, text=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def test_interrupted_load_survives_restart_and_is_consumed(self):
        self.run_mode("loading")
        report = self.run_mode("read")
        self.assertIn("Ultima etapa: Imagem 19", report)
        history = report.split("Etapas recentes:\n")[1].split("\n\n")[0].splitlines()
        self.assertEqual(history, [f"Imagem {i}" for i in range(8, 20)])
        self.assertIn("fechamento manual", report)
        self.assertEqual(self.run_mode("read"), "NONE")

    def test_success_does_not_report_normal_exit(self):
        self.run_mode("success")
        self.assertEqual(self.run_mode("read"), "NONE")

    def test_exception_retains_error_stack_and_checkpoint(self):
        self.run_mode("error")
        report = self.run_mode("read")
        for value in ("Null Object Reference", "PlayState.hx line 123", "Iniciando script"):
            self.assertIn(value, report)
        self.assertNotIn("Nao deve sobrescrever", report)

    def test_io_failure_does_not_crash_game(self):
        blocked = self.root / "not-a-directory"
        blocked.write_text("blocked", encoding="utf-8")
        self.run_mode("loading", blocked)
        self.run_mode("error", blocked)
        self.run_mode("success", blocked)


if __name__ == "__main__":
    unittest.main()
