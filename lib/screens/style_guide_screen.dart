import 'package:flutter/material.dart';
import '../widgets/common/design_system.dart';

class StyleGuideScreen extends StatelessWidget {
  const StyleGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        title: const Text('VET-POS Design System'),
        backgroundColor: cardBackground,
        foregroundColor: textPrimary,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introduction
            Text('Introduction', style: h1),
            const SizedBox(height: space16),
            Text(
              'This style guide provides a comprehensive overview of the VET-POS design system, including colors, typography, components, and spacing guidelines.',
              style: bodyLarge.copyWith(color: textSecondary),
            ),
            const SizedBox(height: space32),

            // Colors Section
            _buildSection(
              title: 'Colors',
              description: 'Our color palette is designed to be accessible and consistent across the application.',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Brand Colors', style: h3),
                  const SizedBox(height: space16),
                  Wrap(
                    spacing: space16,
                    runSpacing: space16,
                    children: [
                      _colorBox('Primary', primaryBlue),
                      _colorBox('Secondary', secondaryGreen),
                      _colorBox('Warning', warningOrange),
                      _colorBox('Destructive', destructiveRed),
                    ],
                  ),
                  const SizedBox(height: space24),
                  Text('Neutral Colors', style: h3),
                  const SizedBox(height: space16),
                  Wrap(
                    spacing: space16,
                    runSpacing: space16,
                    children: [
                      _colorBox('Background', appBackground),
                      _colorBox('Card', cardBackground),
                      _colorBox('Border', borderColor),
                      _colorBox('Muted', mutedBackground),
                    ],
                  ),
                  const SizedBox(height: space24),
                  Text('Text Colors', style: h3),
                  const SizedBox(height: space16),
                  Wrap(
                    spacing: space16,
                    runSpacing: space16,
                    children: [
                      _colorBox('Primary', textPrimary),
                      _colorBox('Secondary', textSecondary),
                      _colorBox('Muted', textMuted),
                      _colorBox('Third', textThird),
                    ],
                  ),
                ],
              ),
            ),

            // Typography Section
            _buildSection(
              title: 'Typography',
              description: 'Our typography system is built for readability and hierarchy.',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Headings', style: h3),
                  const SizedBox(height: space16),
                  Text('Heading 1', style: h1),
                  Text('Heading 2', style: h2),
                  Text('Heading 3', style: h3),
                  Text('Heading 4', style: h4),
                  const SizedBox(height: space24),
                  Text('Body Text', style: h3),
                  const SizedBox(height: space16),
                  Text('Body Large - 16px', style: bodyLarge),
                  Text('Body - 14px', style: body),
                  Text('Body Small - 12px', style: bodySmall),
                  const SizedBox(height: space24),
                  Text('Labels', style: h3),
                  const SizedBox(height: space16),
                  Text('Label Large - 14px', style: labelLarge),
                  Text('Label Medium - 12px', style: labelMedium),
                  Text('Label Small - 11px', style: labelSmall),
                ],
              ),
            ),

            // Components Section
            _buildSection(
              title: 'Components',
              description: 'Reusable components that follow our design system.',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Buttons
                  Text('Buttons', style: h3),
                  const SizedBox(height: space16),
                  Wrap(
                    spacing: space12,
                    runSpacing: space12,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: primaryButtonStyle,
                        child: const Text('Primary'),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        style: secondaryButtonStyle,
                        child: const Text('Secondary'),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        style: outlineButtonStyle,
                        child: const Text('Outline'),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: destructiveButtonStyle,
                        child: const Text('Destructive'),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: ghostButtonStyle,
                        child: const Text('Ghost'),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        style: ghostBorderButtonStyle,
                        child: const Text('Ghost Border'),
                      ),
                    ],
                  ),
                  const SizedBox(height: space16),
                  Text('Button Sizes', style: h4),
                  const SizedBox(height: space12),
                  Wrap(
                    spacing: space12,
                    runSpacing: space12,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: smallButtonStyle,
                        child: const Text('Small'),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: primaryButtonStyle,
                        child: const Text('Medium'),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: largeButtonStyle,
                        child: const Text('Large'),
                      ),
                    ],
                  ),
                  const SizedBox(height: space16),
                  Text('Icon Buttons', style: h4),
                  const SizedBox(height: space12),
                  Wrap(
                    spacing: space12,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                        style: iconButtonStyle,
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.edit),
                        style: iconButtonStyle,
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.delete),
                        style: iconButtonStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: space24),

                  // Form Elements
                  Text('Form Elements', style: h3),
                  const SizedBox(height: space16),
                  designSystemFormCard(
                    title: 'Form Example',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DesignSystemFormField(
                          label: 'Default Input',
                          input: TextField(
                            decoration: designSystemInputDecoration(
                              hint: 'Enter text here',
                              fillColor: mutedBackground,
                              filled: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: space16),
                        DesignSystemFormField(
                          label: 'With Error',
                          input: TextField(
                            decoration: designSystemInputDecoration(
                              hint: 'Enter text here',
                              errorText: 'This field is required',
                            ),
                          ),
                        ),
                        const SizedBox(height: space16),
                        DesignSystemFormField(
                          label: 'Search Input',
                          input: TextField(
                            decoration: searchInputDecoration(
                              hint: 'Search...',
                            ),
                          ),
                        ),
                        const SizedBox(height: space16),
                        DesignSystemFormField(
                          label: 'Dropdown',
                          input: _StyleGuideShopifyDropdownDemo(),
                        ),
                        const SizedBox(height: space16),
                        DesignSystemFormField(
                          label: 'Custom Select',
                          input: DesignSystemSelect<String>(
                            value: null,
                            options: const ['Option 1', 'Option 2', 'Option 3'],
                            getLabel: (option) => option,
                            onChanged: (value) {},
                            placeholder: 'Choose option',
                          ),
                        ),
                        const SizedBox(height: space16),
                        // Checkbox (interactive)
                        _StyleGuideCheckboxDemo(),
                        const SizedBox(height: space16),
                        // Radio group (interactive)
                        _StyleGuideRadioGroupDemo(),
                      ],
                    ),
                  ),
                  const SizedBox(height: space24),

                  // Cards
                  Text('Cards', style: h3),
                  const SizedBox(height: space16),
                  designSystemCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Card Title', style: h4),
                        const SizedBox(height: space8),
                        Text('This is a card component with consistent styling.', style: body),
                      ],
                    ),
                  ),
                  const SizedBox(height: space24),

                  // Badges
                  Text('Badges', style: h3),
                  const SizedBox(height: space16),
                  Wrap(
                    spacing: space12,
                    children: const [
                      DesignSystemBadge(text: 'Default'),
                      DesignSystemBadge(text: 'Secondary', variant: BadgeVariant.secondary),
                      DesignSystemBadge(text: 'Destructive', variant: BadgeVariant.destructive),
                      DesignSystemBadge(text: 'Warning', variant: BadgeVariant.warning),
                      DesignSystemBadge(text: 'Outline', variant: BadgeVariant.outline),
                    ],
                  ),
                  const SizedBox(height: space24),

                  // Alerts
                  Text('Alerts', style: h3),
                  const SizedBox(height: space16),
                  const DesignSystemAlert(
                    title: 'Information',
                    message: 'This is an informational alert message.',
                  ),
                  const SizedBox(height: space8),
                  const DesignSystemAlert(
                    title: 'Warning',
                    message: 'This is a warning alert message.',
                    variant: AlertVariant.warning,
                  ),
                  const SizedBox(height: space8),
                  const DesignSystemAlert(
                    title: 'Error',
                    message: 'This is an error alert message.',
                    variant: AlertVariant.error,
                  ),
                  const SizedBox(height: space8),
                  const DesignSystemAlert(
                    title: 'Success',
                    message: 'This is a success alert message.',
                    variant: AlertVariant.success,
                  ),
                  const SizedBox(height: space24),

                  // Modals
                  Text('Modals', style: h3),
                  const SizedBox(height: space16),
                  Wrap(
                    spacing: space12,
                    children: [
                      ElevatedButton(
                        onPressed: () => _showExampleDialog(context),
                        style: primaryButtonStyle,
                        child: const Text('Show Dialog'),
                      ),
                      ElevatedButton(
                        onPressed: () => _showExampleBottomSheet(context),
                        style: primaryButtonStyle,
                        child: const Text('Show Bottom Sheet'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Spacing Section
            _buildSection(
              title: 'Spacing',
              description: 'Consistent spacing system for layout and components.',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Spacing Scale', style: h3),
                  const SizedBox(height: space16),
                  _spacingBox('space2', space2),
                  _spacingBox('space4', space4),
                  _spacingBox('space8', space8),
                  _spacingBox('space16', space16),
                  _spacingBox('space24', space24),
                  _spacingBox('space32', space32),
                  _spacingBox('space48', space48),
                  _spacingBox('space64', space64),
                ],
              ),
            ),

            // Dimensions Section
            _buildSection(
              title: 'Dimensions',
              description: 'Standard dimensions for components and layouts.',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Button Dimensions', style: h3),
                  const SizedBox(height: space16),
                  _dimensionBox('Button Min Width', buttonMinWidth),
                  _dimensionBox('Button Icon Width', buttonIconWidth),
                  _dimensionBox('Button Height Small', buttonHeightSmall),
                  _dimensionBox('Button Height Medium', buttonHeightMedium),
                  _dimensionBox('Button Height Large', buttonHeightLarge),
                  const SizedBox(height: space24),
                  Text('Modal Dimensions', style: h3),
                  const SizedBox(height: space16),
                  _dimensionBox('Modal Max Width', modalMaxWidth),
                  _dimensionBox('Modal Max Width Large', modalMaxWidthLarge),
                  _dimensionBox('Modal Max Width Small', modalMaxWidthSmall),
                  _dimensionBox('Modal Min Height', modalMinHeight),
                  _dimensionBox('Modal Header Height', modalHeaderHeight),
                  _dimensionBox('Modal Footer Height', modalFooterHeight),
                ],
              ),
            ),

            // Popup/Snackbar Section
            _buildSection(
              title: 'Popup Notification',
              description: 'A notification popup appears at the bottom right with animation when an action is successful.',
              content: Builder(
                builder: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        OverlayEntry? entry;
                        entry = OverlayEntry(
                          builder: (_) => DesignSystemSnackbar(
                            message: 'Đã lưu thông tin sản phẩm thành công',
                            icon: Icons.check_circle,
                            onDismissed: () => entry?.remove(),
                          ),
                        );
                        Overlay.of(context).insert(entry);
                      },
                      child: const Text('Show Popup'),
                    ),
                    const SizedBox(height: space16),
                    Text('Click the button to show a popup notification at the bottom right.', style: caption),
                  ],
                ),
              ),
            ),

            // Shopify Dropdown Section
            _buildSection(
              title: 'Shopify-style Dropdown',
              description: 'A dropdown menu styled like Shopify admin, with full-width, shadow, border, scroll, and hover.',
              content: _ShopifyDropdownDemo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: h2),
        const SizedBox(height: space8),
        Text(description, style: bodyLarge.copyWith(color: textSecondary)),
        const SizedBox(height: space24),
        content,
        const SizedBox(height: space48),
      ],
    );
  }

  Widget _colorBox(String name, Color color) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(borderRadiusMedium),
            border: Border.all(color: borderColor),
          ),
        ),
        const SizedBox(height: space8),
        Text(name, style: labelMedium),
        const SizedBox(height: space4),
        Text(
          '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
          style: caption.copyWith(color: textSecondary),
        ),
      ],
    );
  }

  Widget _spacingBox(String name, double size) {
    return Padding(
      padding: const EdgeInsets.only(bottom: space16),
      child: Row(
        children: [
          Container(
            width: size,
            height: 24,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(borderRadiusSmall),
            ),
          ),
          const SizedBox(width: space16),
          Text(name, style: body),
          const SizedBox(width: space8),
          Text('${size.toInt()}px', style: caption.copyWith(color: textSecondary)),
        ],
      ),
    );
  }

  Widget _dimensionBox(String name, double size) {
    return Padding(
      padding: const EdgeInsets.only(bottom: space16),
      child: Row(
        children: [
          Text(name, style: body),
          const SizedBox(width: space8),
          Text('${size.toInt()}px', style: caption.copyWith(color: textSecondary)),
        ],
      ),
    );
  }

  void _showExampleDialog(BuildContext context) {
    showDesignSystemDialog(
      context: context,
      title: 'Example Dialog',
      content: const Text('This is an example dialog using our design system.'),
      icon: Icons.info_outline,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: ghostBorderButtonStyle,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: primaryButtonStyle,
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  void _showExampleBottomSheet(BuildContext context) {
    showDesignSystemBottomSheet(
      context: context,
      height: 300,
      child: Padding(
        padding: const EdgeInsets.all(space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Example Bottom Sheet', style: h3),
            const SizedBox(height: space16),
            Text(
              'This is an example bottom sheet using our design system.',
              style: body,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopifyDropdownDemo extends StatefulWidget {
  @override
  State<_ShopifyDropdownDemo> createState() => _ShopifyDropdownDemoState();
}

class _ShopifyDropdownDemoState extends State<_ShopifyDropdownDemo> {
  String? selectedCategory;
  final categories = const [
    'General Antibiotics',
    'Vitamins & Supplements',
    'Pet Care',
    'Livestock Injections',
    'Veterinary Anesthetics',
    'Livestock Parasiticides',
    'Poultry Medications',
    'Category 8',
    'Category 9',
    'Category 10',
    'Category 11',
    'Category 12',
  ];
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Danh mục', style: labelLarge),
        const SizedBox(height: space8),
        SizedBox(
          width: 340,
          child: ShopifyDropdown<String>(
            items: categories,
            value: selectedCategory,
            getLabel: (c) => c,
            onChanged: (v) => setState(() => selectedCategory = v),
            hint: 'Chọn danh mục',
          ),
        ),
        const SizedBox(height: space16),
        Text('Selected: ${selectedCategory ?? "(none)"}', style: caption),
      ],
    );
  }
}

class _StyleGuideShopifyDropdownDemo extends StatefulWidget {
  @override
  State<_StyleGuideShopifyDropdownDemo> createState() => _StyleGuideShopifyDropdownDemoState();
}

class _StyleGuideShopifyDropdownDemoState extends State<_StyleGuideShopifyDropdownDemo> {
  String? selectedCategory;
  final categories = const [
    'General Antibiotics',
    'Vitamins & Supplements',
    'Pet Care',
    'Livestock Injections',
    'Veterinary Anesthetics',
    'Livestock Parasiticides',
    'Poultry Medications',
  ];
  @override
  Widget build(BuildContext context) {
    return ShopifyDropdown<String>(
      items: categories,
      value: selectedCategory,
      getLabel: (c) => c,
      onChanged: (v) => setState(() => selectedCategory = v),
      hint: 'Select an option',
    );
  }
}

class _StyleGuideCheckboxDemo extends StatefulWidget {
  @override
  State<_StyleGuideCheckboxDemo> createState() => _StyleGuideCheckboxDemoState();
}

class _StyleGuideCheckboxDemoState extends State<_StyleGuideCheckboxDemo> {
  bool isChecked = true;
  @override
  Widget build(BuildContext context) {
    return DesignSystemCheckbox(
      value: isChecked,
      onChanged: (value) => setState(() => isChecked = value ?? false),
      label: 'I agree to terms and conditions',
    );
  }
}

class _StyleGuideRadioGroupDemo extends StatefulWidget {
  @override
  State<_StyleGuideRadioGroupDemo> createState() => _StyleGuideRadioGroupDemoState();
}

class _StyleGuideRadioGroupDemoState extends State<_StyleGuideRadioGroupDemo> {
  String selectedRadio = 'Option 1';
  final options = const ['Option 1', 'Option 2', 'Option 3'];
  @override
  Widget build(BuildContext context) {
    return DesignSystemRadioGroup<String>(
      options: options,
      value: selectedRadio,
      getLabel: (option) => option,
      onChanged: (value) => setState(() => selectedRadio = value ?? options[0]),
      direction: Axis.vertical,
    );
  }
} 