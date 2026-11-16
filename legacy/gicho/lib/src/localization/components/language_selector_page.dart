import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../configured_localization.dart';
import '../translate.dart';

/// Selects from the application's initialized localization languages.
final class LanguageSelectorPage extends StatefulWidget {
  const LanguageSelectorPage({super.key});

  @override
  State<LanguageSelectorPage> createState() => _LanguageSelectorPageState();
}

final class _LanguageSelectorPageState extends State<LanguageSelectorPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final languages = moztopiaLocalization.languages;
    final selectedCode = context.locale.languageCode;
    final selectedLanguage = languages.firstWhere(
      (language) => language.locale.languageCode == selectedCode,
      orElse: () => languages.first,
    );
    final fallbackLocale = moztopiaLocalization.configuration.fallbackLanguage;
    final selectedName = selectedLanguage.nameIn(context.locale);
    final selectedFallbackName = selectedLanguage.nameIn(fallbackLocale);
    final normalizedQuery = _query.trim().toLowerCase();
    final filteredLanguages = normalizedQuery.isEmpty
        ? languages
        : languages
              .where(
                (language) =>
                    language
                        .nameIn(context.locale)
                        .toLowerCase()
                        .contains(normalizedQuery) ||
                    language
                        .nameIn(fallbackLocale)
                        .toLowerCase()
                        .contains(normalizedQuery) ||
                    language
                        .nameIn(language.locale)
                        .toLowerCase()
                        .contains(normalizedQuery) ||
                    language.locale.languageCode.contains(normalizedQuery),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: Text(translate('language', context: context)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  translate('preview', context: context),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(selectedLanguage.label)),
                    title: Text(selectedName),
                    subtitle: Text(
                      selectedName == selectedFallbackName
                          ? selectedLanguage.locale.languageCode
                          : '$selectedFallbackName · '
                                '${selectedLanguage.locale.languageCode}',
                    ),
                    trailing: Text(selectedLanguage.locale.languageCode),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Filter languages',
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 12),
                Text(
                  '${filteredLanguages.length} of ${languages.length} '
                  'app-enabled languages',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
          Expanded(
            child: RadioGroup<Locale>(
              groupValue: context.locale,
              onChanged: (locale) async {
                if (locale != null) await context.setLocale(locale);
              },
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                itemCount: filteredLanguages.length,
                itemBuilder: (context, index) {
                  final option = filteredLanguages[index];
                  final localizedName = option.nameIn(context.locale);
                  final fallbackName = option.nameIn(fallbackLocale);
                  final isSelected = option.locale.languageCode == selectedCode;
                  final nativeName = option.nameIn(option.locale);
                  final displayNames = <String>[localizedName];
                  if (!isSelected && nativeName != localizedName) {
                    displayNames.add(nativeName);
                  }
                  if (!isSelected &&
                      fallbackName != localizedName &&
                      fallbackName != nativeName) {
                    displayNames.add(
                      option.locale.languageCode == fallbackLocale.languageCode
                          ? fallbackName
                          : fallbackName.toLowerCase(),
                    );
                  }
                  final displayName = [
                    displayNames.first,
                    for (final name in displayNames.skip(1)) '($name)',
                  ].join(' ');
                  return RadioListTile(
                    value: option.locale,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(displayName),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
