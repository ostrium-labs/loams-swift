# docsearch

A small search CLI over the sample knowledge base. The query is matched with BM25, and a toy 3-d embedding derived from the text drives the vector retriever, so no model is needed.

```sh
export LOAMS_ENDPOINT=http://127.0.0.1:8080
swift run docsearch refund
swift run docsearch shipping --tenant a --limit 2
```
