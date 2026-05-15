import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/message_model.dart';
import 'models/product_model.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(MessageModelAdapter());
  Hive.registerAdapter(ProductModelAdapter());
  await Hive.openBox<MessageModel>('messages');
  await Hive.openBox<ProductModel>('products');
  await Hive.openBox('settings');
  runApp(const NetcodeApp());
}

class NetcodeApp extends StatelessWidget {
  const NetcodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Netcode',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const SplashScreen(),
    );
  }
}
