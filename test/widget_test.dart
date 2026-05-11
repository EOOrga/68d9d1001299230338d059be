import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marie_franc_ops/main.dart';

void main() {
  final storage = <String, String>{};

  setUp(() {
    storage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(localStoreChannel, (call) async {
          final key = call.arguments['key'] as String;
          return switch (call.method) {
            'read' => storage[key],
            'write' => storage[key] = call.arguments['value'] as String,
            'clear' => storage.remove(key),
            _ => throw PlatformException(code: 'not_implemented'),
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(localStoreChannel, null);
  });

  testWidgets('opens the work register and saves a local record', (
    tester,
  ) async {
    await tester.pumpWidget(const OperationsApp());
    await tester.pumpAndSettle();

    expect(find.text('Operations overview'), findsOneWidget);
    expect(find.text('Priority queue'), findsOneWidget);

    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();

    expect(find.text('Work register'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-record')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Dock booking B');
    await tester.enterText(find.byType(TextFormField).at(1), 'Warehouse desk');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'Hold the west dock for an inbound carrier appointment.',
    );
    await tester.enterText(find.byType(TextFormField).at(3), '2');
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save locally'));
    await tester.pumpAndSettle();

    expect(find.text('Dock booking B'), findsOneWidget);
  });

  testWidgets('settings explain local storage and privacy posture', (
    tester,
  ) async {
    await tester.pumpWidget(const OperationsApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text(appName), findsOneWidget);
    expect(find.text('Local data'), findsOneWidget);
    expect(find.textContaining('Records stay on this device'), findsOneWidget);
  });
}
