import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../logging/configured_logging.dart';
import 'gicho_camera.dart';
import 'gicho_photo_models.dart';
import 'gicho_photo_normalizer.dart';

/// Full-screen, app-neutral camera experience with capture and retake.
class GichoCameraPage extends StatefulWidget {
  const GichoCameraPage({
    required this.gateway,
    required this.normalizer,
    required this.copy,
    required this.aspectRatio,
    this.initialDevices = const [],
    this.logSink,
    super.key,
  });

  final GichoCameraGateway gateway;
  final GichoPhotoNormalizer normalizer;
  final GichoCameraCopy copy;
  final double aspectRatio;
  final List<GichoCameraDevice> initialDevices;
  final GichoPhotoLogSink? logSink;

  @override
  State<GichoCameraPage> createState() => _GichoCameraPageState();
}

class _GichoCameraPageState extends State<GichoCameraPage>
    with WidgetsBindingObserver {
  List<GichoCameraDevice> _devices = const [];
  GichoCameraSession? _session;
  GichoPhoto? _captured;
  GichoPhotoException? _failure;
  var _deviceIndex = 0;
  var _busy = true;
  var _suspended = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _devices = widget.initialDevices;
    unawaited(_start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final session = _session;
    _session = null;
    if (session != null) unawaited(session.dispose());
    _log('camera page disposed');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _log('camera lifecycle changed: ${state.name}');
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _suspended = true;
      unawaited(_disposeSession());
    } else if (state == AppLifecycleState.resumed && _suspended) {
      _suspended = false;
      if (_captured == null) unawaited(_openCurrentCamera());
    }
  }

  Future<void> _start() async {
    _log('camera discovery started');
    try {
      if (_devices.isEmpty) _devices = await widget.gateway.discoverCameras();
      if (_devices.isEmpty) {
        throw const GichoPhotoException(
          GichoPhotoFailureKind.unavailable,
        );
      }
      final preferred = _devices.indexWhere(
        (device) => device.lens == GichoCameraLens.front,
      );
      _deviceIndex = preferred < 0 ? 0 : preferred;
      _log('camera discovery completed: ${_devices.length} device(s)');
      await _openCurrentCamera();
    } on GichoPhotoException catch (error) {
      _setFailure(error, 'camera discovery failed');
    } catch (error, stackTrace) {
      _setFailure(
        GichoPhotoException(
          GichoPhotoFailureKind.pluginFailure,
          cause: error,
          stackTrace: stackTrace,
        ),
        'camera discovery failed',
      );
    }
  }

  Future<void> _openCurrentCamera() async {
    if (_devices.isEmpty || !mounted) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    final device = _devices[_deviceIndex];
    _log('camera initialization started: ${device.lens.name}');
    try {
      await _disposeSession();
      final session = await widget.gateway.openCamera(device);
      if (!mounted) {
        await session.dispose();
        return;
      }
      setState(() {
        _session = session;
        _busy = false;
      });
      _log('camera initialization completed: ${device.lens.name}');
    } on GichoPhotoException catch (error) {
      _setFailure(error, 'camera initialization failed');
    } catch (error, stackTrace) {
      _setFailure(
        GichoPhotoException(
          GichoPhotoFailureKind.pluginFailure,
          cause: error,
          stackTrace: stackTrace,
        ),
        'camera initialization failed',
      );
    }
  }

  Future<void> _capture() async {
    final session = _session;
    if (session == null || _busy) return;
    setState(() => _busy = true);
    _log('photo capture started');
    try {
      final raw = await session.capturePhoto();
      _log('photo normalization started');
      final photo = await widget.normalizer.normalize(raw);
      if (!mounted) return;
      setState(() {
        _captured = photo;
        _busy = false;
      });
      _log('photo capture completed: ${photo.width}x${photo.height}');
    } on GichoPhotoException catch (error) {
      _setFailure(error, 'photo capture failed');
    } catch (error, stackTrace) {
      _setFailure(
        GichoPhotoException(
          GichoPhotoFailureKind.pluginFailure,
          cause: error,
          stackTrace: stackTrace,
        ),
        'photo capture failed',
      );
    }
  }

  void _retake() {
    _log('photo retake selected');
    setState(() {
      _captured = null;
      _failure = null;
      _busy = false;
    });
  }

  void _usePhoto() {
    final photo = _captured;
    if (photo == null) return;
    _log('captured photo confirmed');
    Navigator.of(context).pop(photo);
  }

  Future<void> _switchCamera() async {
    if (_devices.length < 2 || _busy) return;
    _deviceIndex = (_deviceIndex + 1) % _devices.length;
    _log('camera switch selected: ${_devices[_deviceIndex].lens.name}');
    await _openCurrentCamera();
  }

  Future<void> _disposeSession() async {
    final session = _session;
    _session = null;
    if (session != null) {
      _log('camera session disposal started');
      await session.dispose();
      _log('camera session disposal completed');
    }
  }

  void _setFailure(GichoPhotoException failure, String event) {
    _log('$event: ${failure.kind.name}');
    if (!mounted) return;
    setState(() {
      _failure = failure;
      _busy = false;
    });
  }

  void _log(String message) {
    final line = '[Gicho photo] $message';
    final sink = widget.logSink;
    if (sink != null) {
      sink(line);
    } else {
      unawaited(moztopiaLog.debug(line));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.copy.title)),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Expanded(child: Center(child: _preview())),
                const SizedBox(height: 20),
                _controls(),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _preview() => AspectRatio(
    aspectRatio: widget.aspectRatio,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: _failure != null
            ? _failureView(_failure!)
            : _captured != null
            ? Image.memory(
                _captured!.bytes,
                fit: BoxFit.cover,
                semanticLabel: widget.copy.usePhoto,
              )
            : _session != null
            ? _livePreview(_session!)
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(widget.copy.initializing),
                  ],
                ),
              ),
      ),
    ),
  );

  Widget _livePreview(GichoCameraSession session) => Stack(
    fit: StackFit.expand,
    children: [
      _coveringPreview(session),
      if (_devices.length > 1)
        Positioned(
          top: 14,
          right: 14,
          child: IconButton.filledTonal(
            key: const ValueKey('gicho-camera-switch'),
            tooltip: widget.copy.switchCamera,
            onPressed: _busy ? null : _switchCamera,
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
        ),
    ],
  );

  Widget _coveringPreview(GichoCameraSession session) => LayoutBuilder(
    builder: (context, constraints) {
      final viewportRatio = constraints.maxWidth / constraints.maxHeight;
      final cameraRatio = session.previewAspectRatio;
      final size = cameraRatio > viewportRatio
          ? Size(constraints.maxHeight * cameraRatio, constraints.maxHeight)
          : Size(constraints.maxWidth, constraints.maxWidth / cameraRatio);
      return ClipRect(
        child: OverflowBox(
          alignment: Alignment.center,
          minWidth: size.width,
          maxWidth: size.width,
          minHeight: size.height,
          maxHeight: size.height,
          child: SizedBox.fromSize(size: size, child: session.buildPreview()),
        ),
      );
    },
  );

  Widget _failureView(GichoPhotoException failure) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.no_photography_outlined,
            size: 52,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 14),
          Text(
            _failureText(failure.kind),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _busy ? null : _start,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(widget.copy.retry),
          ),
        ],
      ),
    ),
  );

  String _failureText(GichoPhotoFailureKind kind) => switch (kind) {
    GichoPhotoFailureKind.unsupported => widget.copy.unsupported,
    GichoPhotoFailureKind.unavailable => widget.copy.unavailable,
    GichoPhotoFailureKind.permissionDenied => widget.copy.permissionDenied,
    GichoPhotoFailureKind.permissionPermanentlyDenied =>
      widget.copy.permissionPermanentlyDenied,
    GichoPhotoFailureKind.restricted => widget.copy.restricted,
    _ => widget.copy.failure,
  };

  Widget _controls() {
    if (_failure != null) return const SizedBox(height: 48);
    if (_captured != null) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: const ValueKey('gicho-camera-retake'),
              onPressed: _busy ? null : _retake,
              icon: const Icon(Icons.replay_rounded),
              label: Text(widget.copy.retake),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              key: const ValueKey('gicho-camera-use-photo'),
              onPressed: _busy ? null : _usePhoto,
              icon: const Icon(Icons.check_rounded),
              label: Text(widget.copy.usePhoto),
            ),
          ),
        ],
      );
    }
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        button: true,
        label: _busy ? widget.copy.capturing : widget.copy.capture,
        child: FilledButton.icon(
          key: const ValueKey('gicho-camera-capture'),
          onPressed: _busy ? null : _capture,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.camera_alt_rounded),
          label: Text(_busy ? widget.copy.capturing : widget.copy.capture),
        ),
      ),
    );
  }
}
