# sql

Runs SQL through the published `loams.sql` module (including bound parameters and the hybrid `rrf`, `vector_search`, and `text_search` table functions). It uses the shared SDK seed helper and does not call the HTTP SQL route directly.

Seeds `kb` and runs SQL queries against the `examples-swift` namespace using the SDK module.

```sh
export LOAMS_ENDPOINT=http://127.0.0.1:8080
swift run sql
```
