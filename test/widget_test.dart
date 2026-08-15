import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:well_spent/main.dart';
import 'package:well_spent/providers/expense_provider.dart';
import 'package:well_spent/widgets/liquid_glass_chip.dart';
import 'package:well_spent/widgets/quick_add_modal.dart';

void main() {
  testWidgets('App renders dashboard navigation title', (WidgetTester tester) async {
    await tester.pumpWidget(const WellSpentApp());
    await tester.pump();

    // Verify that the app shows the title.
    expect(find.text('Well Spent'), findsWidgets);
  });

  testWidgets('Quick add modal renders liquid glass category chips and headers', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ExpenseProvider(),
        child: const CupertinoApp(
          home: CupertinoPageScaffold(
            child: QuickAddModal(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Quick Add Expense'), findsOneWidget);
    expect(find.text('CATEGORY'), findsOneWidget);
    expect(find.byType(LiquidGlassChip), findsWidgets);
  });
}
