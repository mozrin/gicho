import 'package:material_ui/material_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Translates [key] using the active Easy Localization context.
String translate(
  String key, {
  BuildContext? context,
  List<String>? args,
  Map<String, String>? namedArgs,
  String? gender,
}) {
  return tr(
    key,
    context: context,
    args: args,
    namedArgs: namedArgs,
    gender: gender,
  );
}
