import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matter/pages/contacts/contacts_page.dart';
import 'package:matter/providers/chat_provider.dart';
import 'package:matter/src/rust/api/matrix.dart';
import 'package:matter/widgets/soft_superellipse_border.dart';

void main() {
  testWidgets('renders contacts with separated avatar and info card', (
    tester,
  ) async {
    const contactId = '@alice:example.org';
    final contact = Contact(id: contactId, name: 'Alice', status: '在线');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contactsProvider.overrideWith((ref) async => [contact]),
        ],
        child: const MaterialApp(home: ContactsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('在线'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('contact-row-separator:$contactId')),
      findsOneWidget,
    );
    final infoCard = tester.widget<Material>(
      find.byKey(const ValueKey('contact-info-card:$contactId')),
    );
    expect(infoCard.shape, isA<SoftSuperellipseBorder>());
    expect(
      (infoCard.shape! as SoftSuperellipseBorder).exponent,
      SoftSuperellipseBorder.defaultExponent,
    );
    expect((infoCard.shape! as SoftSuperellipseBorder).side.width, 1.5);
    expect(infoCard.elevation, greaterThan(0));
    final avatarMaterial = tester.widget<Material>(
      find.byKey(const ValueKey('contact-avatar-shadow:$contactId')),
    );
    expect(avatarMaterial.shape, isA<SoftSuperellipseBorder>());
    expect(
      (avatarMaterial.shape! as SoftSuperellipseBorder).exponent,
      SoftSuperellipseBorder.defaultExponent,
    );
    expect((avatarMaterial.shape! as SoftSuperellipseBorder).side.width, 1.5);
    expect(avatarMaterial.elevation, greaterThan(0));
  });
}
