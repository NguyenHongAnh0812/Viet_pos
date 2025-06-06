import 'package:flutter/material.dart';

// ===================== COLORS =====================
const Color primaryBlue = Color(0xFF3A6FF8); // --primary
const Color secondaryGreen = Color(0xFF67C687); // --secondary
const Color warningOrange = Color(0xFFFFB547); // --warning
const Color destructiveRed = Color(0xFFFF5A5F); // --destructive
const Color borderColor = Color(0xFFD1D5DB); // --border

const Color appBackground = Color(0xFFF7F9FC); // --background
const Color cardBackground = Color(0xFFFFFFFF); // --card
const Color textPrimary = Color(0xFF1E1E1E); // --foreground
const Color textSecondary = Color(0xFF6B7280); // --muted-foreground
const Color textThird = Color(0xFF71717A); // --title
const Color mutedBackground = Color(0xFFE9EDF5); // hsl(210 20% 96%)
const Color accentBackground = Color(0xFFE9EDF5); // hsl(210 20% 96%)
const Color accentForeground = Color(0xFF1E1E1E); // hsl(240 6% 10%)

// ===================== SPACING =====================
const double space2 = 2.0;
const double space4 = 4.0;
const double space8 = 8.0;
const double space10 = 10.0;
const double space12 = 12.0;
const double space16 = 16.0;
const double space20 = 20.0;
const double space24 = 24.0;
const double space32 = 32.0;
const double space48 = 48.0;
const double space64 = 64.0;

// ===================== RESPONSIVE TYPOGRAPHY =====================
const TextStyle h1Mobile = TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: fontFamily);
const TextStyle h2Mobile = TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: fontFamily);
const TextStyle h3Mobile = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: fontFamily);
const TextStyle bodyMobile = TextStyle(fontSize: 14, fontWeight: FontWeight.normal, fontFamily: fontFamily);
const TextStyle smallMobile = TextStyle(fontSize: 12, fontWeight: FontWeight.normal, fontFamily: fontFamily);
const TextStyle captionMobile = TextStyle(fontSize: 11, fontWeight: FontWeight.normal, fontFamily: fontFamily);
const double spaceMobile = 8.0;

TextStyle responsiveTextStyle(BuildContext context, TextStyle desktop, TextStyle mobile) {
  return MediaQuery.of(context).size.width < 1024 ? mobile : desktop;
}

// ===================== TYPOGRAPHY =====================
const String fontFamily = 'Inter';
const TextStyle h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: fontFamily);
const TextStyle h2 = TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: fontFamily);
const TextStyle h3 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: fontFamily);
const TextStyle h4 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: fontFamily);
const TextStyle body = TextStyle(fontSize: 14, fontWeight: FontWeight.normal, fontFamily: fontFamily);
const TextStyle heading = TextStyle(fontSize: 16, fontWeight: FontWeight.normal, fontFamily: fontFamily);
const TextStyle caption = TextStyle(fontSize: 12, fontWeight: FontWeight.normal, fontFamily: fontFamily);
const TextStyle small = TextStyle(fontSize: 14, fontWeight: FontWeight.normal, fontFamily: fontFamily);

// ===================== BUTTON STYLES =====================
ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: primaryBlue,
  foregroundColor: Colors.white,
  minimumSize: const Size(64, 40),
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  textStyle: body.copyWith(fontWeight: FontWeight.w600),
  elevation: 0,
);
ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
  foregroundColor: secondaryGreen,
  backgroundColor: Colors.white,
  side: const BorderSide(color: borderColor, width: 1.5),
  minimumSize: const Size(64, 40),
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  textStyle: body.copyWith(fontWeight: FontWeight.w600),
);
ButtonStyle outlineButtonStyle = OutlinedButton.styleFrom(
  foregroundColor: textPrimary,
  backgroundColor: Colors.white,
  side: const BorderSide(color: borderColor, width: 1.2),
  minimumSize: const Size(64, 40),
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  textStyle: body.copyWith(fontWeight: FontWeight.w600),
);
ButtonStyle destructiveButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: destructiveRed,
  foregroundColor: Colors.white,
  minimumSize: const Size(64, 40),
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  textStyle: body.copyWith(fontWeight: FontWeight.w600),
  elevation: 0,
);
ButtonStyle ghostButtonStyle = TextButton.styleFrom(
  foregroundColor: textPrimary,
  backgroundColor: Colors.transparent,
  minimumSize: const Size(40, 40),
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  textStyle: body.copyWith(fontWeight: FontWeight.w600),
);

// ===================== CARD =====================
Card designSystemCard({required Widget child, EdgeInsetsGeometry? padding}) => Card(
  elevation: 1,
  color: cardBackground,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: const BorderSide(color: borderColor, width: 1),
  ),
  child: Padding(
    padding: padding ?? const EdgeInsets.all(space16),
    child: child,
  ),
);

// ===================== INPUT =====================
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
    borderSide: const BorderSide(color: borderColor),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: primaryBlue, width: 2),
  ),
);

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
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
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

enum BadgeVariant { defaultVariant, secondary, destructive, outline }

// ===================== DIALOG =====================
Future<T?> showDesignSystemDialog<T>({
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          if (icon != null)
            Icon(icon, color: iconColor ?? destructiveRed, size: 28),
          if (icon != null) const SizedBox(width: 8),
          Expanded(child: Text(title, style: h3)),
        ],
      ),
      content: content,
      actions: actions,
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );
}

// ===================== DROPDOWN MENU =====================
class DesignSystemDropdownMenu<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  const DesignSystemDropdownMenu({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.borderRadius = 8,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: designSystemInputDecoration(hint: hint),
      borderRadius: BorderRadius.circular(borderRadius),
      style: body,
      padding: padding,
    );
  }
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(displayIcon, color: fg, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: body.copyWith(fontWeight: FontWeight.bold, color: fg)),
                if (message != null) ...[
                  const SizedBox(height: 2),
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
      color: color ?? Colors.grey.shade200,
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
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
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
      padding: padding ?? const EdgeInsets.symmetric(vertical: space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: h2),
            if (description != null) ...[
              const SizedBox(height: 4),
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
    this.gap = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: small.copyWith(fontWeight: FontWeight.w600)),
            if (required) ...[
              const SizedBox(width: 2),
              const Text('*', style: TextStyle(color: destructiveRed, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        SizedBox(height: gap),
        input,
        if (helperText != null && (errorText == null || errorText!.isEmpty)) ...[
          const SizedBox(height: 4),
          Text(helperText!, style: caption.copyWith(color: textSecondary)),
        ],
        if (errorText != null && errorText!.isNotEmpty) ...[
          const SizedBox(height: 4),
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

// ===================== UTILS =====================
List<Widget> _withGap(List<Widget> children, double gap) {
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