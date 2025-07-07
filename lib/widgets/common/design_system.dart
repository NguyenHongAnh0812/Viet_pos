import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';
import 'package:intl/intl.dart';

/// VET-POS Flutter Style Guide
/// Based on the VET-POS web design system with consistent naming conventions
/// 
/// LAYOUT RULES:
/// - Tất cả màn hình chính phải có max width 1200px (appMaxWidth)
/// - Sử dụng Center widget để căn giữa nội dung
/// - Responsive design: mobile < 768px, desktop >= 768px
/// - Input fields phải có height cố định 40px
/// - UI blocks phải flat (không có box shadow)
/// - Blog titles sử dụng mainGreen theme color

// ===================== COLORS =====================
const Color mainGreen = Color(0xFF22C55E); // Màu xanh lá chủ đạo
const Color secondaryGreen = Color(0xFF67C687); // --secondary
const Color warningOrange = Color(0xFFFFB547); // --warning
const Color destructiveRed = Color(0xFFFF5A5F); // --destructive
const Color borderColor = Color(0xFFE5E7EB); // --border

const Color appBackground = Color(0xFFF0FDF4); // --background
const Color cardBackground = Color(0xFFFFFFFF);
const Color homePageBackground = Color(0xF0FDF4FF); // --card
const Color textPrimary = Color(0xFF1E1E1E); // --foreground
const Color textSecondary = Color(0xFF71717A); // --muted-foreground
const Color textMuted = Color(0xFF71717A); // --muted-foreground
const Color textThird = Color(0xFF4B5563); // --text-third
const Color textActive = Color(0xFF374145); // --foreground
const Color mutedBackground = Color(0xFFF1F3F6); // --muted
const Color accentBackground = Color(0xFFF1F3F6); // --accent
const Color accentForeground = Color(0xFF18181B); // --accent-foreground

// Sidebar specific colors
const Color sidebarBackground = Color(0xFFFFFFFF);
const Color sidebarForeground = Color(0xFF1E1E1E);
const Color sidebarPrimary = Color(0xFF3A6FF8);
const Color sidebarAccent = Color(0xFFF1F3F6);
const Color sidebarBorder = Color(0xFFE4E4E7);
const Color sidebarHoverBackground = Color(0xFFF3F4F6); // sidebar hover background

// Status colors
const Color successGreen = Color(0xFF67C687);
const Color errorRed = Color(0xFFFF5A5F);
const Color infoBlue = Color(0xFF3A6FF8);

// ===================== SPACING =====================
const double space2 = 2.0;
const double space4 = 4.0;
const double space8 = 8.0;
const double space10 = 10.0;
const double space12 = 12.0;
const double space16 = 16.0;
const double space18 = 18.0;
const double space20 = 20.0;
const double space24 = 24.0;
const double space32 = 32.0;
const double space48 = 48.0;
const double space64 = 64.0;
const double spaceMobile = 12.0; // Spacing cho mobile

// Component specific spacing
const double cardPadding = 24.0;
const double buttonPadding = 16.0;
const double inputPadding = 16.0;
const double iconSpacing = 8.0;
const double pageHorizontalPadding = 16.0;
const double sectionSpacing = 24.0;
const double itemSpacing = 16.0;

// ===================== SIZING =====================
// Button Heights
const double buttonHeightSmall = 32.0;
const double buttonHeightMedium = 40.0;
const double buttonHeightLarge = 48.0;

// Button Widths
const double buttonMinWidth = 64.0;
const double buttonIconWidth = 40.0;

// Input Heights
const double inputHeight = 40.0;
const double textareaMinHeight = 80.0;

// Icon Sizes
const double iconSmall = 16.0;
const double iconMedium = 20.0;
const double iconLarge = 24.0;
const double iconXLarge = 32.0;

// Border Radius
const double borderRadiusSmall = 4.0;
const double borderRadiusMedium = 8.0;
const double borderRadiusLarge = 12.0;
const double borderRadiusXLarge = 16.0;

// Modal/Dialog Dimensions
const double modalMaxWidth = 500.0;
const double modalMaxWidthLarge = 700.0;
const double modalMaxWidthSmall = 400.0;
const double modalMinHeight = 200.0;
const double modalPadding = 24.0;
const double modalHeaderHeight = 64.0;
const double modalFooterHeight = 72.0;

// Layout
const double sidebarWidth = 288.0;
const double sidebarItemHeight = 40.0;
const double headerHeight = 64.0;
const double bottomNavHeight = 80.0;
const double appMaxWidth = 1200.0; // Max width cho tất cả màn hình chính

// ===================== RESPONSIVE TYPOGRAPHY =====================
TextStyle responsiveTextStyle(BuildContext context, TextStyle desktop, TextStyle mobile) {
  return MediaQuery.of(context).size.width < 1024 ? mobile : desktop;
}

// ===================== LAYOUT HELPERS =====================
/// Tạo Container với max width appMaxWidth để đảm bảo layout nhất quán
Widget appMaxWidthContainer({required Widget child}) {
  return Center(
    child: Container(
      constraints: const BoxConstraints(maxWidth: appMaxWidth),
      child: child,
    ),
  );
}

/// Tạo Container với max width appMaxWidth và padding
Widget appMaxWidthContainerWithPadding({
  required Widget child, 
  EdgeInsetsGeometry padding = const EdgeInsets.all(16),
}) {
  return Center(
    child: Container(
      constraints: const BoxConstraints(maxWidth: appMaxWidth),
      padding: padding,
      child: child,
    ),
  );
}

// ===================== TYPOGRAPHY =====================
TextStyle getInterTextStyle({
  required double fontSize,
  required FontWeight fontWeight,
  Color color = textPrimary,
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

// Heading Styles
TextStyle get h1 => getInterTextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: 0.0);
TextStyle get h2 => getInterTextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: 0.0);
TextStyle get h3 => getInterTextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: 0.0);
TextStyle get h4 => getInterTextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: 0.0);

// Body Text Styles
TextStyle get bodyLarge => getInterTextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, letterSpacing: 0.0);
TextStyle get body => getInterTextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, letterSpacing: 0.0);
TextStyle get bodySmall => getInterTextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4, letterSpacing: 0.0);

// Label Styles
TextStyle get labelLarge => getInterTextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4, letterSpacing: 0.0);
TextStyle get labelMedium => getInterTextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.4, letterSpacing: 0.0);
TextStyle get labelSmall => getInterTextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.3, letterSpacing: 0.0);

// Utility Styles
TextStyle get heading => getInterTextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.0);
TextStyle get caption => getInterTextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textMuted, letterSpacing: 0.0);
TextStyle get small => getInterTextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.0);
TextStyle get mutedText => getInterTextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textMuted, height: 1.5, letterSpacing: 0.0);

// Mobile Styles
TextStyle get h1Mobile => getInterTextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 0.0);
TextStyle get h2Mobile => getInterTextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.0);
TextStyle get h3Mobile => getInterTextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.0);
TextStyle get bodyMobile => getInterTextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.0);
TextStyle get smallMobile => getInterTextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.0);
TextStyle get captionMobile => getInterTextStyle(fontSize: 11, fontWeight: FontWeight.w400, letterSpacing: 0.0);

// ===================== BUTTON STYLES =====================
const double buttonBorderRadius = 6.0;

ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: mainGreen,
  foregroundColor: Colors.white,
  minimumSize: const Size(buttonMinWidth, buttonHeightMedium),
  padding: const EdgeInsets.symmetric(horizontal: space20, vertical: space18),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonBorderRadius)),
  textStyle: labelLarge,
  elevation: 0,
);

ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
  foregroundColor: textPrimary,
  backgroundColor: cardBackground,
  side: const BorderSide(color: borderColor),
  minimumSize: const Size(buttonMinWidth, buttonHeightMedium),
  padding: const EdgeInsets.symmetric(horizontal: space20, vertical: space18),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonBorderRadius)),
  textStyle: labelLarge,
);

ButtonStyle outlineButtonStyle = OutlinedButton.styleFrom(
  foregroundColor: textPrimary,
  backgroundColor: cardBackground,
  side: const BorderSide(color: borderColor, width: 1.2),
  minimumSize: const Size(buttonMinWidth, buttonHeightMedium),
  padding: const EdgeInsets.symmetric(horizontal: space20, vertical: space18),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonBorderRadius)),
  textStyle: labelLarge,
);

ButtonStyle destructiveButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: destructiveRed,
  foregroundColor: Colors.white,
  minimumSize: const Size(buttonMinWidth, buttonHeightMedium),
  padding: const EdgeInsets.symmetric(horizontal: space20, vertical: space18),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonBorderRadius)),
  textStyle: labelLarge,
  elevation: 0,
);

ButtonStyle ghostButtonStyle = TextButton.styleFrom(
  foregroundColor: textPrimary,
  backgroundColor: Colors.transparent,
  minimumSize: const Size(buttonIconWidth, buttonHeightMedium),
  padding: const EdgeInsets.symmetric(horizontal: space20, vertical: space18),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonBorderRadius)),
  textStyle: labelLarge,
);

// Ghost button with gray border
ButtonStyle ghostBorderButtonStyle = OutlinedButton.styleFrom(
  foregroundColor: textPrimary,
  backgroundColor: appBackground,
  side: const BorderSide(color: borderColor, width: 1),
  minimumSize: const Size(buttonMinWidth, buttonHeightMedium),
  padding: const EdgeInsets.symmetric(horizontal: space20, vertical: space18),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonBorderRadius)),
  textStyle: labelLarge,
);

// Button size variants
ButtonStyle smallButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: mainGreen,
  foregroundColor: Colors.white,
  minimumSize: const Size(buttonMinWidth, buttonHeightSmall),
  padding: const EdgeInsets.symmetric(horizontal: space12, vertical: space4),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonBorderRadius)),
  textStyle: labelMedium,
  elevation: 0,
);

ButtonStyle largeButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: mainGreen, 
  foregroundColor: Colors.white,
  minimumSize: const Size(buttonMinWidth, buttonHeightLarge),
  padding: const EdgeInsets.symmetric(horizontal: space20, vertical: space12),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonBorderRadius)),
  textStyle: labelLarge,
  elevation: 0,
);

// Icon button style
ButtonStyle iconButtonStyle = IconButton.styleFrom(
  backgroundColor: Colors.transparent,
  foregroundColor: textPrimary,
  minimumSize: const Size(buttonIconWidth, buttonIconWidth),
  padding: const EdgeInsets.all(space8),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonBorderRadius)),
);

// ===================== CARD =====================
Card designSystemCard({required Widget child, EdgeInsetsGeometry? padding}) => Card(
  elevation: 1,
  color: cardBackground,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(borderRadiusMedium),
    side: const BorderSide(color: borderColor, width: 1),
  ),
  child: Padding(
    padding: padding ?? const EdgeInsets.all(cardPadding),
    child: child,
  ),
);

// Form card with multiple inputs
Card designSystemFormCard({required Widget child, String? title, EdgeInsetsGeometry? padding}) => Card(
  elevation: 1,
  color: cardBackground,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(borderRadiusMedium),
    side: const BorderSide(color: borderColor, width: 1),
  ),
  child: Padding(
    padding: padding ?? const EdgeInsets.all(cardPadding),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(title, style: h4),
          const SizedBox(height: space16),
        ],
        child,
      ],
    ),
  ),
);

// ===================== INPUT =====================
InputDecoration designSystemInputDecoration({
  String? label,
  String? hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? errorText,
  bool isDense = true,
  EdgeInsetsGeometry? contentPadding,
  Color? fillColor,
  bool? filled,
}) => InputDecoration(
  labelText: label,
  hintText: hint,
  prefixIcon: prefixIcon,
  suffixIcon: suffixIcon,
  errorText: errorText,
  isDense: isDense,
  floatingLabelBehavior: FloatingLabelBehavior.never,
  contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: inputPadding, vertical: inputPadding - 4),
  filled: filled ?? true,
  fillColor: fillColor ?? cardBackground,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(borderRadiusMedium),
    borderSide: const BorderSide(color: borderColor),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(borderRadiusMedium),
    borderSide: const BorderSide(color: borderColor),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(borderRadiusMedium),
    borderSide: const BorderSide(color: mainGreen, width: 2),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(borderRadiusMedium),
    borderSide: const BorderSide(color: destructiveRed),
  ),
  hintStyle: mutedText,
);

// Search input without background
InputDecoration searchInputDecoration({
  String? hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) => InputDecoration(
  hintText: hint ?? 'Search...',
  prefixIcon: prefixIcon ?? const Icon(Icons.search, color: textSecondary),
  suffixIcon: suffixIcon,
  contentPadding: const EdgeInsets.symmetric(horizontal: inputPadding, vertical: inputPadding - 4),
  filled: false,
  isDense: true,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(borderRadiusMedium),
    borderSide: const BorderSide(color: borderColor),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(borderRadiusMedium),
    borderSide: const BorderSide(color: borderColor),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(borderRadiusMedium),
    borderSide: const BorderSide(color: mainGreen, width: 2),
  ),
  hintStyle: mutedText,
);

// ===================== SELECT/DROPDOWN =====================
class DesignSystemDropdownMenu<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool isExpanded;
  
  const DesignSystemDropdownMenu({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.borderRadius = borderRadiusMedium,
    this.padding,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: inputHeight, // 40px
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        isExpanded: isExpanded,
        decoration: designSystemInputDecoration(hint: hint, contentPadding: const EdgeInsets.symmetric(horizontal: inputPadding, vertical: 8)),
        borderRadius: BorderRadius.circular(borderRadius),
        style: body,
        dropdownColor: cardBackground,
        icon: const Icon(Icons.keyboard_arrow_down, color: textSecondary),
        iconSize: iconLarge,
      ),
    );
  }
}

// Custom dropdown with better styling
class DesignSystemSelect<T> extends StatelessWidget {
  final T? value;
  final List<T> options;
  final String Function(T) getLabel;
  final ValueChanged<T?> onChanged;
  final String? placeholder;
  final bool enabled;
  
  const DesignSystemSelect({
    super.key,
    required this.value,
    required this.options,
    required this.getLabel,
    required this.onChanged,
    this.placeholder,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: inputHeight, // 40px
      decoration: BoxDecoration(
        color: enabled ? cardBackground : mutedBackground,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(borderRadiusMedium),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: placeholder != null 
            ? Text(placeholder!, style: mutedText) 
            : null,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: textSecondary),
          iconSize: iconLarge,
          style: body,
          dropdownColor: cardBackground,
          padding: const EdgeInsets.symmetric(horizontal: inputPadding),
          items: options.map((T option) {
            return DropdownMenuItem<T>(
              value: option,
              child: Text(getLabel(option), style: body),
            );
          }).toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}

// ===================== CHECKBOX =====================
class DesignSystemCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String? label;
  final bool enabled;
  
  const DesignSystemCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isChecked = value;
    if (label != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: iconMedium,
            height: iconMedium,
            child: Checkbox(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: mainGreen,
              checkColor: Colors.white,
              side: BorderSide(color: isChecked ? mainGreen : borderColor, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadiusSmall),
              ),
            ),
          ),
          const SizedBox(width: space8),
          Text(label!, style: body),
        ],
      );
    }
    
    return SizedBox(
      width: iconMedium,
      height: iconMedium,
      child: Checkbox(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: mainGreen,
        checkColor: Colors.white,
        side: BorderSide(color: isChecked ? mainGreen : borderColor, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
      ),
    );
  }
}

// ===================== RADIO BUTTON =====================
class DesignSystemRadio<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final ValueChanged<T?> onChanged;
  final String? label;
  final bool enabled;
  
  const DesignSystemRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.label,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (label != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: iconMedium,
            height: iconMedium,
            child: Radio<T>(
              value: value,
              groupValue: groupValue,
              onChanged: enabled ? onChanged : null,
              activeColor: mainGreen,
              fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return mainGreen;
                }
                return borderColor;
              }),
            ),
          ),
          const SizedBox(width: space8),
          Text(label!, style: body),
        ],
      );
    }
    
    return SizedBox(
      width: iconMedium,
      height: iconMedium,
      child: Radio<T>(
        value: value,
        groupValue: groupValue,
        onChanged: enabled ? onChanged : null,
        activeColor: mainGreen,
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return mainGreen;
          }
          return borderColor;
        }),
      ),
    );
  }
}

// Radio group for multiple options
class DesignSystemRadioGroup<T> extends StatelessWidget {
  final List<T> options;
  final T? value;
  final String Function(T) getLabel;
  final ValueChanged<T?> onChanged;
  final Axis direction;
  final bool enabled;
  
  const DesignSystemRadioGroup({
    super.key,
    required this.options,
    required this.value,
    required this.getLabel,
    required this.onChanged,
    this.direction = Axis.vertical,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (direction == Axis.horizontal) {
      return Row(
        children: options.map((T option) {
          return Padding(
            padding: const EdgeInsets.only(right: space16),
            child: DesignSystemRadio<T>(
              value: option,
              groupValue: value,
              onChanged: onChanged,
              label: getLabel(option),
              enabled: enabled,
            ),
          );
        }).toList(),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options.map((T option) {
        return Padding(
          padding: const EdgeInsets.only(bottom: space8),
          child: DesignSystemRadio<T>(
            value: option,
            groupValue: value,
            onChanged: onChanged,
            label: getLabel(option),
            enabled: enabled,
          ),
        );
      }).toList(),
    );
  }
}

// ===================== BADGE =====================
class DesignSystemBadge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final double? borderRadius;
  
  const DesignSystemBadge({
    super.key,
    required this.text,
    this.variant = BadgeVariant.defaultVariant,
    this.padding,
    this.fontSize,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BoxBorder? border;
    
    switch (variant) {
      case BadgeVariant.secondary:
        bg = secondaryGreen.withValues(alpha: 0.12);
        fg = secondaryGreen;
        break;
      case BadgeVariant.destructive:
        bg = destructiveRed.withValues(alpha: 0.12);
        fg = destructiveRed;
        break;
      case BadgeVariant.warning:
        bg = warningOrange.withValues(alpha: 0.12);
        fg = warningOrange;
        break;
      case BadgeVariant.outline:
        bg = Colors.transparent;
        fg = textPrimary;
        border = Border.all(color: borderColor, width: 1);
        break;
      default:
        bg = mainGreen.withValues(alpha: 0.12);
        fg = mainGreen;
    }
    
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius ?? borderRadiusLarge),
        border: border,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: fontSize ?? 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

enum BadgeVariant { defaultVariant, secondary, destructive, warning, outline }

// ===================== DIALOG/MODAL =====================
Future<T?> showDesignSystemDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  List<Widget>? actions,
  IconData? icon,
  Color? iconColor,
  double? maxWidth,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadiusLarge)),
      backgroundColor: cardBackground,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? modalMaxWidth,
          minHeight: modalMinHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              height: modalHeaderHeight,
              padding: const EdgeInsets.symmetric(horizontal: modalPadding),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor, width: 1)),
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: iconColor ?? destructiveRed, size: iconLarge),
                    const SizedBox(width: iconSpacing),
                  ],
                  Expanded(
                    child: Text(title, style: h4),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: iconButtonStyle,
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(modalPadding),
                child: content,
              ),
            ),
            // Actions
            if (actions != null && actions.isNotEmpty) ...[
              Container(
                height: modalFooterHeight,
                padding: const EdgeInsets.symmetric(horizontal: modalPadding, vertical: space16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: borderColor, width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: _withGap(actions, space8),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

// Simple alert dialog (for quick confirmations)
Future<T?> showDesignSystemAlert<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  List<Widget>? actions,
  IconData? icon,
  Color? iconColor,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadiusLarge)),
      backgroundColor: cardBackground,
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor ?? destructiveRed, size: iconLarge),
            const SizedBox(width: iconSpacing),
          ],
          Expanded(child: Text(title, style: h4)),
        ],
      ),
      content: content,
      actions: actions,
      actionsPadding: const EdgeInsets.symmetric(horizontal: space16, vertical: space8),
    ),
  );
}

// Bottom sheet modal
Future<T?> showDesignSystemBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  double? height,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: height,
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(borderRadiusXLarge),
          topRight: Radius.circular(borderRadiusXLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: space12),
            decoration: BoxDecoration(
              color: mutedBackground,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(child: child),
        ],
      ),
    ),
  );
}

// ===================== ALERT =====================
class DesignSystemAlert extends StatelessWidget {
  final String title;
  final String? message;
  final AlertVariant variant;
  final IconData? icon;
  
  const DesignSystemAlert({
    super.key,
    required this.title,
    this.message,
    this.variant = AlertVariant.info,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData displayIcon = icon ?? Icons.info_outline;
    
    switch (variant) {
      case AlertVariant.warning:
        bg = warningOrange.withValues(alpha: 0.12);
        fg = warningOrange;
        displayIcon = icon ?? Icons.warning_amber_rounded;
        break;
      case AlertVariant.error:
        bg = destructiveRed.withValues(alpha: 0.12);
        fg = destructiveRed;
        displayIcon = icon ?? Icons.error_outline;
        break;
      case AlertVariant.success:
        bg = secondaryGreen.withValues(alpha: 0.12);
        fg = secondaryGreen;
        displayIcon = icon ?? Icons.check_circle_outline;
        break;
      default:
        bg = mainGreen.withValues(alpha: 0.12);
        fg = mainGreen;
        displayIcon = icon ?? Icons.info_outline;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: space16, vertical: space12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadiusLarge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(displayIcon, color: fg, size: iconLarge),
          const SizedBox(width: space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: body.copyWith(fontWeight: FontWeight.bold, color: fg)),
                if (message != null) ...[
                  const SizedBox(height: space2),
                  Text(message!, style: small.copyWith(color: fg)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum AlertVariant { info, warning, error, success }

// ===================== SEPARATOR =====================
class DesignSystemSeparator extends StatelessWidget {
  final double thickness;
  final Color? color;
  final double? indent;
  final double? endIndent;
  
  const DesignSystemSeparator({
    super.key,
    this.thickness = 1,
    this.color,
    this.indent,
    this.endIndent,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      thickness: thickness,
      color: color ?? borderColor,
      indent: indent,
      endIndent: endIndent,
      height: thickness,
    );
  }
}

// ===================== SKELETON (LOADING PLACEHOLDER) =====================
class DesignSystemSkeleton extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadiusGeometry borderRadius;
  
  const DesignSystemSkeleton({
    super.key,
    this.height = 16,
    this.width = double.infinity,
    this.borderRadius = const BorderRadius.all(Radius.circular(borderRadiusMedium)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: mutedBackground,
        borderRadius: borderRadius,
      ),
    );
  }
}

// ===================== FORM SECTION =====================
class DesignSystemFormSection extends StatelessWidget {
  final String? title;
  final String? description;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double gap;
  
  const DesignSystemFormSection({
    super.key,
    this.title,
    this.description,
    required this.children,
    this.padding,
    this.gap = space16,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: sectionSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: h2),
            if (description != null) ...[
              const SizedBox(height: space4),
              Text(description!, style: small.copyWith(color: textSecondary)),
            ],
            const SizedBox(height: space16),
          ],
          ..._withGap(children, gap),
        ],
      ),
    );
  }
}

// ===================== FORM FIELD =====================
class DesignSystemFormField extends StatelessWidget {
  final String label;
  final Widget input;
  final String? errorText;
  final String? helperText;
  final bool required;
  final double gap;
  
  const DesignSystemFormField({
    super.key,
    required this.label,
    required this.input,
    this.errorText,
    this.helperText,
    this.required = false,
    this.gap = space8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: labelMedium.copyWith(fontWeight: FontWeight.w600)),
            if (required) ...[
              const SizedBox(width: space2),
              const Text('*', style: TextStyle(color: destructiveRed, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        SizedBox(height: gap),
        input,
        if (helperText != null && (errorText == null || errorText!.isEmpty)) ...[
          const SizedBox(height: space4),
          Text(helperText!, style: caption.copyWith(color: textSecondary)),
        ],
        if (errorText != null && errorText!.isNotEmpty) ...[
          const SizedBox(height: space4),
          Text(errorText!, style: caption.copyWith(color: destructiveRed)),
        ],
      ],
    );
  }
}

// ===================== FORM ACTIONS =====================
class DesignSystemFormActions extends StatelessWidget {
  final List<Widget> actions;
  final MainAxisAlignment alignment;
  final double gap;
  
  const DesignSystemFormActions({
    super.key,
    required this.actions,
    this.alignment = MainAxisAlignment.end,
    this.gap = space16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: _withGap(actions, gap),
    );
  }
}

// ===================== NAVIGATION STYLES =====================
BoxDecoration sidebarItemDecoration = BoxDecoration(
  borderRadius: BorderRadius.circular(borderRadiusMedium),
  color: Colors.transparent,
);

BoxDecoration sidebarItemActiveDecoration = BoxDecoration(
  borderRadius: BorderRadius.circular(borderRadiusMedium),
  color: sidebarAccent,
);

// ===================== CURRENCY FORMATTING =====================
const String currencySymbol = '₫';
const String currencyLocale = 'vi_VN';

// Format tiền chuẩn: 1,500,000 ₫
String formatCurrency(double amount) {
  return '${amount.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  )} $currencySymbol';
}

// Format tiền compact: 1.5M ₫ (cho số lớn)
String formatCurrencyCompact(double amount) {
  if (amount >= 1000000) {
    final millions = amount / 1000000;
    return '${millions.toStringAsFixed(millions.truncateToDouble() == millions ? 0 : 1)}M $currencySymbol';
  } else if (amount >= 1000) {
    final thousands = amount / 1000;
    return '${thousands.toStringAsFixed(thousands.truncateToDouble() == thousands ? 0 : 0)}K $currencySymbol';
  } else {
    return formatCurrency(amount);
  }
}

// Hàm helper để tạo NumberFormat instance
NumberFormat getCurrencyFormatter() {
  return NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
}

// ===================== RESPONSIVE UTILITIES =====================
EdgeInsets getResponsivePadding(double screenWidth) {
  if (screenWidth < 600) {
    return const EdgeInsets.all(space16);
  } else if (screenWidth < 900) {
    return const EdgeInsets.all(space24);
  } else {
    return const EdgeInsets.all(space32);
  }
}

double getResponsiveCardWidth(double screenWidth) {
  if (screenWidth < 600) {
    return screenWidth - (space16 * 2);
  } else if (screenWidth < 900) {
    return 600;
  } else {
    return 800;
  }
}

bool isMobile(double screenWidth) => screenWidth < 600;
bool isTablet(double screenWidth) => screenWidth >= 600 && screenWidth < 900;
bool isDesktop(double screenWidth) => screenWidth >= 900;

// ===================== THEME =====================
ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: mainGreen,
    secondary: secondaryGreen,
    error: destructiveRed,
    background: appBackground,
    surface: cardBackground,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onError: Colors.white,
    onBackground: textPrimary,
    onSurface: textPrimary,
  ),
  textTheme: TextTheme(
    displayLarge: h1,
    displayMedium: h2,
    displaySmall: h3,
    headlineMedium: h4,
    bodyLarge: bodyLarge,
    bodyMedium: body,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  ),
  scaffoldBackgroundColor: appBackground,
  cardTheme: CardThemeData(
    color: cardBackground,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadiusMedium),
      side: const BorderSide(color: borderColor),
    ),
    margin: EdgeInsets.zero,
  ),
  dividerColor: borderColor,
  appBarTheme: AppBarTheme(
    backgroundColor: appBackground,
    foregroundColor: textPrimary,
    elevation: 0,
    shadowColor: borderColor,
    titleTextStyle: h4,
    toolbarHeight: headerHeight,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
  outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryButtonStyle),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: appBackground,
    border: designSystemInputDecoration().border,
    enabledBorder: designSystemInputDecoration().enabledBorder,
    focusedBorder: designSystemInputDecoration().focusedBorder,
    errorBorder: designSystemInputDecoration().errorBorder,
    contentPadding: designSystemInputDecoration().contentPadding,
    hintStyle: designSystemInputDecoration().hintStyle,
  ),
);

// ===================== UTILS =====================
List<Widget> _withGap(List<Widget> children, double gap) {
  if (children.isEmpty) return [];
  final List<Widget> result = [];
  for (int i = 0; i < children.length; i++) {
    result.add(children[i]);
    if (i < children.length - 1) {
      result.add(SizedBox(width: gap));
    }
  }
  return result;
}

/// ========================================
/// USAGE EXAMPLES
/// ========================================

/*
// Example 1: Using colors
Container(
  color: mainGreen,
  child: Text(
    'Hello',
    style: TextStyle(color: Colors.white),
  ),
)

// Example 2: Using typography
Text(
  'Heading Text',
  style: h2,
)

// Example 3: Using card
designSystemCard(
  child: Column(children: [...]),
)

// Example 4: Using form card
designSystemFormCard(
  title: 'Product Information',
  child: Column(
    children: [
      DesignSystemFormField(
        label: 'Product Name',
        required: true,
        input: TextField(
          decoration: designSystemInputDecoration(hint: 'Enter product name'),
        ),
      ),
      // ... more form fields
    ],
  ),
)

// Example 5: Using button styles
ElevatedButton(
  style: primaryButtonStyle,
  onPressed: () {},
  child: Text('Primary Button'),
)

// Example 6: Ghost button with border
OutlinedButton(
  style: ghostBorderButtonStyle,
  onPressed: () {},
  child: Text('Ghost Button'),
)

// Example 7: Using input decoration
TextField(
  decoration: designSystemInputDecoration(
    label: 'Tên sản phẩm',
    hint: 'Nhập tên sản phẩm...',
  ),
)

// Example 8: Search input without background
TextField(
  decoration: searchInputDecoration(
    hint: 'Search products...',
  ),
)

// Example 9: Using dropdown/select
DesignSystemDropdownMenu<String>(
  value: selectedValue,
  items: [
    DropdownMenuItem(value: 'option1', child: Text('Option 1')),
    DropdownMenuItem(value: 'option2', child: Text('Option 2')),
  ],
  onChanged: (value) => setState(() => selectedValue = value),
  hint: 'Select an option',
)

// Example 10: Custom select
DesignSystemSelect<String>(
  value: selectedOption,
  options: ['Option 1', 'Option 2', 'Option 3'],
  getLabel: (option) => option,
  onChanged: (value) => setState(() => selectedOption = value),
  placeholder: 'Choose option',
)

// Example 11: Checkbox
DesignSystemCheckbox(
  value: isChecked,
  onChanged: (value) => setState(() => isChecked = value ?? false),
  label: 'I agree to terms and conditions',
)

// Example 12: Radio button
DesignSystemRadio<String>(
  value: 'option1',
  groupValue: selectedRadio,
  onChanged: (value) => setState(() => selectedRadio = value),
  label: 'Option 1',
)

// Example 13: Radio group
DesignSystemRadioGroup<String>(
  options: ['Option 1', 'Option 2', 'Option 3'],
  value: selectedRadio,
  getLabel: (option) => option,
  onChanged: (value) => setState(() => selectedRadio = value),
  direction: Axis.vertical,
)

// Example 14: Using the complete theme
MaterialApp(
  theme: lightTheme,
  home: YourHomeWidget(),
)

// Example 15: Currency formatting
Text(formatCurrency(1500000)) // Output: "1,500,000 ₫"

// Example 16: Responsive design
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  return Container(
    padding: getResponsivePadding(screenWidth),
    width: getResponsiveCardWidth(screenWidth),
    child: YourContent(),
  );
}

// Example 17: Using badges
DesignSystemBadge(
  text: 'Active',
  variant: BadgeVariant.secondary,
)

// Example 18: Using alerts
DesignSystemAlert(
  title: 'Success',
  message: 'Operation completed successfully',
  variant: AlertVariant.success,
)

// Example 19: Form field
DesignSystemFormField(
  label: 'Product Name',
  required: true,
  input: TextField(
    decoration: designSystemInputDecoration(hint: 'Enter product name'),
  ),
)

// Example 20: Modal dialog
showDesignSystemDialog(
  context: context,
  title: 'Confirm Delete',
  content: Text('Are you sure you want to delete this item?'),
  icon: Icons.delete,
  iconColor: destructiveRed,
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text('Cancel'),
    ),
    ElevatedButton(
      style: destructiveButtonStyle,
      onPressed: () => Navigator.pop(context, true),
      child: Text('Delete'),
    ),
  ],
)

// Example 21: Bottom sheet
showDesignSystemBottomSheet(
  context: context,
  height: 300,
  child: YourBottomSheetContent(),
)
*/

// ===================== SNACKBAR/TOAST =====================
class DesignSystemSnackbar extends StatefulWidget {
  final String message;
  final IconData? icon;
  final Duration duration;
  final VoidCallback? onDismissed;
  const DesignSystemSnackbar({
    super.key,
    required this.message,
    this.icon,
    this.duration = const Duration(seconds: 3),
    this.onDismissed,
  });

  @override
  State<DesignSystemSnackbar> createState() => _DesignSystemSnackbarState();
}

class _DesignSystemSnackbarState extends State<DesignSystemSnackbar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1.2),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutExpo,
    ));
    _controller.forward();
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (widget.onDismissed != null) widget.onDismissed!();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32, right: 32),
        child: SlideTransition(
          position: _offsetAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(borderRadiusMedium),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon ?? Icons.check_circle, color: secondaryGreen, size: 20),
                  const SizedBox(width: 12),
                  Text(widget.message, style: bodyLarge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== DROPDOWN MENU HOVER =====================
class MutedDropdownMenuItem<T> extends StatelessWidget {
  final T value;
  final Widget child;
  const MutedDropdownMenuItem({super.key, required this.value, required this.child});
  @override
  Widget build(BuildContext context) {
    return _HoverContainer(child: child);
  }
}

class _HoverContainer extends StatefulWidget {
  final Widget child;
  const _HoverContainer({required this.child});
  @override
  State<_HoverContainer> createState() => _HoverContainerState();
}
class _HoverContainerState extends State<_HoverContainer> {
  bool _hovering = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Container(
        color: _hovering ? mutedBackground : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: widget.child,
      ),
    );
  }
}

// ===================== SHOPIFY STYLE DROPDOWN =====================
class ShopifyDropdown<T> extends StatefulWidget {
  final List<T> items;
  final T? value;
  final String Function(T) getLabel;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final double maxHeight;
  final bool enabled;
  final Color? backgroundColor;

  const ShopifyDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.getLabel,
    required this.onChanged,
    this.hint,
    this.maxHeight = 260,
    this.enabled = true,
    this.backgroundColor,
  });

  @override
  State<ShopifyDropdown<T>> createState() => _ShopifyDropdownState<T>();
}

class _ShopifyDropdownState<T> extends State<ShopifyDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Transparent barrier to detect outside tap
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 4),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: widget.maxHeight,
                    minWidth: size.width,
                  ),
                  decoration: BoxDecoration(
                    color: cardBackground,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(buttonBorderRadius),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: widget.items.length,
                      itemBuilder: (context, index) {
                        final item = widget.items[index];
                        final selected = item == widget.value;
                        return _ShopifyDropdownItem<T>(
                          label: widget.getLabel(item),
                          selected: selected,
                          onTap: () {
                            widget.onChanged(item);
                            _removeOverlay();
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    final selectedLabel = widget.value != null ? widget.getLabel(widget.value as T) : null;
    return SizedBox(
      height: inputHeight, // 40px
      child: CompositedTransformTarget(
        link: _layerLink,
        child: GestureDetector(
          onTap: widget.enabled ? _toggleDropdown : null,
          child: Focus(
            focusNode: _focusNode,
            onFocusChange: (hasFocus) {
              if (!hasFocus) _removeOverlay();
            },
            child: Container(
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? cardBackground,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(buttonBorderRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduce vertical padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      selectedLabel ?? (widget.hint ?? ''),
                      style: body.copyWith(
                        color: widget.enabled
                            ? (selectedLabel != null ? textPrimary : textMuted)
                            : textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopifyDropdownItem<T> extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ShopifyDropdownItem({required this.label, required this.selected, required this.onTap});
  @override
  State<_ShopifyDropdownItem<T>> createState() => _ShopifyDropdownItemState<T>();
}

class _ShopifyDropdownItemState<T> extends State<_ShopifyDropdownItem<T>> {
  bool _hovering = false;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      onHover: (hover) => setState(() => _hovering = hover),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _hovering
              ? mutedBackground
              : widget.selected
                  ? mutedBackground.withValues(alpha: 0.5)
                  : Colors.transparent,
        ),
        child: Text(
          widget.label,
          style: body.copyWith(
            color: textPrimary,
            fontWeight: widget.selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class FilterSidebarContent extends StatefulWidget {
  final VoidCallback? onClose;
  final List<String> categories;
  final List<String> tags;
  final String selectedCategory;
  final RangeValues priceRange;
  final RangeValues stockRange;
  final String status;
  final Set<String> selectedTags;
  final void Function({required String category, required RangeValues price, required RangeValues stock, required String statusValue, required Set<String> tagsValue}) onApply;
  final VoidCallback onReset;
  const FilterSidebarContent({
    Key? key,
    this.onClose,
    required this.categories,
    required this.tags,
    required this.selectedCategory,
    required this.priceRange,
    required this.stockRange,
    required this.status,
    required this.selectedTags,
    required this.onApply,
    required this.onReset,
  }) : super(key: key);

  @override
  State<FilterSidebarContent> createState() => _FilterSidebarContentState();
}

class _FilterSidebarContentState extends State<FilterSidebarContent> {
  late String selectedCategory;
  late RangeValues priceRange;
  late RangeValues stockRange;
  late String status;
  late Set<String> selectedTags;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.selectedCategory;
    priceRange = widget.priceRange;
    stockRange = widget.stockRange;
    status = widget.status;
    selectedTags = Set<String>.from(widget.selectedTags);
  }

  void _reset() {
    setState(() {
      selectedCategory = 'Tất cả';
      priceRange = const RangeValues(3000, 375000);
      stockRange = const RangeValues(50, 500);
      status = 'Tất cả';
      selectedTags.clear();
    });
    widget.onReset();
  }

  void _apply() {
    widget.onApply(
      category: selectedCategory,
      price: priceRange,
      stock: stockRange,
      statusValue: status,
      tagsValue: selectedTags,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bộ lọc sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text('Danh mục sản phẩm', style: labelLarge),
                const SizedBox(height: 8),
                ShopifyDropdown<String>(
                  items: widget.categories,
                  value: selectedCategory,
                  getLabel: (c) => c,
                  onChanged: (val) => setState(() => selectedCategory = val ?? 'Tất cả'),
                  hint: 'Chọn danh mục',
                ),
                const SizedBox(height: 24),
                Text('Khoảng giá', style: labelLarge),
                const SizedBox(height: 8),
                designSystemRangeSlider(
                  context: context,
                  values: priceRange,
                  min: widget.priceRange.start,
                  max: widget.priceRange.end,
                  divisions: 100,
                  onChanged: (v) => setState(() => priceRange = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${priceRange.start.toStringAsFixed(0)}₫', style: caption),
                    Text('${priceRange.end.toStringAsFixed(0)}₫', style: caption),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Tồn kho', style: labelLarge),
                const SizedBox(height: 8),
                designSystemRangeSlider(
                  context: context,
                  values: stockRange,
                  min: widget.stockRange.start,
                  max: widget.stockRange.end,
                  divisions: 50,
                  onChanged: (v) => setState(() => stockRange = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${stockRange.start.toInt()}', style: caption),
                    Text('${stockRange.end.toInt()}', style: caption),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Trạng thái sản phẩm', style: labelLarge),
                const SizedBox(height: 8),
                DesignSystemRadioGroup<String>(
                  options: const ['Tất cả', 'Còn bán', 'Ngừng bán'],
                  value: status,
                  getLabel: (s) => s,
                  onChanged: (v) => setState(() => status = v ?? 'Tất cả'),
                  direction: Axis.vertical,
                ),
                const SizedBox(height: 24),
                Text('Tags', style: labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.tags.map((tag) {
                    final isSelected = selectedTags.contains(tag);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (isSelected) {
                          selectedTags.remove(tag);
                        } else {
                          selectedTags.add(tag);
                        }
                      }),
                      child: DesignSystemBadge(
                        text: tag,
                        variant: isSelected ? BadgeVariant.secondary : BadgeVariant.outline,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        fontSize: 13,
                        borderRadius: 16,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _reset,
                        child: const Text('Xóa bộ lọc'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _apply,
                        style: primaryButtonStyle,
                        child: const Text('Áp dụng'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ===================== RANGE SLIDER =====================
Widget designSystemRangeSlider({
  required BuildContext context,
  required RangeValues values,
  required double min,
  required double max,
  required ValueChanged<RangeValues> onChanged,
  int? divisions,
  String? label,
  Color? activeColor,
  Color? inactiveColor,
  double trackHeight = 4,
  double thumbRadius = 10,
  double overlayRadius = 18,
}) {
  return SliderTheme(
    data: SliderTheme.of(context).copyWith(
      activeTrackColor: activeColor ?? mainGreen,
      inactiveTrackColor: inactiveColor ?? borderColor,
      trackHeight: trackHeight,
      rangeThumbShape: RoundRangeSliderThumbShape(enabledThumbRadius: thumbRadius),
      overlayShape: RoundSliderOverlayShape(overlayRadius: overlayRadius),
      thumbColor: activeColor ?? mainGreen,
      overlayColor: (activeColor ?? mainGreen).withValues(alpha: 0.12),
      valueIndicatorColor: activeColor ?? mainGreen,
      tickMarkShape: const RoundSliderTickMarkShape(),
      activeTickMarkColor: borderColor,
      inactiveTickMarkColor: borderColor.withValues(alpha: 0.5),
    ),
    child: RangeSlider(
      values: values,
      min: min,
      max: max,
      divisions: divisions,
      labels: label != null ? RangeLabels(label, label) : null,
      onChanged: onChanged,
    ),
  );
}

// ===== TABLE DESIGN SYSTEM =====

/// Table Design System for consistent data presentation
/// 
/// Tables are used to display structured data in rows and columns.
/// This system provides consistent styling for table containers, headers, and rows.
class TableDesignSystem {
  // Table Container Styles
  static BoxDecoration tableContainerDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: borderColor),
  );

  // Table Header Styles
  static BoxDecoration tableHeaderDecoration = BoxDecoration(
    border: Border(bottom: BorderSide(color: borderColor)),
  );

  static EdgeInsets tableHeaderPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16);

  static TextStyle tableHeaderTextStyle = const TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: textSecondary,
  );

  // Table Row Styles
  static EdgeInsets tableRowPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16);

  static BoxDecoration tableRowDecoration = BoxDecoration(
    border: Border(bottom: BorderSide(color: borderColor.withValues(alpha: 0.5))),
  );

  static TextStyle tableRowTextStyle = const TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 14,
  );

  static TextStyle tableRowSubtitleStyle = TextStyle(
    fontSize: 13,
    color: Colors.grey[600],
  );

  // Table Loading State
  static Widget tableLoadingState = const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: CircularProgressIndicator(),
    ),
  );

  // Table Empty State
  static Widget tableEmptyState(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message),
    ),
  );

  // Table Error State
  static Widget tableErrorState(String error) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text('Error: $error'),
    ),
  );
}

/// Standard table container widget
class StandardTableContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const StandardTableContainer({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: TableDesignSystem.tableContainerDecoration,
      padding: padding,
      child: child,
    );
  }
}

/// Standard table header widget
class StandardTableHeader extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;

  const StandardTableHeader({
    super.key,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? TableDesignSystem.tableHeaderPadding,
      decoration: TableDesignSystem.tableHeaderDecoration,
      child: Row(children: children),
    );
  }
}

/// Standard table row widget
class StandardTableRow extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final bool isSelectable;

  const StandardTableRow({
    super.key,
    required this.children,
    this.padding,
    this.onTap,
    this.isSelectable = true,
  });

  @override
  Widget build(BuildContext context) {
    final rowContent = Container(
      padding: padding ?? TableDesignSystem.tableRowPadding,
      decoration: TableDesignSystem.tableRowDecoration,
      child: Row(children: children),
    );

    if (!isSelectable || onTap == null) {
      return rowContent;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: rowContent,
      ),
    );
  }
}

/// Table column with flexible width
class TableColumn extends StatelessWidget {
  final Widget child;
  final int flex;
  final CrossAxisAlignment alignment;
  final EdgeInsets? padding;

  const TableColumn({
    super.key,
    required this.child,
    this.flex = 1,
    this.alignment = CrossAxisAlignment.start,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Table column with fixed width
class TableColumnFixed extends StatelessWidget {
  final Widget child;
  final double width;
  final CrossAxisAlignment alignment;
  final EdgeInsets? padding;

  const TableColumnFixed({
    super.key,
    required this.child,
    required this.width,
    this.alignment = CrossAxisAlignment.start,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: padding,
        child: child,
      ),
    );
  }
}

// ===== SUBPAGE STYLEGUIDE =====

/// Example: How to use Table Design System
/// 
/// This example shows how to create a product list table using the design system
class ExampleProductTable extends StatelessWidget {
  final List<Product> products;
  final Function(Product)? onProductTap;
  final Function(Product)? onEdit;
  final Function(Product)? onDelete;

  const ExampleProductTable({
    super.key,
    required this.products,
    this.onProductTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return StandardTableContainer(
        child: TableDesignSystem.tableEmptyState('No products available'),
      );
    }

    return StandardTableContainer(
      child: Column(
        children: [
          StandardTableHeader(
            children: [
              TableColumn(
                flex: 3,
                child: Text('Product Name', style: TableDesignSystem.tableHeaderTextStyle),
              ),
              TableColumn(
                flex: 1,
                child: Text('Stock', style: TableDesignSystem.tableHeaderTextStyle),
              ),
              TableColumn(
                flex: 1,
                child: Text('Price', style: TableDesignSystem.tableHeaderTextStyle),
              ),
              if (onEdit != null || onDelete != null)
                TableColumnFixed(
                  width: 100,
                  child: Text('Actions', style: TableDesignSystem.tableHeaderTextStyle),
                ),
            ],
          ),
          ...products.map((product) => StandardTableRow(
            onTap: onProductTap != null ? () => onProductTap!(product) : null,
            children: [
              TableColumn(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.internalName ?? '', style: TableDesignSystem.tableRowTextStyle),
                    Text(product.tradeName ?? '', style: TableDesignSystem.tableRowSubtitleStyle),
                  ],
                ),
              ),
              TableColumn(
                flex: 1,
                child: Text((product.stockSystem ?? 0).toString(), style: TableDesignSystem.tableRowTextStyle),
              ),
              TableColumn(
                flex: 1,
                child: Text('\$${product.salePrice ?? 0}', style: TableDesignSystem.tableRowTextStyle),
              ),
              if (onEdit != null || onDelete != null)
                TableColumnFixed(
                  width: 100,
                  child: Row(
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => onEdit!(product),
                        ),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => onDelete!(product),
                        ),
                    ],
                  ),
                ),
            ],
          )),
        ],
      ),
    );
  }
}

/// Example: Hierarchical category table
class ExampleCategoryTreeTable extends StatelessWidget {
  final List<ProductCategory> categories;
  final Function(ProductCategory)? onCategoryTap;
  final Set<String> expandedCategories;
  final Function(String) onToggleExpand;
  final Map<String, int> categoryProductCounts; // Map category ID to product count

  const ExampleCategoryTreeTable({
    super.key,
    required this.categories,
    this.onCategoryTap,
    required this.expandedCategories,
    required this.onToggleExpand,
    required this.categoryProductCounts,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return StandardTableContainer(
        child: TableDesignSystem.tableEmptyState('No categories available'),
      );
    }

    return StandardTableContainer(
      child: Column(
        children: [
          StandardTableHeader(
            children: [
              TableColumn(
                flex: 3,
                child: Text('Category Name', style: TableDesignSystem.tableHeaderTextStyle),
              ),
              TableColumnFixed(
                width: 120,
                child: Text('Products', style: TableDesignSystem.tableHeaderTextStyle),
              ),
            ],
          ),
          ...buildCategoryTree(categories, level: 0),
        ],
      ),
    );
  }

  List<Widget> buildCategoryTree(List<ProductCategory> categories, {int level = 0}) {
    return categories.map((category) {
      // Check if this category has children by looking for categories with this as parent
      final hasChildren = categories.any((c) => c.parentId == category.id);
      final isExpanded = expandedCategories.contains(category.id);
      final isChild = level > 0;

      return Column(
        children: [
          StandardTableRow(
            onTap: () {
              if (hasChildren) {
                onToggleExpand(category.id);
              } else if (onCategoryTap != null) {
                onCategoryTap!(category);
              }
            },
            children: [
              TableColumn(
                flex: 3,
                child: Row(
                  children: [
                    SizedBox(width: level * 32), // Indentation
                    SizedBox(
                      width: 28,
                      child: Center(
                        child: hasChildren && !isChild
                          ? AnimatedRotation(
                              duration: const Duration(milliseconds: 200),
                              turns: isExpanded ? 0.25 : 0,
                              child: Icon(
                                Icons.keyboard_arrow_right,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                            )
                          : isChild
                            ? Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[600],
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(category.name, style: TableDesignSystem.tableRowTextStyle),
                          if (category.description.isNotEmpty)
                            Text(category.description, style: TableDesignSystem.tableRowSubtitleStyle),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              TableColumnFixed(
                width: 120,
                child: Text(
                  categoryProductCounts[category.id]?.toString() ?? '0',
                  style: TableDesignSystem.tableRowTextStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          if (hasChildren && isExpanded) ...[
            ...buildCategoryTree(
              categories.where((c) => c.parentId == category.id).toList(), 
              level: level + 1
            ),
          ],
        ],
      );
    }).toList();
  }
}
