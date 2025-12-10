import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ama_order_system_flutter/src/models/order.dart';
import 'package:ama_order_system_flutter/src/models/user.dart';
import 'package:ama_order_system_flutter/src/services/api_client.dart';
import 'package:ama_order_system_flutter/src/state/auth_notifier.dart';
import 'package:ama_order_system_flutter/src/state/order_notifier.dart';
import 'package:ama_order_system_flutter/src/widgets/order_form.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier() : super(ApiClient());

  @override
  Future<void> restoreSession() async {
    initializing = false;
  }

  @override
  Future<List<AppUser>> fetchAssignableTakers() async {
    return const [AppUser(id: 1, username: 'taker', role: 'taker', isApproved: true)];
  }

  @override
  Future<List<AppUser>> fetchAccounters() async {
    return const [AppUser(id: 99, username: 'acc', role: 'accounter', isApproved: true)];
  }
}

class _FakeOrderNotifier extends OrderNotifier {
  _FakeOrderNotifier() : super(ApiClient());

  @override
  Future<void> createOrder(OrderDraft draft) async {}

  @override
  Future<List<String>> suggestProducts(String query) async => [];
}

void main() {
  testWidgets('Enter on price adds an item and focuses the next name', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthNotifier>.value(value: _FakeAuthNotifier()),
          ChangeNotifierProvider<OrderNotifier>.value(value: _FakeOrderNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OrderForm(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final name1 = find.widgetWithText(TextFormField, 'Name #1');
    await tester.tap(name1);
    await tester.pump();
    await tester.enterText(name1, 'Item 1');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    final qty = find.widgetWithText(TextFormField, 'Qty');
    await tester.enterText(qty, '2');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    final price = find.widgetWithText(TextFormField, 'Price');
    await tester.enterText(price, '5');
    await tester.testTextInput.receiveAction(TextInputAction.done);

    // Allow the widget tree to rebuild and the queued focus request to fire.
    await tester.pump();
    await tester.pump();

    final name2 = find.widgetWithText(TextFormField, 'Name #2');
    expect(name2, findsOneWidget);
    final name2Editable = find.descendant(of: name2, matching: find.byType(EditableText));
    expect(name2Editable, findsOneWidget);
    expect(tester.widget<EditableText>(name2Editable).focusNode.hasFocus, isTrue);
  });
}
