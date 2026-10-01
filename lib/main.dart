import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/split_bill_provider.dart';
import 'screens/main_scaffold.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedState = await StorageService.loadState();
  runApp(SplitBillApp(savedState: savedState));
}

class SplitBillApp extends StatelessWidget {
  final Map<String, dynamic>? savedState;
  const SplitBillApp({super.key, this.savedState});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SplitBillProvider(savedState: savedState)),
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
