"""Execute the real release shell script with fake Azure CLI and smoke-test commands."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "release.sh"
FAKE_COMMAND = r"""#!/usr/bin/python3
import json, os, sys
from pathlib import Path
path = Path(os.environ['FAKE_STATE'])
state = json.loads(path.read_text())
args = sys.argv[1:]
code = 0
if Path(sys.argv[0]).name == 'az':
    state['commands'].append(args)
    if args[:2] == ['webapp', 'show']:
        print('staging.example.test' if '--slot' in args else 'live.example.test')
    elif args[:4] == ['webapp', 'deployment', 'slot', 'swap']:
        state['swaps'] += 1
        code = 1 if state.get('swap_error') else 0
    elif args[:2] == ['webapp', 'deploy']:
        code = 1 if state.get('deploy_error') else 0
else:
    if args[0] == '-':
        if state.get('initial'):
            code = 1
        else:
            print('previous')
    else:
        url, commit = args[1:3]
        if 'staging' in url:
            code = int(bool(state.get('staging_error'))) if state['swaps'] == 0 else int(bool(state.get('rollback_target_error')))
        elif state['swaps'] == 1:
            code = int(bool(state.get('live_error')))
path.write_text(json.dumps(state))
sys.exit(code)
"""


class ReleaseTests(unittest.TestCase):
    def run_release(self, **scenario):
        with tempfile.TemporaryDirectory() as temp:
            folder = Path(temp)
            state = folder / 'state.json'
            state.write_text(json.dumps(dict(commands=[], swaps=0, **scenario)))
            for name in ['az', 'python3']:
                fake = folder / name
                fake.write_text(FAKE_COMMAND)
                fake.chmod(0o755)
            env = dict(os.environ, PATH=temp + os.pathsep + os.environ['PATH'],
                       FAKE_STATE=str(state), RESOURCE_GROUP='test', APP_NAME='test',
                       EXPECTED_COMMIT='new', PACKAGE_PATH='/unused/application.zip',
                       ALLOW_INITIAL_DEPLOYMENT=str(scenario.get('allow_initial', False)).lower())
            result = subprocess.run(['bash', str(SCRIPT)], env=env, capture_output=True, text=True)
            return result.returncode, json.loads(state.read_text())

    def test_success_swaps_once(self):
        code, state = self.run_release()
        self.assertEqual(0, code)
        self.assertEqual(1, state['swaps'])

    def test_staging_failure_does_not_swap(self):
        code, state = self.run_release(staging_error=True)
        self.assertNotEqual(0, code)
        self.assertEqual(0, state['swaps'])

    def test_failed_live_verification_rolls_back_and_stays_failed(self):
        code, state = self.run_release(live_error=True)
        self.assertNotEqual(0, code)
        self.assertEqual(2, state['swaps'])

    def test_initial_release_requires_explicit_opt_in(self):
        code, state = self.run_release(initial=True)
        self.assertNotEqual(0, code)
        self.assertEqual(0, state['swaps'])

    def test_failed_first_release_has_no_blind_rollback(self):
        code, state = self.run_release(initial=True, allow_initial=True, live_error=True)
        self.assertNotEqual(0, code)
        self.assertEqual(1, state['swaps'])

    def test_ambiguous_swap_failure_does_not_swap_again(self):
        code, state = self.run_release(swap_error=True)
        self.assertNotEqual(0, code)
        self.assertEqual(1, state['swaps'])

    def test_wrong_rollback_target_does_not_swap_again(self):
        code, state = self.run_release(live_error=True, rollback_target_error=True)
        self.assertNotEqual(0, code)
        self.assertEqual(1, state['swaps'])

    def test_deployment_failure_leaves_live_untouched(self):
        code, state = self.run_release(deploy_error=True)
        self.assertNotEqual(0, code)
        self.assertEqual(0, state['swaps'])
