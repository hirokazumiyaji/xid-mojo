from std.testing import TestSuite, assert_true
from xid.system import _hostname_bytes, _process_id, _unix_seconds


def test_unix_seconds() raises:
    var value = _unix_seconds()
    assert_true(value >= 1767225600)
    assert_true(value < 4102444800)


def test_process_id() raises:
    assert_true(_process_id() > 0)


def test_hostname() raises:
    assert_true(len(_hostname_bytes()) > 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
