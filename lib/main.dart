import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/split_bill_provider.dart';
import 'screens/main_scaffold.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SplitBillApp());
}

class SplitBillApp extends StatelessWidget {
  const SplitBillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SplitBillProvider()),
      ],
      child: MaterialApp(
        title: 'SplitBill',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainScaffold(),
      ),
    );
  }
}
