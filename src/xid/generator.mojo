from crypto.sha256 import SHA256
from std.atomic import Atomic
from std.memory import ArcPointer
from std.os import getenv
from std.random import Random
from std.time import perf_counter_ns
from xid.id import ID
from xid.system import _hostname_bytes, _process_id, _unix_seconds


struct Generator(Copyable, Movable):
    var _machine: Array[UInt8, 3]
    var _pid: UInt16
    var _counter: ArcPointer[Atomic[DType.uint32]]

    def __init__(out self) raises:
        var override = getenv("XID_MACHINE_ID")
        var machine: Array[UInt8, 3]
        if override.byte_length() > 0:
            machine = _parse_machine_id_override(override)
        else:
            var hostname = _hostname_bytes()
            machine = _machine_id_from_hostname(Span(hostname))
        var pid = _process_id()
        var seed = UInt64(perf_counter_ns())
        seed ^= UInt64(machine[0]) << 40
        seed ^= UInt64(machine[1]) << 32
        seed ^= UInt64(machine[2]) << 24
        seed ^= UInt64(pid) << 8
        self = _generator_with_parts(machine, pid, _initial_counter(seed))

    def __init__(
        out self,
        var machine: Array[UInt8, 3],
        pid: UInt16,
        var counter: ArcPointer[Atomic[DType.uint32]],
    ):
        self._machine = machine^
        self._pid = pid
        self._counter = counter^

    def new_with_time(mut self, timestamp: UInt32) -> ID:
        var counter = self._next_counter()
        var raw = Array[UInt8, 12](fill=0)
        raw[0] = UInt8(timestamp >> 24)
        raw[1] = UInt8(timestamp >> 16)
        raw[2] = UInt8(timestamp >> 8)
        raw[3] = UInt8(timestamp)
        raw[4] = self._machine[0]
        raw[5] = self._machine[1]
        raw[6] = self._machine[2]
        raw[7] = UInt8(self._pid >> 8)
        raw[8] = UInt8(self._pid)
        raw[9] = UInt8(counter >> 16)
        raw[10] = UInt8(counter >> 8)
        raw[11] = UInt8(counter)
        return ID(raw^)

    def _next_counter(self) -> UInt32:
        return (self._counter[].fetch_add(1) + 1) & 0x00FFFFFF

    def new(mut self) raises -> ID:
        return self.new_with_time(_unix_seconds())


def _generator_with_parts(
    machine: Array[UInt8, 3], pid: UInt16, counter: UInt32
) -> Generator:
    return Generator(
        machine.copy(),
        pid,
        ArcPointer(Atomic[DType.uint32](counter & 0x00FFFFFF)),
    )


def _machine_id_from_hostname(hostname: Span[Byte, _]) -> Array[UInt8, 3]:
    var hasher = SHA256()
    hasher.update_bytes(hostname)
    var digest = hasher^.digest()
    return [digest[0], digest[1], digest[2]]


def _parse_machine_id_override(value: String) raises -> Array[UInt8, 3]:
    var raw = value.as_bytes()
    if raw[0] == UInt8(0x2D):
        raise Error("XID_MACHINE_ID out of range for 3 bytes")
    var number: UInt32 = 0
    for i in range(len(raw)):
        var character = raw[i]
        if character < UInt8(0x30) or character > UInt8(0x39):
            raise Error("XID_MACHINE_ID value is set to not a number")
        var digit = UInt32(character - UInt8(0x30))
        if number > 1677721 or (number == 1677721 and digit > 5):
            raise Error("XID_MACHINE_ID out of range for 3 bytes")
        number = number * 10 + digit
    return [
        UInt8(number >> 16),
        UInt8(number >> 8),
        UInt8(number),
    ]


def _initial_counter(seed: UInt64) -> UInt32:
    var random = Random(seed=seed)
    return UInt32(random.step()[0] & 0x00FFFFFF)
