# sql

Seeds `kb` and runs three SQL queries (count, group by, filtered select) against the `examples-swift` namespace. The SDK has no SQL module yet, so the example posts to the engine's REST route `/v1/namespaces/examples-swift/sql`.

```sh
swift run sql
```
