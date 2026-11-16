# Upload

Upload is not implemented by the current Gicho package or example
application. There is no exported `upload()`, `UploadResult`, `UploadStorage`,
or `UploadRetention` API.

Applications that need file selection, storage, or transfer must currently own
that implementation and its dependencies. Gicho exposes Dio through:

```dart
import 'package:moztopia/gicho.dart';
```

That export can be used by an application-owned upload client, but Gicho
does not define upload behavior, file-picker integration, public-storage
policy, or cleanup semantics.
