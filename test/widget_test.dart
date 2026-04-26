import 'package:flutter_test/flutter_test.dart';
import 'package:kopi_jalanan_gank/app.dart';
import 'package:provider/provider.dart';
import 'package:kopi_jalanan_gank/providers/product_provider.dart';
import 'package:kopi_jalanan_gank/providers/cart_provider.dart';
import 'package:kopi_jalanan_gank/providers/transaction_provider.dart';
import 'package:kopi_jalanan_gank/providers/finance_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
          ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ],
        child: const KopiJalananApp(),
      ),
    );
    expect(find.byType(KopiJalananApp), findsOneWidget);
  });
}
