import 'package:gicho/gicho.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('email verified state is supplied by the consumer', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContactEmailField(
            controller: controller,
            label: 'Email',
            verified: true,
            verifiedLabel: 'Confirmed email',
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.verified), findsOneWidget);
    expect(find.byTooltip('Confirmed email'), findsOneWidget);
  });

  testWidgets('postal fields follow the supplied country structure', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: StructuredPostalAddressFields(
              fields: const [
                StructuredPostalAddressField(
                  keyName: 'postal_code',
                  label: 'ZIP code',
                  required: true,
                ),
              ],
              controllers: {'postal_code': controller},
              requiredMessage: 'Required',
            ),
          ),
        ),
      ),
    );
    expect(find.text('ZIP code'), findsOneWidget);
    expect(find.byKey(const ValueKey('postal.postal_code')), findsOneWidget);
  });

  testWidgets('phone capabilities change only when the owner selects them', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var capabilities = <String>{};
    var country = 'TH';
    Widget editor() => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ContactPhoneField(
            controller: controller,
            countryCode: country,
            countries: const [
              ContactPhoneCountry(
                code: 'TH',
                label: 'Thailand and a long country label',
              ),
              ContactPhoneCountry(code: 'US', label: 'United States'),
            ],
            onCountryChanged: (value) => country = value,
            label: 'Phone',
            countryLabel: 'Country',
            capabilityLabel: 'I can receive',
            capabilityOptions: const {'sms': 'SMS', 'whatsapp': 'WhatsApp'},
            capabilities: capabilities,
            onCapabilitiesChanged: (value) => capabilities = value,
            format: (value, _) => value,
          ),
        ),
      ),
    );
    await tester.pumpWidget(editor());
    expect(capabilities, isEmpty);
    await tester.tap(find.text('WhatsApp'));
    expect(capabilities, {'whatsapp'});
    await tester.pumpWidget(editor());
    expect(find.byType(CheckboxListTile), findsNWidgets(2));
  });
}
