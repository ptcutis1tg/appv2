import 'package:flutter/material.dart';
import 'package:appv2/theme/app_theme.dart';
import 'package:appv2/screens/ledger_home_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:appv2/db/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await DatabaseHelper.instance.database;
  runApp(const SmartFinanceApp());
}

class SmartFinanceApp extends StatelessWidget {
  const SmartFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Finance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const LedgerHomeScreen(),
    );
  }
}
