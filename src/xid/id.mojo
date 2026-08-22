from std.hashlib import Hasher


comptime _ALPHABET: StaticString = "0123456789abcdefghijklmnopqrstuv"


struct ID(Comparable, Copyable, Hashable, Movable, Writable):
    var _bytes: Array[UInt8, 12]

    def __init__(out self, var bytes: Array[UInt8, 12]):
        self._bytes = bytes^

    def bytes(self) -> Array[UInt8, 12]:
        return self._bytes.copy()

    def __eq__(self, other: Self) -> Bool:
        for i in range(12):
            if self._bytes[i] != other._bytes[i]:
                return False
        return True

    def __hash__[H: Hasher](self, mut hasher: H):
        hasher._update_with_bytes(Span(self._bytes))

    def time(self) -> UInt32:
        return (
            UInt32(self._bytes[0]) << 24
            | UInt32(self._bytes[1]) << 16
            | UInt32(self._bytes[2]) << 8
            | UInt32(self._bytes[3])
        )

    def machine(self) -> Array[UInt8, 3]:
        return [self._bytes[4], self._bytes[5], self._bytes[6]]

    def pid(self) -> UInt16:
        return UInt16(self._bytes[7]) << 8 | UInt16(self._bytes[8])

    def counter(self) -> UInt32:
        return (
            UInt32(self._bytes[9]) << 16
            | UInt32(self._bytes[10]) << 8
            | UInt32(self._bytes[11])
        )

    def is_nil(self) -> Bool:
        for i in range(12):
            if self._bytes[i] != 0:
                return False
        return True

    def is_zero(self) -> Bool:
        return self.is_nil()

    def compare(self, other: Self) -> Int:
        for i in range(12):
            if self._bytes[i] < other._bytes[i]:
                return -1
            if self._bytes[i] > other._bytes[i]:
                return 1
        return 0

    def __lt__(self, other: Self) -> Bool:
        return self.compare(other) < 0

    def to_string(self) -> String:
        var chars = Array[Byte, 20](fill=0)
        chars[0] = self._bytes[0] >> 3
        chars[1] = (self._bytes[0] << 2 | self._bytes[1] >> 6) & 0x1F
        chars[2] = (self._bytes[1] >> 1) & 0x1F
        chars[3] = (self._bytes[1] << 4 | self._bytes[2] >> 4) & 0x1F
        chars[4] = (self._bytes[2] << 1 | self._bytes[3] >> 7) & 0x1F
        chars[5] = (self._bytes[3] >> 2) & 0x1F
        chars[6] = (self._bytes[3] << 3 | self._bytes[4] >> 5) & 0x1F
        chars[7] = self._bytes[4] & 0x1F
        chars[8] = self._bytes[5] >> 3
        chars[9] = (self._bytes[5] << 2 | self._bytes[6] >> 6) & 0x1F
        chars[10] = (self._bytes[6] >> 1) & 0x1F
        chars[11] = (self._bytes[6] << 4 | self._bytes[7] >> 4) & 0x1F
        chars[12] = (self._bytes[7] << 1 | self._bytes[8] >> 7) & 0x1F
        chars[13] = (self._bytes[8] >> 2) & 0x1F
        chars[14] = (self._bytes[8] << 3 | self._bytes[9] >> 5) & 0x1F
        chars[15] = self._bytes[9] & 0x1F
        chars[16] = self._bytes[10] >> 3
        chars[17] = (self._bytes[10] << 2 | self._bytes[11] >> 6) & 0x1F
        chars[18] = (self._bytes[11] >> 1) & 0x1F
        chars[19] = (self._bytes[11] << 4) & 0x1F
        var alphabet = _ALPHABET.as_bytes()
        for i in range(20):
            chars[i] = alphabet[Int(chars[i])]
        return String(StringSlice(unsafe_from_utf8=Span(chars)))

    def write_to(self, mut writer: Some[Writer]):
        writer.write(self.to_string())


def from_bytes(value: Span[UInt8, _]) raises -> ID:
    if len(value) != 12:
        raise Error("xid: invalid ID")
    var bytes = Array[UInt8, 12](fill=0)
    for i in range(12):
        bytes[i] = value[i]
    return ID(bytes^)


def _decode_digit(value: UInt8) raises -> UInt8:
    if value >= UInt8(0x30) and value <= UInt8(0x39):
        return value - UInt8(0x30)
    if value >= UInt8(0x61) and value <= UInt8(0x76):
        return value - UInt8(0x61) + UInt8(10)
    raise Error("xid: invalid ID")


def from_string(value: String) raises -> ID:
    if value.byte_length() != 20:
        raise Error("xid: invalid ID")
    var raw = value.as_bytes()
    var digits = Array[UInt8, 20](fill=0)
    for i in range(20):
        digits[i] = _decode_digit(raw[i])
    if digits[19] & 0x0F != 0:
        raise Error("xid: invalid ID")
    var bytes = Array[UInt8, 12](fill=0)
    bytes[0] = digits[0] << 3 | digits[1] >> 2
    bytes[1] = digits[1] << 6 | digits[2] << 1 | digits[3] >> 4
    bytes[2] = digits[3] << 4 | digits[4] >> 1
    bytes[3] = digits[4] << 7 | digits[5] << 2 | digits[6] >> 3
    bytes[4] = digits[6] << 5 | digits[7]
    bytes[5] = digits[8] << 3 | digits[9] >> 2
    bytes[6] = digits[9] << 6 | digits[10] << 1 | digits[11] >> 4
    bytes[7] = digits[11] << 4 | digits[12] >> 1
    bytes[8] = digits[12] << 7 | digits[13] << 2 | digits[14] >> 3
    bytes[9] = digits[14] << 5 | digits[15]
    bytes[10] = digits[16] << 3 | digits[17] >> 2
    bytes[11] = digits[17] << 6 | digits[18] << 1 | digits[19] >> 4
    return ID(bytes^)


def nil_id() -> ID:
    return ID(Array[UInt8, 12](fill=0))
