# xid

[English](README.md)

## インストール

Pixi、Mojo 1.0.0、`crypto = "0.2.0"` を使用する。

```toml
channels = [
    "https://prefix.dev/hirokazumiyaji/mojo",
    "https://conda.modular.com/max",
    "conda-forge",
]
```

## 使い方

```mojo
from xid import Generator, from_string


def main() raises:
    var generator = Generator()
    var value = generator.new()
    print(value)
    var parsed = from_string(value.to_string())
    print(parsed.time())
```

## バイナリレイアウト

XID は 12 バイトのレイアウトで構成される。

timestamp、process ID、counter の数値 field は big-endian で格納される。

machine ID は 3 バイトの raw bytes として格納される。

| オフセット | 長さ | 値 |
|---:|---:|---|
| 0 | 4 | Unix epoch 秒 |
| 4 | 3 | machine ID |
| 7 | 2 | process ID |
| 9 | 3 | counter |

## テキスト形式

XID は alphabet `0123456789abcdefghijklmnopqrstuv` を使う 20 文字の小文字 base32hex へ変換される。

テキストの順序は bytewise の順序と一致する。

## 順序付け

`ID` は `Comparable` に準拠するため、`List[ID]` は標準ライブラリの `sort()` で整列できる。

`compare()` は `rs/xid` と同様に `-1`、`0`、`1` を返す。

## Generator の所有権と並行性

`Generator()` を一度生成し、アプリケーションの状態として保持する。

コピーは `ArcPointer[Atomic[DType.uint32]]` を通じて一つの atomic counter を共有する。

各 thread はコピーを所有し、`new()` または `new_with_time()` を呼び出せる。

counter は 2²⁴ 個で周回するため、machine ID と process ID が変わらない場合の一つの generator の一意性上限は、`rs/xid` と同じ毎秒 2²⁴ 個である。

## rs/xid との差分

この package は package-level `New()`、JSON support、SQL support、Python bindings、Windows support を提供しない。

package-level の可変状態ではなく、明示的な `Generator` を使用する。

machine ID は hostname の SHA-256 の先頭 3 バイトであり、MD5 を使う `rs/xid` とは同一 host でも machine ID が異なるため、生成される ID も一致しない。

`from_string()` は末尾文字の non-canonical な下位 bit を拒否するが、`rs/xid` はこれを受け入れる。

## セキュリティ

XID は secret ではなく、cryptographic randomness を使用しない。

token、password、session secret、その他の security-sensitive identifier には使用しない。

## 開発

個別の test は Pixi で実行する。

```sh
pixi run test-id
pixi run test-system
pixi run test-generator
```

## 出典

設計と固定 test vector は [rs/xid](https://github.com/rs/xid) を参照している。

同 project は MIT License で配布されている。

## ライセンス

xid は [MIT License](LICENSE) で配布する。
