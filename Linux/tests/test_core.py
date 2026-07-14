import tempfile
import unittest
from pathlib import Path

from lockcode.audit import AuditStore
from lockcode.policy import AttemptLimiter, GrantState, PendingRequestState, valid_code
from lockcode.settings import SettingsStore
from lockcode.secure_store import derive_credential, verify_credential


class PolicyTests(unittest.TestCase):
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
    def test_protected_apps_persist(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "settings.json"
            store = SettingsStore(path)
            store.value.protected_executables = ["/usr/bin/example"]
            store.value.grace_minutes = 42
            store.save()
            restored = SettingsStore(path).value
            self.assertEqual(restored.protected_executables, ["/usr/bin/example"])
            self.assertEqual(restored.grace_minutes, 42)

    def test_audit_is_generic_and_bounded(self):
        with tempfile.TemporaryDirectory() as directory:
            audit = AuditStore(Path(directory) / "audit.json")
            for _ in range(205):
                audit.record("Intento fallido")
            self.assertEqual(len(audit.read()), 200)
            self.assertNotIn("application", str(audit.read()).lower())


if __name__ == "__main__":
    unittest.main()
