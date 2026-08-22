from std.os import getenv, setenv, unsetenv
from std.runtime.asyncrt import TaskGroup
from std.testing import TestSuite, assert_equal, assert_raises, assert_true
from xid.generator import (
    Generator,
    _generator_with_parts,
    _initial_counter,
    _machine_id,
    _machine_id_from_hostname,
    _parse_machine_id_override,
)
from xid.system import _hostname_bytes


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
        _ = _parse_machine_id_override("12x")
    with assert_raises(contains="XID_MACHINE_ID out of range for 3 bytes"):
        _ = _parse_machine_id_override("-1")
    with assert_raises(contains="XID_MACHINE_ID out of range for 3 bytes"):
        _ = _parse_machine_id_override("16777216")


def test_initial_counter_is_24_bit() raises:
    for _ in range(4):
        assert_equal(_initial_counter() & 0xFF000000, UInt32(0))


def test_machine_id_hashes_the_hostname() raises:
    var hostname = _hostname_bytes()
    assert_equal(_machine_id(), _machine_id_from_hostname(Span(hostname)))


def test_generator_layout_and_counter() raises:
    var machine: Array[UInt8, 3] = [0x60, 0xF4, 0x86]
    var generator = _generator_with_parts(
        machine, UInt16(0xE428), UInt32(4271560)
    )
    var first = generator.new_with_time(UInt32(1300816219))
    var second = generator.new_with_time(UInt32(1300816219))
    assert_equal(first.to_string(), "9m4e2mr0ui3e8a215n4g")
    assert_equal(first.counter(), UInt32(4271561))
    assert_equal(second.counter(), UInt32(4271562))


def test_generator_copies_share_counter() raises:
    var machine: Array[UInt8, 3] = [1, 2, 3]
    var first = _generator_with_parts(machine, UInt16(4), UInt32(9))
    var second = first.copy()
    assert_equal(first.new_with_time(1).counter(), UInt32(10))
    assert_equal(second.new_with_time(1).counter(), UInt32(11))


def test_generator_counter_wraps_at_24_bits() raises:
    var machine: Array[UInt8, 3] = [1, 2, 3]
    var generator = _generator_with_parts(machine, UInt16(4), UInt32(0xFFFFFE))
    assert_equal(generator.new_with_time(1).counter(), UInt32(0xFFFFFF))
    assert_equal(generator.new_with_time(1).counter(), UInt32(0))


def test_public_generator_uses_override_and_current_time() raises:
    var original = getenv("XID_MACHINE_ID")
    _ = setenv("XID_MACHINE_ID", "66051")
    try:
        var generator = Generator()
        var value = generator.new()
        var expected_machine: Array[UInt8, 3] = [1, 2, 3]
        assert_equal(value.machine(), expected_machine)
        assert_equal(value.pid() > 0, True)
        assert_equal(value.time() >= UInt32(1767225600), True)
        assert_equal(value.time() < UInt32(4102444800), True)
    finally:
        if original.byte_length() == 0:
            _ = unsetenv("XID_MACHINE_ID")
        else:
            _ = setenv("XID_MACHINE_ID", original)


def test_concurrent_generation_has_no_duplicate_counters() raises:
    var machine: Array[UInt8, 3] = [1, 2, 3]
    var generator = _generator_with_parts(machine, UInt16(4), UInt32(0))
    var generator_copy = generator.copy()
    var counters = Array[UInt32, 256](fill=0)
    var counters_ptr = counters.unsafe_ptr()

    var group = TaskGroup()

    async def generate(index: Int) {imm}:
        counters_ptr[unsafe_offset=index] = generator_copy._next_counter()

    for index in range(256):
        group.create_task(generate(index))
    group.wait()
    for i in range(256):
        for j in range(i + 1, 256):
            assert_true(counters[i] != counters[j])


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
