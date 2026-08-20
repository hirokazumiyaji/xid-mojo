# xid-mojo 設計仕様

## 目的

`xid-mojo`は、[`rs/xid`](https://github.com/rs/xid) と相互変換できる XID を Mojo で生成し、解析するライブラリである。

XID のバイナリ表現は12バイト、文字列表現は20文字の小文字 base32hex とする。
生成には中央サーバーを必要とせず、同一の machine ID とプロセス ID を使う生成器ごとに、1秒あたり2²⁴個まで異なる ID を生成する。

対象環境は Mojo 1.0.0 が動作する macOS ARM64 と Linux x86-64 とする。

## 制約

実行時の追加依存は、Prefix.dev の `@hirokazumiyaji/mojo` channel で配布する `crypto = 0.1.0` だけとする。
hostname の SHA-256 には `crypto.sha256.SHA256` を使い、暗号ハッシュをこのリポジトリへ複製しない。

Unix epoch の現在時刻、現在プロセスの PID、hostname を取得する公開 API は Mojo 1.0.0 の標準ライブラリにない。
この三つの値は、`std.ffi.external_call()` から macOS と Linux の libc を呼んで取得する。
外部コマンド、Python interop、動的に追加する共有ライブラリは使わない。

依存解決と開発タスクには Pixi を使う。
既存の Python と `uv` の雛形は削除し、Python パッケージや Python ラッパーは提供しない。

## 対象外

次の機能は実装しない。

- Go 固有の `database/sql` インターフェース
- JSON の marshal と unmarshal
- CLI
- Python ラッパー
- Windows 対応
- ベンチマーク
- Conda パッケージの公開 recipe

## パッケージ構成

`src/xid/id.mojo` は XID の値表現、base32hex 変換、比較、部分抽出を担当する。
このモジュールは OS API、乱数、SHA-256 に依存しない。

`src/xid/generator.mojo` は machine ID、PID、共有 counter を保持し、12バイトの ID を生成する。
hostname の SHA-256 と `XID_MACHINE_ID` の解釈もこのモジュールが担当する。

`src/xid/system.mojo` は libc の `time`、`getpid`、`gethostname` を呼ぶ内部ラッパーだけを提供する。
OS 依存処理をこのモジュールへ閉じ込めることで、ID の変換処理を OS と無関係にテストできるようにする。

`src/xid/__init__.mojo` は利用者向けの型と関数だけを再公開する。

## ID の表現

**ID** は12個の `UInt8` を保持する値型である。
値の並びは MongoDB ObjectID と互換にする。

| オフセット | 長さ | 内容 | byte order |
|---:|---:|---|---|
| 0 | 4 | Unix epoch の秒 | big-endian |
| 4 | 3 | machine ID | big-endian の24-bit値 |
| 7 | 2 | PID | big-endian |
| 9 | 3 | counter | big-endian の24-bit値 |

文字列表現には alphabet `0123456789abcdefghijklmnopqrstuv` を使う。
12バイトを padding なしで20文字へ変換し、バイト列の辞書順と文字列の辞書順を一致させる。

decoder は長さ20、alphabet、末尾の未使用4ビットを検証する。
末尾の未使用ビットが0でない文字列は、同じ12バイトへ復号できる場合でも non-canonical として拒否する。

## 公開 API

`ID` は `Copyable`、`Movable`、`Equatable`、`Hashable`、`Writable` に準拠する。
`Writable.write_to()` は20文字の XID を書き出す。

`ID` は次の操作を提供する。

- `to_string() -> String`
- `bytes() -> InlineArray[UInt8, 12]`
- `time() -> UInt32`
- `machine() -> InlineArray[UInt8, 3]`
- `pid() -> UInt16`
- `counter() -> UInt32`
- `is_nil() -> Bool`
- `is_zero() -> Bool`
- `compare(other: ID) -> Int`

パッケージは次の関数を公開する。

- `from_string(value: String) raises -> ID`
- `from_bytes(value: Span[Byte, _]) raises -> ID`
- `nil_id() -> ID`
- `sort(mut ids: List[ID])`

`from_string()` と `from_bytes()` は不正な入力に対して `Error("xid: invalid ID")` を送出する。
生成済み `ID` の操作は error を送出しない。

## Generator の所有権

Mojo は実行時の module-level 変数を提供しないため、Go 版の package-level `New()` は再現しない。
利用者は `Generator()` を一度構築し、そのインスタンスから ID を生成する。

`Generator` は machine ID、PID、`ArcPointer[Atomic[DType.uint32]]` を保持する。
`Generator` のコピーは同じ atomic counter を共有する。
各スレッドは `Generator` のコピーを所有し、`new()` または `new_with_time()` を呼び出せる。

`Generator` は次の操作を公開する。

- `Generator() raises`
- `new(mut self) raises -> ID`
- `new_with_time(mut self, unix_seconds: UInt32) -> ID`

`new()` は libc `time()` から秒を取得し、`new_with_time()` に渡す。
`new_with_time()` は atomic counter を1増やし、その下位24ビットを ID に格納する。
counter が2²⁴回増えると格納値は周回するため、一意性の上限は upstream と同じ1秒あたり2²⁴個である。

## Generator の初期化

`Generator()` は machine ID、PID、counter の順に初期化する。

環境変数 `XID_MACHINE_ID` が空でなければ、10進整数として解釈する。
値が数値でない場合は `Error("XID_MACHINE_ID value is set to not a number")` を送出する。
値が0未満または `0xFFFFFF` より大きい場合は `Error("XID_MACHINE_ID out of range for 3 bytes")` を送出する。

`XID_MACHINE_ID` が空なら libc `gethostname()` で hostname を取得する。
取得に失敗した場合や結果が空の場合は `Error("xid: cannot get hostname")` を送出する。
取得した byte 列を `crypto.sha256.SHA256.update_bytes()` へ渡し、`digest()` の先頭3バイトを machine ID にする。

PID は libc `getpid()` の下位16ビットを使う。
この切り詰めは upstream の2バイト表現と一致する。

counter の初期値は `std.random.Random` のローカルインスタンスから取得する。
seed には `perf_counter_ns()`、machine ID、PID を混合し、標準ライブラリの共有 PRNG 状態を使わない。
XID は時刻、machine ID、PID、counter を露出するため、この乱数は予測困難性を保証するものではない。

## エラー境界

エラーを送出する処理は、外部入力の解析、`Generator` の初期化、現在時刻の取得に限定する。
libc `time()` が `-1` を返した場合は、`new()` が `Error("xid: cannot get current time")` を送出する。
したがって、公開シグネチャは `new(mut self) raises -> ID` とする。
指定時刻を使う `new_with_time()` は error を送出しない。

エラー時にランダムな machine ID へ切り替える fallback は設けない。
hostname の取得失敗を隠すと、再起動後に machine ID が変わり、運用者が一意性の前提を確認できなくなるためである。

## Pixi 構成

`pixi.toml` は `osx-arm64` と `linux-64` を対象にし、次の channel を指定する。

```toml
channels = [
    "https://prefix.dev/@hirokazumiyaji/mojo",
    "https://conda.modular.com/max",
    "conda-forge",
]
```

依存は次の2項目に固定する。

```toml
[dependencies]
mojo-compiler = "1.0.0"
crypto = "0.1.0"
```

`mojo-compiler` はビルド環境であり、`xid` の Mojo コードが import する追加ライブラリは `crypto` だけである。

Pixi task は `format`、個別テスト、全テスト、`precompile`、配布形態の import test を提供する。
`precompile` は `src/xid` を `xid.mojoc` へ変換する。

## テスト方針

テストは `std.testing.TestSuite` で実行し、期待値は実装対象から独立した固定値を使う。

`tests/id_test.mojo` は upstream の12バイト fixture と文字列 `9m4e2mr0ui3e8a215n4g` の相互変換を検証する。
同じテスト群で部分抽出、nil 判定、比較、sort、不正な長さ、不正文字、大文字、non-canonical な末尾を検証する。

`tests/generator_test.mojo` は固定した構成要素から作る ID、連続 counter、コピー間の counter 共有、並行生成時の重複不在を検証する。
環境変数による machine ID の正常値、境界値、不正値も検証する。
固定 hostname の SHA-256 期待値を使い、machine ID が digest の先頭3バイトになることを検証する。

`tests/system_test.mojo` は Unix 秒が2026年1月1日から2100年1月1日の範囲にあること、PID が正であること、hostname が空でないことを検証する。
この範囲テストは libc の単位や時計種別を取り違える実装を検出するために置く。

配布形態の import test は、`xid.mojoc` だけを import path に置いた利用例をコンパイルして実行する。
このテストにより、ソースツリーが偶然 import path に含まれる状態へ依存していないことを確認する。

## 文書とライセンス

README は英語を本文とし、日本語版を `README.ja.md` に置く。
両方に Pixi での導入方法、最小使用例、byte layout、文字列表現、`Generator` のコピー方法、upstream との差分、非暗号学的 ID であることを記載する。

ソースコードは MIT License で配布する。
README とライセンス関連文書には、設計と固定テストベクトルの参照元として `rs/xid` を明記する。

## 完了条件

次の条件をすべて満たした時点で実装完了とする。

- Pixi が lockfile を再現できる。
- Mojo formatter を適用した差分が残らない。
- すべての単体テストが成功する。
- 並行生成テストで重複が発生しない。
- `src/xid` の precompile が成功する。
- precompile 済み `xid.mojoc` を使う利用例が成功する。
- README の最小使用例がコンパイルできる。
