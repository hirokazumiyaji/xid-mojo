from std.ffi import c_int, c_long, c_size_t, external_call


def _unix_seconds() raises -> UInt32:
    var storage: c_long = 0
    var value = external_call["time", c_long](Pointer(to=storage))
    if value == -1:
        raise Error("xid: cannot get current time")
    return UInt32(value)


def _process_id() -> UInt16:
    return UInt16(external_call["getpid", c_int]())


def _hostname_bytes() -> List[UInt8]:
    var buffer = Array[UInt8, 256](fill=0)
    if (
        external_call["gethostname", c_int](buffer.unsafe_ptr(), c_size_t(256))
        != 0
    ):
        return []
    var result: List[UInt8] = []
    for i in range(256):
        if buffer[i] == 0:
            break
        result.append(buffer[i])
    return result^
