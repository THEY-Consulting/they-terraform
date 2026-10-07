"""Check the actual module graph without planning or contacting AWS.

Run `terraform -chdir=aws/lambda init -backend=false` before this test.
"""

from collections import defaultdict
import os
from pathlib import Path
import re
import subprocess
import unittest


def dependencies(dot):
    edges = defaultdict(list)
    for source, target in re.findall(r'"([^"\n]+)" -> "([^"\n]+)"', dot):
        edges[source].append(target)
    return edges


def reaches(edges, source, target):
    pending = [source]
    seen = set()
    while pending:
        node = pending.pop()
        if node == target:
            return True
        if node not in seen:
            seen.add(node)
            pending.extend(edges[node])
    return False


class PolicyOrderTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        module = Path(__file__).resolve().parent
        cli_path = os.environ.get("TERRAFORM_CLI_PATH")
        binary = str(Path(cli_path) / "terraform-bin") if cli_path else "terraform"
        result = subprocess.run(
            [binary, f"-chdir={module}", "graph", "-type=plan"],
            check=True, capture_output=True, text=True,
        )
        cls.edges = dependencies(result.stdout)

    def assert_policies_ready(self, function):
        source = f"[root] {function} (expand)"
        for policy in ("vpc_access", "cloudwatch_logs", "custom_policies"):
            with self.subTest(function=function, policy=policy):
                target = f"[root] aws_iam_role_policy.{policy} (expand)"
                self.assertTrue(
                    reaches(self.edges, source, target),
                    f"{function} can be created before its {policy} policy.",
                )

    def test_direct_lambda_waits_for_execution_policies(self):
        self.assert_policies_ready("aws_lambda_function.lambda_func")

    def test_datadog_lambda_waits_for_execution_policies(self):
        self.assert_policies_ready("module.lambda-datadog.aws_lambda_function.this")


if __name__ == "__main__":
    unittest.main()
