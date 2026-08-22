from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)
from xid.id import ID, from_bytes, from_string, nil_id


def fixture_bytes() -> Array[UInt8, 12]:
    return [
        0x4D,
        0x88,
        0xE1,
        0x5B,
        0x60,
        0xF4,
        0x86,
        0xE4,
        0x28,
        0x41,
        0x2D,
        0xC9,
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


def test_string_round_trip() raises:
    var raw = fixture_bytes()
    var value = from_bytes(Span(raw))
    assert_equal(value.to_string(), "9m4e2mr0ui3e8a215n4g")
    assert_equal(from_string("9m4e2mr0ui3e8a215n4g"), value)


def test_from_string_rejects_invalid_values() raises:
    with assert_raises(contains="xid: invalid ID"):
        _ = from_string("9m4e2mr0ui3e8a215n4")
    with assert_raises(contains="xid: invalid ID"):
        _ = from_string("9m4e2mr0ui3e8a215n4w")
    with assert_raises(contains="xid: invalid ID"):
        _ = from_string("9M4e2mr0ui3e8a215n4g")
    with assert_raises(contains="xid: invalid ID"):
        _ = from_string("9m4e2mr0ui3e8a215n4h")


def test_compare_and_sort() raises:
    var zero = nil_id()
    var raw = Array[UInt8, 12](fill=0)
    raw[11] = 1
    var one = from_bytes(Span(raw))
    assert_equal(zero.compare(one), -1)
    assert_equal(one.compare(zero), 1)
    assert_equal(one.compare(one), 0)
    assert_true(zero < one)
    assert_true(one > zero)
    var values: List[ID] = [one.copy(), zero.copy()]
    sort(values)
    assert_equal(values[0], zero)
    assert_equal(values[1], one)


def test_writable_and_hashable() raises:
    var value = from_bytes(Span(fixture_bytes()))
    assert_equal(String(value), "9m4e2mr0ui3e8a215n4g")
    assert_equal(hash(value), hash(value.copy()))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
