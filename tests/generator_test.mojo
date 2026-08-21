from std.testing import TestSuite, assert_equal, assert_raises
from xid.generator import (
    _initial_counter,
    _machine_id_from_hostname,
    _parse_machine_id_override,
)


def test_machine_id_from_hostname() raises:
    var hostname: Array[UInt8, 3] = [0x61, 0x62, 0x63]
    var expected: Array[UInt8, 3] = [0xBA, 0x78, 0x16]
    assert_equal(_machine_id_from_hostname(Span(hostname)), expected)


def test_machine_id_override() raises:
    var small: Array[UInt8, 3] = [0, 0, 123]
    var maximum: Array[UInt8, 3] = [0xFF, 0xFF, 0xFF]
    assert_equal(_parse_machine_id_override("123"), small)
    assert_equal(_parse_machine_id_override("16777215"), maximum)
    with assert_raises(contains="XID_MACHINE_ID value is set to not a number"):
        _ = _parse_machine_id_override("")
    with assert_raises(contains="XID_MACHINE_ID value is set to not a number"):
        _ = _parse_machine_id_override("12x")
    with assert_raises(contains="XID_MACHINE_ID out of range for 3 bytes"):
        _ = _parse_machine_id_override("-1")
    with assert_raises(contains="XID_MACHINE_ID out of range for 3 bytes"):
        _ = _parse_machine_id_override("16777216")


def test_initial_counter_is_deterministic_and_24_bit() raises:
    var value = _initial_counter(UInt64(123456789))
    assert_equal(value & 0xFF000000, UInt32(0))
    assert_equal(value, _initial_counter(UInt64(123456789)))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
