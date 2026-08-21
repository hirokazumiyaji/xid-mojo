struct ID(Copyable, Equatable, Movable):
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


def from_bytes(value: Span[UInt8, _]) raises -> ID:
    if len(value) != 12:
        raise Error("xid: invalid ID")
    var bytes = Array[UInt8, 12](fill=0)
    for i in range(12):
        bytes[i] = value[i]
    return ID(bytes^)


def nil_id() -> ID:
    return ID(Array[UInt8, 12](fill=0))
