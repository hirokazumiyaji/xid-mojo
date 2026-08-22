from std.testing import assert_equal, assert_false
from xid import Generator, from_string


def main() raises:
    var parsed = from_string("9m4e2mr0ui3e8a215n4g")
    assert_equal(parsed.pid(), UInt16(0xE428))
    var generator = Generator()
    assert_false(generator.new().is_nil())
