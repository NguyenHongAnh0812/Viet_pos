import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/setup_admin_screen.dart';
import 'screens/products/product_list_screen.dart';
import 'screens/products/add_product_screen.dart';
import 'screens/invoice_import_screen.dart';
import 'screens/invoice_import_list_screen.dart';
import 'screens/customers/customer_list_screen.dart';
import 'screens/customers/add_customer_screen.dart';
import 'screens/customers/customer_detail_screen.dart';
import 'widgets/main_layout.dart';
import 'widgets/common/design_system.dart';
import 'screens/orders/order_create_screen.dart';
import 'services/user_service.dart';
import 'screens/test_clear_users_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VET-POS',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      home: const AuthWrapper(),
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
        '/test-clear-users': (context) => const TestClearUsersScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  bool _hasUsers = false;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      // Kiểm tra xem có user nào trong hệ thống không
      final hasUsers = await _userService.hasAnyUsers();
      print('DEBUG: hasUsers = $hasUsers');
      
      // Kiểm tra xem user hiện tại có đăng nhập không
      final currentUser = FirebaseAuth.instance.currentUser;
      final isAuthenticated = currentUser != null;
      print('DEBUG: isAuthenticated = $isAuthenticated');
      print('DEBUG: currentUser = ${currentUser?.email}');

      setState(() {
        _hasUsers = hasUsers;
        _isAuthenticated = isAuthenticated;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking auth state: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    print('DEBUG: Building AuthWrapper - hasUsers: $_hasUsers, isAuthenticated: $_isAuthenticated');

    // Nếu chưa có user nào trong hệ thống -> Hiển thị setup admin
    if (!_hasUsers) {
      print('DEBUG: Showing SetupAdminScreen');
      return const SetupAdminScreen();
    }

    // Nếu đã có user nhưng chưa đăng nhập -> Hiển thị login
    if (!_isAuthenticated) {
      print('DEBUG: Showing LoginScreen');
      return const LoginScreen();
    }

    // Nếu đã đăng nhập -> Hiển thị main layout
    print('DEBUG: Showing MainLayout');
    return const MainLayout();
  }
}
