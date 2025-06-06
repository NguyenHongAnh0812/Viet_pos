import 'package:flutter/material.dart';
import '../widgets/common/design_system.dart';

class StyleGuideScreen extends StatelessWidget {
  const StyleGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        title: const Text('Style Guide'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colors
            Text('Colors', style: h2),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _colorBox('Primary Blue', primaryBlue),
                _colorBox('Secondary Green', secondaryGreen),
                _colorBox('Warning Orange', warningOrange),
                _colorBox('Destructive Red', destructiveRed),
                _colorBox('Border', borderColor),
                _colorBox('App Background', appBackground),
                _colorBox('Card Background', cardBackground),
                _colorBox('Text Primary', textPrimary),
                _colorBox('Text Secondary', textSecondary),
                _colorBox('Text Third', textThird),
                _colorBox('Muted Background', mutedBackground),
                _colorBox('Accent Background', accentBackground),
                _colorBox('Accent Foreground', accentForeground),
              ],
            ),
            const SizedBox(height: 32),
            // Typography
            Text('Typography', style: h2),
            const SizedBox(height: 12),
            Text('h1 - 28 bold', style: h1),
            Text('h2 - 22 bold', style: h2),
            Text('h3 - 18 w600', style: h3),
            Text('h4 - 18 w600', style: h4),
            Text('body - 14', style: body),
            Text('heading - 16', style: heading),
            Text('caption - 12', style: caption),
            const SizedBox(height: 12),
            Text('h1Mobile', style: h1Mobile),
            Text('h2Mobile', style: h2Mobile),
            Text('h3Mobile', style: h3Mobile),
            Text('bodyMobile', style: bodyMobile),
            Text('smallMobile', style: smallMobile),
            Text('captionMobile', style: captionMobile),
            const SizedBox(height: 32),
            // Buttons
            Text('Buttons', style: h2),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: primaryButtonStyle,
                  child: const Text('Primary'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {},
                  style: secondaryButtonStyle,
                  child: const Text('Secondary'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {},
                  style: outlineButtonStyle,
                  child: const Text('Outline'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: destructiveButtonStyle,
                  child: const Text('Destructive'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {},
                  style: ghostButtonStyle,
                  child: const Text('Ghost'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Card
            Text('Card', style: h2),
            const SizedBox(height: 12),
            designSystemCard(
              child: Text('This is a card', style: body),
            ),
            const SizedBox(height: 32),
            // Badge
            Text('Badge', style: h2),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: const [
                DesignSystemBadge(text: 'Default'),
                DesignSystemBadge(text: 'Secondary', variant: BadgeVariant.secondary),
                DesignSystemBadge(text: 'Destructive', variant: BadgeVariant.destructive),
                DesignSystemBadge(text: 'Outline', variant: BadgeVariant.outline),
              ],
            ),
            const SizedBox(height: 32),
            // Input
            Text('Input', style: h2),
            const SizedBox(height: 12),
            TextField(
              decoration: designSystemInputDecoration(label: 'Label', hint: 'Hint'),
            ),
            const SizedBox(height: 32),
            // Alert
            Text('Alert', style: h2),
            const SizedBox(height: 12),
            const DesignSystemAlert(title: 'Info Alert', message: 'This is an info alert.'),
            const SizedBox(height: 8),
            const DesignSystemAlert(title: 'Warning Alert', message: 'This is a warning alert.', variant: AlertVariant.warning),
            const SizedBox(height: 8),
            const DesignSystemAlert(title: 'Error Alert', message: 'This is an error alert.', variant: AlertVariant.error),
            const SizedBox(height: 8),
            const DesignSystemAlert(title: 'Success Alert', message: 'This is a success alert.', variant: AlertVariant.success),
            const SizedBox(height: 32),
            // Separator
            Text('Separator', style: h2),
            const SizedBox(height: 12),
            const DesignSystemSeparator(),
            const SizedBox(height: 32),
            // Skeleton
            Text('Skeleton', style: h2),
            const SizedBox(height: 12),
            const DesignSystemSkeleton(height: 20, width: 200),
            const SizedBox(height: 32),
            // Form Section
            Text('Form Section', style: h2),
            const SizedBox(height: 12),
            const DesignSystemFormSection(
              title: 'Section Title',
              description: 'Section description',
              children: [
                Text('Form content here'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorBox(String name, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
} 