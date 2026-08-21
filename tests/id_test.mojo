from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)
from xid.id import from_bytes, nil_id


def fixture_bytes() -> Array[UInt8, 12]:
    return [
        0x4D, 0x88, 0xE1, 0x5B, 0x60, 0xF4,
        0x86, 0xE4, 0x28, 0x41, 0x2D, 0xC9,
    ]


def test_parts() raises:
    var raw = fixture_bytes()
    var value = from_bytes(Span(raw))
    assert_equal(value.bytes(), raw)
    assert_equal(value.time(), UInt32(1300816219))
    var expected_machine: Array[UInt8, 3] = [0x60, 0xF4, 0x86]
    assert_equal(value.machine(), expected_machine)
    assert_equal(value.pid(), UInt16(0xE428))
    assert_equal(value.counter(), UInt32(4271561))


def test_from_bytes_rejects_invalid_length() raises:
    var raw = Array[UInt8, 11](fill=0)
    with assert_raises(contains="xid: invalid ID"):
        _ = from_bytes(Span(raw))


def test_nil() raises:
    assert_true(nil_id().is_nil())
    assert_true(nil_id().is_zero())
    var raw = fixture_bytes()
    assert_false(from_bytes(Span(raw)).is_nil())


def test_ids_compare_by_bytes() raises:
    var raw = fixture_bytes()
    var value = from_bytes(Span(raw))
    var same = value.copy()
    assert_true(value == same)
    raw[11] = 0
    assert_false(value == from_bytes(Span(raw)))


def test_from_bytes_copies_input() raises:
    var raw = fixture_bytes()
    var value = from_bytes(Span(raw))
    raw[0] = 0
    assert_equal(value.time(), UInt32(1300816219))


def test_bytes_returns_copy() raises:
    var value = from_bytes(Span(fixture_bytes()))
    var raw = value.bytes()
    raw[0] = 0
    assert_equal(value.time(), UInt32(1300816219))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
