import 'package:material_ui/material_ui.dart';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';

typedef LocalizationAssetError =
    void Function(
      Object error,
      StackTrace stackTrace,
      String path,
      Locale locale,
    );

class ResilientAssetLoader extends AssetLoader {
  const ResilientAssetLoader(this.delegate, {this.onError});

  final AssetLoader delegate;
  final LocalizationAssetError? onError;

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    try {
      return await delegate.load(path, locale) ?? const {};
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace, path, locale);
      return const {};
    }
  }
}
