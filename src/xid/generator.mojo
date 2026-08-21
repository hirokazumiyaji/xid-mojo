from crypto.sha256 import SHA256
from std.random import Random


def _machine_id_from_hostname(hostname: Span[Byte, _]) -> Array[UInt8, 3]:
    var hasher = SHA256()
    hasher.update_bytes(hostname)
    var digest = hasher^.digest()
    return [digest[0], digest[1], digest[2]]


def _parse_machine_id_override(value: String) raises -> Array[UInt8, 3]:
    if value.byte_length() == 0:
        raise Error("XID_MACHINE_ID value is set to not a number")
    if String(value[byte=0]) == "-":
        raise Error("XID_MACHINE_ID out of range for 3 bytes")
    var number: UInt32 = 0
    for i in range(value.byte_length()):
        var character = String(value[byte=i]).as_bytes()[0]
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
