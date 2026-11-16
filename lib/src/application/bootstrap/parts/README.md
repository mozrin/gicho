# GichoBootstrap private parts

- `GichoBootstrapLoadingView` hosts the consumer's initial splash in a
  themed Material app before configuration is available.
- `GichoBootstrapFailureView` hosts the retryable configuration error.

They remain private because callers configure them through `GichoBootstrap`
and should not depend on its internal presentation. Promote either only if
independent consumers need a separate public contract outside bootstrap.
