import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/products/add_product_screen.dart';
import 'screens/invoice_import_screen.dart';
import 'screens/invoice_import_list_screen.dart';
import 'screens/customers/customer_list_screen.dart';
import 'screens/customers/add_customer_screen.dart';
import 'screens/customers/customer_detail_screen.dart';
import 'widgets/main_layout.dart';
import 'widgets/common/design_system.dart';
import 'screens/orders/order_create_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VET-POS',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainLayout(),
        '/products': (context) => const ProductListScreen(),
        '/addProduct': (context) => const AddProductScreen(),
        '/invoice-imports': (context) => const InvoiceImportListScreen(),
        '/invoice-import': (context) => const InvoiceImportScreen(),
        '/customers': (context) => CustomerListScreen(),
        '/customers/add': (context) => AddCustomerScreen(),
        '/customers/detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return CustomerDetailScreen(customerId: args['id']);
        },
        '/orders/create': (context) => const OrderCreateScreen(),
      },
    );
  }
}
