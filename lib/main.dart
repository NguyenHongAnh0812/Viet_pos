import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/invoice_import_screen.dart';
import 'screens/invoice_import_list_screen.dart';
import 'widgets/main_layout.dart';
import 'widgets/common/design_system.dart';

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
      },
    );
  }
}
