import tempfile
import unittest
import subprocess
from pathlib import Path
from unittest.mock import patch

from lockcode.audit import AuditStore
from lockcode.catalog import load_apps, manual_app
from lockcode.policy import AttemptLimiter, GrantState, PendingRequestState, valid_code
from lockcode.settings import SettingsStore
from lockcode.secure_store import SecretStore, derive_credential, verify_credential
from lockcode.startup import set_enabled
from lockcode.updates import _apt_progress, _parse_release, _rpm_progress, is_newer


class PolicyTests(unittest.TestCase):
    def test_update_metadata_and_progress_are_validated(self):
        release = _parse_release({"tag_name": "v0.1.4", "assets": [{
            "name": "lockcode-linux_0.1.4_all.deb",
            "browser_download_url": "https://github.com/D1abloo/LockAPP/releases/download/v0.1.4/lockcode.deb",
            "digest": "sha256:" + "a" * 64,
            "size": 100,
        }]})
        self.assertEqual(release.version, "0.1.4")
        self.assertTrue(is_newer("0.1.4", "0.1.3"))
        self.assertEqual(_apt_progress("pmstatus:lockcode:75:Instalando"), (0.75, "Instalando"))
        self.assertEqual(_rpm_progress("Actualizando: lockcode  2/4"),
                         (0.5, "Instalando paquete RPM…"))
        rpm = _parse_release({"tag_name": "v0.1.4", "assets": [{
            "name": "lockcode-linux-0.1.4-1.noarch.rpm",
            "browser_download_url": "https://github.com/D1abloo/LockAPP/releases/download/v0.1.4/lockcode.rpm",
            "digest": "sha256:" + "b" * 64,
            "size": 100,
        }]}, ".rpm")
        self.assertEqual(rpm.name, "lockcode-linux-0.1.4-1.noarch.rpm")
        self.assertIsNone(_parse_release({"tag_name": "v0.1.4", "assets": [{
            "name": "lockcode-linux.deb", "browser_download_url": "https://example.com/fake.deb",
            "digest": "sha256:" + "a" * 64,
        }]}))

    def test_codes_accept_letters_and_symbols(self):
        self.assertTrue(valid_code("Clave segura !@#$%^&*()[]{}"))
        self.assertFalse(valid_code("abc"))
        self.assertFalse(valid_code("abcd\n"))
        self.assertTrue(valid_code("x" * 64))
        self.assertFalse(valid_code("x" * 65))

    def test_derived_credential(self):
        credential = derive_credential("Clave !segura#")
        self.assertNotIn("Clave !segura#", credential)
        self.assertTrue(verify_credential("Clave !segura#", credential))
        self.assertFalse(verify_credential("Clave incorrecta", credential))

    def test_fresh_install_uses_a_distinct_keyring_item(self):
        first = SecretStore("a" * 32).attributes
        second = SecretStore("b" * 32).attributes
        self.assertNotEqual(first, second)
        self.assertEqual(first[-2:], ["credential-id", "a" * 32])

    def test_locked_keyring_does_not_wait_forever(self):
        with patch("lockcode.secure_store.subprocess.run", side_effect=subprocess.TimeoutExpired("secret-tool", 1)):
            self.assertIsNone(SecretStore()._lookup())
            with self.assertRaisesRegex(RuntimeError, "llavero GNOME"):
                SecretStore().set_code("Clave !segura#")

    def test_progressive_penalty(self):
        limiter = AttemptLimiter()
        self.assertEqual([limiter.failed(100) for _ in range(3)], [0, 0, 1])
        self.assertFalse(limiter.can_attempt(100.5))
        self.assertTrue(limiter.can_attempt(101))
        limiter.succeeded()
        self.assertTrue(limiter.can_attempt(0))

    def test_grace_and_close_modes(self):
        grants = GrantState()
        grants.approve("/app", 10, 5, 100)
        self.assertTrue(grants.granted("/app", 11, 399, lambda _pid: False))
        self.assertFalse(grants.granted("/app", 11, 401, lambda _pid: False))
        grants.approve("/close", 20, 0, 100)
        self.assertTrue(grants.granted("/close", 20, 500, lambda _pid: True))
        self.assertFalse(grants.granted("/close", 21, 500, lambda _pid: True))
        self.assertFalse(grants.granted("/close", 20, 500, lambda _pid: False))

    def test_pending_request_prevents_cycles(self):
        pending = PendingRequestState()
        self.assertTrue(pending.begin(10))
        self.assertFalse(pending.begin(10))
        pending.complete(10)
        self.assertTrue(pending.begin(10))


class PersistenceTests(unittest.TestCase):
    @patch("lockcode.startup.subprocess.run")
    def test_startup_removes_legacy_entry(self, run):
        with tempfile.TemporaryDirectory() as directory, \
                patch("lockcode.startup.Path.home", return_value=Path(directory)):
            legacy = Path(directory) / ".config/autostart/lockcode.desktop"
            legacy.parent.mkdir(parents=True)
            legacy.write_text("legacy", encoding="utf-8")
            set_enabled(True)
            self.assertFalse(legacy.exists())
            self.assertEqual(run.call_args.args[0],
                ["systemctl", "--user", "enable", "lockcode.service"])

    def test_terminal_can_be_selected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            executable = root / "gnome-terminal"
            executable.write_text("#!/bin/sh\n", encoding="utf-8")
            executable.chmod(0o755)
            (root / "org.gnome.Terminal.desktop").write_text(
                "[Desktop Entry]\nType=Application\nName=Terminal\n"
                f"Exec={executable} --window\n", encoding="utf-8",
            )
            apps = load_apps([root])
            self.assertEqual([(app.name, app.executable) for app in apps],
                [("Terminal", str(executable.resolve()))])

    def test_manual_executable_is_validated_and_persisted(self):
        with tempfile.TemporaryDirectory() as directory:
            executable = Path(directory) / "private-app"
            executable.write_text("#!/bin/sh\n", encoding="utf-8")
            executable.chmod(0o755)
            app = manual_app(str(executable))
            self.assertEqual(app.name, "private-app")
            path = Path(directory) / "settings.json"
            store = SettingsStore(path)
            store.value.manual_executables[app.executable] = app.name
            store.save()
            self.assertEqual(SettingsStore(path).value.manual_executables,
                             {app.executable: "private-app"})

    def test_protected_apps_persist(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "settings.json"
            store = SettingsStore(path)
            store.value.protected_executables = ["/usr/bin/example"]
            store.value.grace_minutes = 42
            store.value.credential_configured = True
            store.save()
            restored = SettingsStore(path).value
            self.assertEqual(restored.protected_executables, ["/usr/bin/example"])
            self.assertEqual(restored.grace_minutes, 42)
            self.assertTrue(restored.credential_configured)
            self.assertEqual(restored.credential_id, store.value.credential_id)

    def test_existing_install_keeps_legacy_keyring_item(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "settings.json"
            path.write_text('{"credential_configured": true}', encoding="utf-8")
            self.assertEqual(SettingsStore(path).value.credential_id, "legacy")

    def test_audit_is_generic_and_bounded(self):
        with tempfile.TemporaryDirectory() as directory:
            audit = AuditStore(Path(directory) / "audit.json")
            for _ in range(205):
                audit.record("Intento fallido")
            self.assertEqual(len(audit.read()), 200)
            self.assertNotIn("application", str(audit.read()).lower())


if __name__ == "__main__":
    unittest.main()
