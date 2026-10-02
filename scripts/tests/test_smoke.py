import importlib.util
import unittest
from pathlib import Path
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("smoke", Path(__file__).parents[1] / "smoke-test.py")
smoke = importlib.util.module_from_spec(spec)
spec.loader.exec_module(smoke)


class SmokeTests(unittest.TestCase):
    @patch.object(smoke, "get", side_effect=["Healthy", '{"service":"octo","commit":"abc"}'])
    def test_accepts_expected_release(self, _):
        self.assertEqual("abc", smoke.verify("https://example.test/", "abc")["commit"])

    @patch.object(smoke, "get", side_effect=["Healthy", '{"service":"octo","commit":"old"}'])
    def test_rejects_healthy_but_wrong_release(self, _):
        with self.assertRaises(ValueError):
            smoke.verify("https://example.test", "new")

    @patch.object(smoke, "get", return_value="Unhealthy")
    def test_rejects_unhealthy_response(self, _):
        with self.assertRaises(ValueError):
            smoke.verify("https://example.test", "abc")

    @patch.object(smoke, "get", side_effect=["Healthy", "not json"])
    def test_rejects_invalid_release_payload(self, _):
        with self.assertRaises(ValueError):
            smoke.verify("https://example.test", "abc")
