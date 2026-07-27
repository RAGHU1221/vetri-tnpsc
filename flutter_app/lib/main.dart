import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'src/providers/app_provider.dart';
import 'src/router.dart';
import 'src/services/notification_service.dart';

// வெற்றி TNPSC theme — report design (ink indigo + gold + leaf green)
const ink = Color(0xFF14213D);
const gold = Color(0xFFC9971C);
const verm = Color(0xFFB33A2B);
const leaf = Color(0xFF2E7D4F);
const paper = Color(0xFFFBF7EE);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  NotificationService.scheduleDailyQuizReminder();
  runApp(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const VetriApp(),
      ),
    );
}

class VetriApp extends StatelessWidget {
  const VetriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'வெற்றி TNPSC',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: paper,
        colorScheme: ColorScheme.fromSeed(seedColor: leaf, primary: leaf),
        // Tamil readability: Noto Sans Tamil, comfortable sizes
        textTheme: GoogleFonts.notoSansTamilTextTheme().copyWith(
          bodyLarge: GoogleFonts.notoSansTamil(fontSize: 18, height: 1.7),
          bodyMedium: GoogleFonts.notoSansTamil(fontSize: 16, height: 1.6),
        ),
        appBarTheme: const AppBarTheme(
            backgroundColor: leaf,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
                fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: leaf,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.notoSansTamil(
                fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: leaf, width: 1.6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.notoSansTamil(
                fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: ink,
            textStyle: GoogleFonts.notoSansTamil(fontWeight: FontWeight.w700),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: EdgeInsets.zero,
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: Colors.white,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: ink,
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
        ),
      ),
    );
  }
}
