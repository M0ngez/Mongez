import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongez/core/widgets/unread_badge.dart';

void main() {
  Widget wrap(Widget child, {TextDirection direction = TextDirection.ltr}) {
    return MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('renders the count with its semantics label', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(const UnreadBadge(count: 3, semanticsLabel: '3 unread requests')),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.bySemanticsLabel('3 unread requests'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('renders nothing for zero or negative counts', (tester) async {
    await tester.pumpWidget(wrap(const UnreadBadge(count: 0)));
    expect(find.text('0'), findsNothing);

    await tester.pumpWidget(wrap(const UnreadBadge(count: -4)));
    expect(find.text('-4'), findsNothing);
  });

  testWidgets('caps the label at 99+', (tester) async {
    await tester.pumpWidget(wrap(const UnreadBadge(count: 150)));
    expect(find.text('99+'), findsOneWidget);
  });

  test('formats counts', () {
    expect(UnreadBadge.format(1), '1');
    expect(UnreadBadge.format(99), '99');
    expect(UnreadBadge.format(100), '99+');
  });
}
