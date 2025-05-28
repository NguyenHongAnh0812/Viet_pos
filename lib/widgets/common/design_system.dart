import 'package:flutter/material.dart';

// Main colors
const Color primaryBlue = Color(0xFF3A6FF8);
const Color secondaryGreen = Color(0xFF67C687);
const Color warningOrange = Color(0xFFFFB547);
const Color destructiveRed = Color(0xFFFF5A5F);

// Backgrounds & Text
const Color appBackground = Color(0xFFF7F9FC);
const Color cardBackground = Color(0xFFFFFFFF);
const Color textPrimary = Color(0xFF1E1E1E);
const Color textSecondary = Color(0xFF6B7280);

// Spacing
const double space2 = 2.0;
const double space4 = 4.0;
const double space5 = 5.0;
const double space8 = 8.0;
const double space12 = 12.0;
const double space14 = 14.0;
const double space16 = 16.0;
const double space20 = 20.0;
const double space24 = 24.0;
const double space32 = 32.0;
const double space44 = 44.0;
const double space200 = 200.0;

// Typography (Inter font)
const TextStyle h1 = TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Inter');
const TextStyle h2 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Inter');
const TextStyle h3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter');
const TextStyle bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.normal, fontFamily: 'Inter');
const TextStyle bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.normal, fontFamily: 'Inter');

// Button styles
final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: primaryBlue,
  foregroundColor: Colors.white,
  minimumSize: const Size(double.infinity, 48),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  elevation: 0,
);

final ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
  foregroundColor: primaryBlue,
  side: const BorderSide(color: Color(0xFFD1D5DB)),
  minimumSize: const Size(double.infinity, 48),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
);

final ButtonStyle destructiveButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: destructiveRed,
  foregroundColor: Colors.white,
);

// Card style helper
Card designSystemCard({required Widget child}) => Card(
  elevation: 1,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
  ),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: child,
  ),
);

// Input decoration helper
InputDecoration designSystemInputDecoration({
  String? label,
  String? hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? errorText,
  bool isDense = false,
  EdgeInsetsGeometry? contentPadding,
}) => InputDecoration(
  labelText: label,
  hintText: hint,
  prefixIcon: prefixIcon,
  suffixIcon: suffixIcon,
  errorText: errorText,
  isDense: isDense,
  contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: primaryBlue, width: 2),
  ),
); 