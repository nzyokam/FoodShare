import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// Nourish & Nature — FoodShare design system
const kPrimary = Color(0xFF38563B);
const kPrimaryContainer = Color(0xFF506F52);
const kSurface = Color(0xFFFAF9F5);
const kOnSurface = Color(0xFF1A1C1A);
const kOutlineVariant = Color(0xFFC2C8BF);
const kSecondaryContainer = Color(0xFFD6E3D3);

ThemeData lightMode = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.light(
    primary: kPrimary,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: kPrimaryContainer,
    onPrimaryContainer: Color(0xFFCDF0CC),
    secondary: Color(0xFF556255),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: kSecondaryContainer,
    onSecondaryContainer: Color(0xFF596659),
    surface: kSurface,
    onSurface: kOnSurface,
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF4F4EF),
    surfaceContainer: Color(0xFFEEEEEA),
    surfaceContainerHigh: Color(0xFFE8E8E4),
    surfaceContainerHighest: Color(0xFFE3E3DE),
    onSurfaceVariant: Color(0xFF424841),
    outline: Color(0xFF737971),
    outlineVariant: kOutlineVariant,
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    inverseSurface: Color(0xFF2F312E),
    onInverseSurface: Color(0xFFF1F1EC),
    inversePrimary: Color(0xFFADCFAD),
    surfaceTint: Color(0xFF476649),
  ),
  scaffoldBackgroundColor: kSurface,
  textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
    displayLarge: GoogleFonts.bebasNeue(fontSize: 48, letterSpacing: 1),
    displayMedium: GoogleFonts.bebasNeue(fontSize: 40, letterSpacing: 0.8),
    displaySmall: GoogleFonts.bebasNeue(fontSize: 32, letterSpacing: 0.6),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFFFFFFFF),
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: kOutlineVariant, width: 0.5),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryContainer,
      foregroundColor: Colors.white,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      elevation: 0,
      textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kPrimary,
      side: const BorderSide(color: kOutlineVariant),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF4F4EF),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kOutlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kOutlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kPrimary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
    ),
    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF424841)),
    hintStyle: const TextStyle(color: Color(0xFF737971)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFFFFFFFF),
    selectedItemColor: kPrimary,
    unselectedItemColor: Color(0xFF737971),
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
    unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 11),
    elevation: 0,
    type: BottomNavigationBarType.fixed,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: kSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
    iconTheme: IconThemeData(color: kOnSurface),
    centerTitle: false,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: kOutlineVariant,
    thickness: 0.5,
    space: 0,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFFEEEEEA),
    selectedColor: kSecondaryContainer,
    side: BorderSide.none,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: kOnSurface,
    unselectedLabelColor: Color(0xFF737971),
    indicatorSize: TabBarIndicatorSize.tab,
    dividerColor: Colors.transparent,
  ),
);
