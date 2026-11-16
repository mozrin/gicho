import 'dart:async';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:material_ui/material_ui.dart';

import '../../logging/configured_logging.dart';
import 'gicho_photo_models.dart';
import 'gicho_photo_normalizer.dart';

/// Full-screen fixed-ratio crop editor that returns newly cropped bytes.
class GichoPhotoCropPage extends StatefulWidget {
  const GichoPhotoCropPage({
    required this.photo,
    required this.aspectRatio,
    required this.copy,
    required this.normalizer,
    this.logSink,
    super.key,
  }) : assert(aspectRatio > 0);

  final GichoPhoto photo;
  final double aspectRatio;
  final GichoPhotoCropCopy copy;
  final GichoPhotoNormalizer normalizer;
  final GichoPhotoLogSink? logSink;

  @override
  State<GichoPhotoCropPage> createState() => _GichoPhotoCropPageState();
}

class _GichoPhotoCropPageState extends State<GichoPhotoCropPage> {
  final _controller = CropController();
  var _ready = false;
  var _cropping = false;
  Object? _failure;

  @override
  void initState() {
    super.initState();
    _log(
      'crop page opened: ${widget.photo.width}x${widget.photo.height} '
      'at ${widget.aspectRatio}',
    );
  }

  @override
  void dispose() {
    _log('crop page disposed');
    super.dispose();
  }

  void _crop() {
    if (!_ready || _cropping) return;
    _log('crop operation started');
    setState(() {
      _cropping = true;
      _failure = null;
    });
    _controller.crop();
  }

  Future<void> _onCropped(CropResult result) async {
    switch (result) {
      case CropSuccess(:final croppedImage):
        try {
          final photo = await widget.normalizer.describeCrop(
            bytes: croppedImage,
            original: widget.photo,
          );
          _log('crop operation completed: ${photo.width}x${photo.height}');
          if (mounted) Navigator.of(context).pop(photo);
        } catch (error) {
          _setFailure(error);
        }
      case CropFailure(:final cause):
        _setFailure(cause);
    }
  }

  void _setFailure(Object error) {
    _log('crop operation failed: $error');
    if (!mounted) return;
    setState(() {
      _failure = error;
      _ready = true;
      _cropping = false;
    });
  }

  void _onStatusChanged(CropStatus status) {
    if (!mounted) return;
    final ready = status == CropStatus.ready && !_cropping;
    final cropping = status == CropStatus.cropping || _cropping;
    if (_ready == ready && _cropping == cropping) return;
    setState(() {
      _ready = ready;
      _cropping = cropping;
    });
    _log('crop editor status changed: ${status.name}');
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Text(
              widget.copy.instructions,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Crop(
                      key: const ValueKey('gicho-photo-crop-editor'),
                      image: widget.photo.bytes,
                      controller: _controller,
                      onCropped: _onCropped,
                      onStatusChanged: _onStatusChanged,
                      aspectRatio: widget.aspectRatio,
                      initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
                        size: 1,
                        aspectRatio: widget.aspectRatio,
                      ),
                      interactive: true,
                      fixCropRect: true,
                      baseColor: Theme.of(context).colorScheme.surface,
                      maskColor: Colors.black.withValues(alpha: 0.68),
                      radius: 22,
                      filterQuality: FilterQuality.high,
                      progressIndicator: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_failure != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Semantics(
                liveRegion: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Flexible(child: Text(widget.copy.failure)),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('gicho-photo-crop-confirm'),
                  onPressed: _ready && !_cropping ? _crop : null,
                  icon: _cropping
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _failure == null
                              ? Icons.check_rounded
                              : Icons.refresh_rounded,
                        ),
                  label: Text(
                    _cropping
                        ? widget.copy.cropping
                        : _failure == null
                        ? widget.copy.usePhoto
                        : widget.copy.retry,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
