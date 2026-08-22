# xid

[日本語](README.ja.md)

## Installation

Use Pixi with Mojo 1.0.0 and `crypto = "0.2.0"`.

```toml
channels = [
    "https://prefix.dev/hirokazumiyaji/mojo",
    "https://conda.modular.com/max",
    "conda-forge",
]
```

## Usage

```mojo
from xid import Generator, from_string


def main() raises:
    var generator = Generator()
    var value = generator.new()
    print(value)
    var parsed = from_string(value.to_string())
    print(parsed.time())
```

## Binary layout

An XID has a 12-byte layout.

The numeric timestamp, process ID, and counter fields are big-endian.

The machine ID is stored as three raw bytes.

| Offset | Length | Value |
|---:|---:|---|
| 0 | 4 | Unix epoch seconds |
| 4 | 3 | Machine ID |
| 7 | 2 | Process ID |
| 9 | 3 | Counter |

## Text format

An XID encodes to 20 lowercase base32hex characters with alphabet `0123456789abcdefghijklmnopqrstuv`.

The text order matches bytewise order.

## Generator ownership and concurrency

Create one `Generator()` and retain it in application state.

Copies share one atomic counter through `ArcPointer[Atomic[DType.uint32]]`.

Each thread may own a copy and call `new()` or `new_with_time()`.

The counter wraps after 2²⁴ values, so one generator has the same 2²⁴-per-second uniqueness limit as `rs/xid` when machine ID and process ID are unchanged.

## Differences from rs/xid

This package does not provide package-level `New()`, JSON support, SQL support, Python bindings, or Windows support.

Use an explicit `Generator` instead of package-level mutable state.

## Security

XID is not a secret and does not use cryptographic randomness.

Do not use it for tokens, passwords, session secrets, or other security-sensitive identifiers.

## Development

Run individual tests with Pixi.

```sh
pixi run test-id
pixi run test-system
pixi run test-generator
```

## Attribution

The design and fixed test vectors reference [rs/xid](https://github.com/rs/xid), which is MIT licensed.

## License

xid is released under the [MIT License](LICENSE).
