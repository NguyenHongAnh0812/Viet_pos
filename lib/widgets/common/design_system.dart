import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// VET-POS Flutter Style Guide
/// Based on the VET-POS web design system with consistent naming conventions

// ===================== COLORS =====================
const Color primaryBlue = Color(0xFF3A6FF8); // --primary
const Color secondaryGreen = Color(0xFF67C687); // --secondary
const Color warningOrange = Color(0xFFFFB547); // --warning
const Color destructiveRed = Color(0xFFFF5A5F); // --destructive
const Color borderColor = Color(0xFFE5E7EB); // --border

const Color appBackground = Color(0xFFF7F9FC); // --background (changed to white)
const Color cardBackground = Color(0xFFFFFFFF); // --card
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

// ===================== RESPONSIVE TYPOGRAPHY =====================
TextStyle responsiveTextStyle(BuildContext context, TextStyle desktop, TextStyle mobile) {
  return MediaQuery.of(context).size.width < 1024 ? mobile : desktop;
}

// ===================== TYPOGRAPHY =====================
TextStyle getInterTextStyle({
  required double fontSize,
  required FontWeight fontWeight,
  Color color = textPrimary,
  double? height,
}) {
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}

// Heading Styles
TextStyle get h1 => getInterTextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2);
TextStyle get h2 => getInterTextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2);
TextStyle get h3 => getInterTextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4);
TextStyle get h4 => getInterTextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);

// Body Text Styles
TextStyle get bodyLarge => getInterTextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
TextStyle get body => getInterTextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
TextStyle get bodySmall => getInterTextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4);

// Label Styles
TextStyle get labelLarge => getInterTextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4);
TextStyle get labelMedium => getInterTextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.4);
TextStyle get labelSmall => getInterTextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.3);

// Utility Styles
TextStyle get heading => getInterTextStyle(fontSize: 16, fontWeight: FontWeight.w400);
TextStyle get caption => getInterTextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textMuted);
TextStyle get small => getInterTextStyle(fontSize: 14, fontWeight: FontWeight.w400);
TextStyle get mutedText => getInterTextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textMuted, height: 1.5);

// Mobile Styles
TextStyle get h1Mobile => getInterTextStyle(fontSize: 20, fontWeight: FontWeight.w700);
TextStyle get h2Mobile => getInterTextStyle(fontSize: 16, fontWeight: FontWeight.w700);
TextStyle get h3Mobile => getInterTextStyle(fontSize: 14, fontWeight: FontWeight.w600);
TextStyle get bodyMobile => getInterTextStyle(fontSize: 14, fontWeight: FontWeight.w400);
TextStyle get smallMobile => getInterTextStyle(fontSize: 12, fontWeight: FontWeight.w400);
TextStyle get captionMobile => getInterTextStyle(fontSize: 11, fontWeight: FontWeight.w400);

// ===================== BUTTON STYLES =====================
const double buttonBorderRadius = 6.0;

ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: primaryBlue,
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
  backgroundColor: primaryBlue,
  foregroundColor: Colors.white,
  minimumSize: const Size(buttonMinWidth, buttonHeightSmall),
  padding: const EdgeInsets.symmetric(horizontal: space12, vertical: space4),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonBorderRadius)),
  textStyle: labelMedium,
  elevation: 0,
);

ButtonStyle largeButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: primaryBlue, 
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

// Box decoration for manual card styling
BoxDecoration cardDecoration = BoxDecoration(
  color: cardBackground,
  borderRadius: BorderRadius.circular(borderRadiusMedium),
  boxShadow: const [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ],
  border: Border.all(color: borderColor, width: 1),
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
    borderSide: const BorderSide(color: primaryBlue, width: 2),
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
    borderSide: const BorderSide(color: primaryBlue, width: 2),
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
              activeColor: primaryBlue,
              checkColor: Colors.white,
              side: BorderSide(color: isChecked ? primaryBlue : borderColor, width: 1.5),
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
        activeColor: primaryBlue,
        checkColor: Colors.white,
        side: BorderSide(color: isChecked ? primaryBlue : borderColor, width: 1.5),
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
              activeColor: primaryBlue,
              fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.selected)) {
                  return primaryBlue;
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
        activeColor: primaryBlue,
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryBlue;
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
        bg = secondaryGreen.withOpacity(0.12);
        fg = secondaryGreen;
        break;
      case BadgeVariant.destructive:
        bg = destructiveRed.withOpacity(0.12);
        fg = destructiveRed;
        break;
      case BadgeVariant.warning:
        bg = warningOrange.withOpacity(0.12);
        fg = warningOrange;
        break;
      case BadgeVariant.outline:
        bg = Colors.transparent;
        fg = textPrimary;
        border = Border.all(color: borderColor, width: 1);
        break;
      default:
        bg = primaryBlue.withOpacity(0.12);
        fg = primaryBlue;
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

// Dialog decoration for manual styling
BoxDecoration dialogDecoration = BoxDecoration(
  color: cardBackground,
  borderRadius: BorderRadius.circular(borderRadiusLarge),
  boxShadow: const [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ],
);

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
        bg = warningOrange.withOpacity(0.12);
        fg = warningOrange;
        displayIcon = icon ?? Icons.warning_amber_rounded;
        break;
      case AlertVariant.error:
        bg = destructiveRed.withOpacity(0.12);
        fg = destructiveRed;
        displayIcon = icon ?? Icons.error_outline;
        break;
      case AlertVariant.success:
        bg = secondaryGreen.withOpacity(0.12);
        fg = secondaryGreen;
        displayIcon = icon ?? Icons.check_circle_outline;
        break;
      default:
        bg = primaryBlue.withOpacity(0.12);
        fg = primaryBlue;
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

String formatCurrency(double amount) {
  return '${amount.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  )} $currencySymbol';
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
    primary: primaryBlue,
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

List<Widget> _withVerticalGap(List<Widget> children, double gap) {
  if (children.isEmpty) return [];
  final List<Widget> result = [];
  for (int i = 0; i < children.length; i++) {
    result.add(children[i]);
    if (i < children.length - 1) {
      result.add(SizedBox(height: gap));
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
  color: primaryBlue,
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
                  ? mutedBackground.withOpacity(0.5)
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
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text('Danh mục sản phẩm', style: labelLarge),
                const SizedBox(height: 8),
                DesignSystemSelect<String>(
                  value: selectedCategory,
                  options: widget.categories,
                  getLabel: (c) => c,
                  onChanged: (val) => setState(() => selectedCategory = val ?? 'Tất cả'),
                  placeholder: 'Chọn danh mục',
                ),
                const SizedBox(height: 24),
                Text('Khoảng giá', style: labelLarge),
                const SizedBox(height: 8),
                // Tạm thời ẩn range slider
                // designSystemRangeSlider(
                //   context: context,
                //   values: priceRange,
                //   min: 3000,
                //   max: 375000,
                //   divisions: 100,
                //   onChanged: (v) => setState(() => priceRange = v),
                // ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     Text('${priceRange.start.toStringAsFixed(0)}đ', style: caption),
                //     Text('${priceRange.end.toStringAsFixed(0)}đ', style: caption),
                //   ],
                // ),
                const SizedBox(height: 24),
                Text('Tồn kho', style: labelLarge),
                const SizedBox(height: 8),
                // Tạm thời ẩn range slider
                // designSystemRangeSlider(
                //   context: context,
                //   values: stockRange,
                //   min: 50,
                //   max: 500,
                //   divisions: 50,
                //   onChanged: (v) => setState(() => stockRange = v),
                // ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     Text('${stockRange.start.toInt()}', style: caption),
                //     Text('${stockRange.end.toInt()}', style: caption),
                //   ],
                // ),
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
                  children: widget.tags.map((tag) => FilterChip(
                    label: Text(tag, style: bodySmall),
                    selected: selectedTags.contains(tag),
                    onSelected: (v) => setState(() {
                      if (v) {
                        selectedTags.add(tag);
                      } else {
                        selectedTags.remove(tag);
                      }
                    }),
                    selectedColor: primaryBlue.withOpacity(0.12),
                    checkmarkColor: primaryBlue,
                  )).toList(),
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
      activeTrackColor: activeColor ?? primaryBlue,
      inactiveTrackColor: inactiveColor ?? borderColor,
      trackHeight: trackHeight,
      rangeThumbShape: RoundRangeSliderThumbShape(enabledThumbRadius: thumbRadius),
      overlayShape: RoundSliderOverlayShape(overlayRadius: overlayRadius),
      thumbColor: activeColor ?? primaryBlue,
      overlayColor: (activeColor ?? primaryBlue).withOpacity(0.12),
      valueIndicatorColor: activeColor ?? primaryBlue,
      tickMarkShape: const RoundSliderTickMarkShape(),
      activeTickMarkColor: borderColor,
      inactiveTickMarkColor: borderColor.withOpacity(0.5),
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
