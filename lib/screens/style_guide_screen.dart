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
                      _colorBox('Primary', mainGreen),
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
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
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

            // Table Design System Section
            _buildSection(
              title: 'Table Design System',
              description: 'Consistent table components for displaying structured data.',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Table
                  Text('Basic Table', style: h3),
                  const SizedBox(height: space16),
                  StandardTableContainer(
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
                          ],
                        ),
                        StandardTableRow(
                          onTap: () {},
                          children: [
                            TableColumn(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Amoxicillin 500mg', style: TableDesignSystem.tableRowTextStyle),
                                  Text('Antibiotic', style: TableDesignSystem.tableRowSubtitleStyle),
                                ],
                              ),
                            ),
                            TableColumn(
                              flex: 1,
                              child: Text('150', style: TableDesignSystem.tableRowTextStyle, textAlign: TextAlign.center),
                            ),
                            TableColumn(
                              flex: 1,
                              child: Text('\$25.00', style: TableDesignSystem.tableRowTextStyle, textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                        StandardTableRow(
                          onTap: () {},
                          children: [
                            TableColumn(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Vitamin B Complex', style: TableDesignSystem.tableRowTextStyle),
                                  Text('Supplement', style: TableDesignSystem.tableRowSubtitleStyle),
                                ],
                              ),
                            ),
                            TableColumn(
                              flex: 1,
                              child: Text('89', style: TableDesignSystem.tableRowTextStyle, textAlign: TextAlign.center),
                            ),
                            TableColumn(
                              flex: 1,
                              child: Text('\$18.50', style: TableDesignSystem.tableRowTextStyle, textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                        StandardTableRow(
                          onTap: () {},
                          children: [
                            TableColumn(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Ivermectin Injection', style: TableDesignSystem.tableRowTextStyle),
                                  Text('Parasiticide', style: TableDesignSystem.tableRowSubtitleStyle),
                                ],
                              ),
                            ),
                            TableColumn(
                              flex: 1,
                              child: Text('45', style: TableDesignSystem.tableRowTextStyle, textAlign: TextAlign.center),
                            ),
                            TableColumn(
                              flex: 1,
                              child: Text('\$32.75', style: TableDesignSystem.tableRowTextStyle, textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: space24),

                  // Table with Actions
                  Text('Table with Actions', style: h3),
                  const SizedBox(height: space16),
                  StandardTableContainer(
                    child: Column(
                      children: [
                        StandardTableHeader(
                          children: [
                            TableColumn(
                              flex: 3,
                              child: Text('Category Name', style: TableDesignSystem.tableHeaderTextStyle),
                            ),
                            TableColumn(
                              flex: 1,
                              child: Text('Products', style: TableDesignSystem.tableHeaderTextStyle),
                            ),
                            TableColumnFixed(
                              width: 100,
                              child: Text('Actions', style: TableDesignSystem.tableHeaderTextStyle),
                            ),
                          ],
                        ),
                        StandardTableRow(
                          children: [
                            TableColumn(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Antibiotics', style: TableDesignSystem.tableRowTextStyle),
                                  Text('General antibiotics for livestock', style: TableDesignSystem.tableRowSubtitleStyle),
                                ],
                              ),
                            ),
                            TableColumn(
                              flex: 1,
                              child: Text('24', style: TableDesignSystem.tableRowTextStyle, textAlign: TextAlign.center),
                            ),
                            TableColumnFixed(
                              width: 100,
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        StandardTableRow(
                          children: [
                            TableColumn(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Vitamins & Supplements', style: TableDesignSystem.tableRowTextStyle),
                                  Text('Nutritional supplements', style: TableDesignSystem.tableRowSubtitleStyle),
                                ],
                              ),
                            ),
                            TableColumn(
                              flex: 1,
                              child: Text('18', style: TableDesignSystem.tableRowTextStyle, textAlign: TextAlign.center),
                            ),
                            TableColumnFixed(
                              width: 100,
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: space24),

                  // Hierarchical Table
                  Text('Hierarchical Table (Tree Structure)', style: h3),
                  const SizedBox(height: space16),
                  StandardTableContainer(
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
                        // Root category
                        StandardTableRow(
                          onTap: () {},
                          children: [
                            TableColumn(
                              flex: 3,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: Center(
                                      child: AnimatedRotation(
                                        duration: const Duration(milliseconds: 200),
                                        turns: 0.25,
                                        child: Icon(
                                          Icons.keyboard_arrow_right,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Livestock Medications', style: TableDesignSystem.tableRowTextStyle),
                                        Text('All livestock medications', style: TableDesignSystem.tableRowSubtitleStyle),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TableColumnFixed(
                              width: 120,
                              child: Text('156', style: TableDesignSystem.tableRowTextStyle, textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                        // Child category (indented)
                        StandardTableRow(
                          onTap: () {},
                          children: [
                            TableColumn(
                              flex: 3,
                              child: Row(
                                children: [
                                  const SizedBox(width: 32), // Indentation
                                  SizedBox(
                                    width: 28,
                                    child: Center(
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Antibiotics', style: TableDesignSystem.tableRowTextStyle),
                                        Text('General antibiotics', style: TableDesignSystem.tableRowSubtitleStyle),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TableColumnFixed(
                              width: 120,
                              child: Text('24', style: TableDesignSystem.tableRowTextStyle, textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                        // Another child category
                        StandardTableRow(
                          onTap: () {},
                          children: [
                            TableColumn(
                              flex: 3,
                              child: Row(
                                children: [
                                  const SizedBox(width: 32), // Indentation
                                  SizedBox(
                                    width: 28,
                                    child: Center(
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Parasiticides', style: TableDesignSystem.tableRowTextStyle),
                                        Text('Anti-parasitic treatments', style: TableDesignSystem.tableRowSubtitleStyle),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TableColumnFixed(
                              width: 120,
                              child: Text('18', style: TableDesignSystem.tableRowTextStyle, textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: space24),

                  // Table States
                  Text('Table States', style: h3),
                  const SizedBox(height: space16),
                  Row(
                    children: [
                      Expanded(
                        child: StandardTableContainer(
                          child: TableDesignSystem.tableLoadingState,
                        ),
                      ),
                      const SizedBox(width: space16),
                      Expanded(
                        child: StandardTableContainer(
                          child: TableDesignSystem.tableEmptyState('No data available'),
                        ),
                      ),
                      const SizedBox(width: space16),
                      Expanded(
                        child: StandardTableContainer(
                          child: TableDesignSystem.tableErrorState('Failed to load data'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: space24),

                  // Table Usage Examples
                  Text('Usage Examples', style: h3),
                  const SizedBox(height: space16),
                  designSystemCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Basic Table Structure', style: h4),
                        const SizedBox(height: space8),
                        Text(
                          'Use StandardTableContainer, StandardTableHeader, and StandardTableRow for consistent table styling.',
                          style: body,
                        ),
                        const SizedBox(height: space16),
                        Text('Column Sizing', style: h4),
                        const SizedBox(height: space8),
                        Text(
                          '• Use TableColumn with flex for flexible width\n'
                          '• Use TableColumnFixed for fixed-width columns\n'
                          '• Common flex ratios: 3:1, 2:1, 1:1',
                          style: body,
                        ),
                        const SizedBox(height: space16),
                        Text('Interactive Features', style: h4),
                        const SizedBox(height: space8),
                        Text(
                          '• Add onTap to StandardTableRow for clickable rows\n'
                          '• Use Material + InkWell for proper touch feedback\n'
                          '• Support for hierarchical/tree structures',
                          style: body,
                        ),
                      ],
                    ),
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

            // Font Weight Test Section
            _buildSection(
              title: 'Font Weight Test',
              description: 'Testing different font weights to ensure they render correctly.',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Font Weight 100 (Thin)', style: getInterTextStyle(fontSize: 16, fontWeight: FontWeight.w100)),
                  Text('Font Weight 200 (Extra Light)', style: getInterTextStyle(fontSize: 16, fontWeight: FontWeight.w200)),
                  Text('Font Weight 300 (Light)', style: getInterTextStyle(fontSize: 16, fontWeight: FontWeight.w300)),
                  Text('Font Weight 400 (Regular/Normal)', style: getInterTextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
                  Text('Font Weight 500 (Medium)', style: getInterTextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Text('Font Weight 600 (Semi Bold)', style: getInterTextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text('Font Weight 700 (Bold)', style: getInterTextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text('Font Weight 800 (Extra Bold)', style: getInterTextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text('Font Weight 900 (Black)', style: getInterTextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: space24),
                  Text('Design System Styles:', style: h3),
                  const SizedBox(height: space16),
                  Row(
                    children: [
                      Expanded(
                        child: Text('bodyLarge (w400)', style: bodyLarge),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('w400', style: caption.copyWith(color: Colors.blue[700])),
                      ),
                    ],
                  ),
                  const SizedBox(height: space8),
                  Row(
                    children: [
                      Expanded(
                        child: Text('body (w400)', style: body),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('w400', style: caption.copyWith(color: Colors.blue[700])),
                      ),
                    ],
                  ),
                  const SizedBox(height: space8),
                  Row(
                    children: [
                      Expanded(
                        child: Text('bodySmall (w400)', style: bodySmall),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('w400', style: caption.copyWith(color: Colors.blue[700])),
                      ),
                    ],
                  ),
                  const SizedBox(height: space8),
                  Row(
                    children: [
                      Expanded(
                        child: Text('labelLarge (w500)', style: labelLarge),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('w500', style: caption.copyWith(color: Colors.green[700])),
                      ),
                    ],
                  ),
                  const SizedBox(height: space8),
                  Row(
                    children: [
                      Expanded(
                        child: Text('labelMedium (w500)', style: labelMedium),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('w500', style: caption.copyWith(color: Colors.green[700])),
                      ),
                    ],
                  ),
                  const SizedBox(height: space8),
                  Row(
                    children: [
                      Expanded(
                        child: Text('labelSmall (w500)', style: labelSmall),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('w500', style: caption.copyWith(color: Colors.green[700])),
                      ),
                    ],
                  ),
                  const SizedBox(height: space8),
                  Row(
                    children: [
                      Expanded(
                        child: Text('h1 (w700)', style: h1),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('w700', style: caption.copyWith(color: Colors.orange[700])),
                      ),
                    ],
                  ),
                  const SizedBox(height: space8),
                  Row(
                    children: [
                      Expanded(
                        child: Text('h2 (w700)', style: h2),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('w700', style: caption.copyWith(color: Colors.orange[700])),
                      ),
                    ],
                  ),
                  const SizedBox(height: space8),
                  Row(
                    children: [
                      Expanded(
                        child: Text('h3 (w600)', style: h3),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('w600', style: caption.copyWith(color: Colors.purple[700])),
                      ),
                    ],
                  ),
                  const SizedBox(height: space8),
                  Row(
                    children: [
                      Expanded(
                        child: Text('h4 (w600)', style: h4),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('w600', style: caption.copyWith(color: Colors.purple[700])),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Shopify Font Comparison Section
            _buildSection(
              title: 'Shopify Admin Font Comparison',
              description: 'Comparing our font with Shopify admin font styles.',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shopify Admin Font Stack:', style: h3),
                  const SizedBox(height: space16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('font-family: "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;', style: body.copyWith(fontFamily: 'monospace')),
                        const SizedBox(height: space8),
                        Text('Font weights: 400 (regular), 500 (medium), 600 (semibold), 700 (bold)', style: body.copyWith(fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                  const SizedBox(height: space24),
                  Text('Our Current Font (Inter):', style: h3),
                  const SizedBox(height: space16),
                  Text('Heading 1 - Product Management', style: getInterTextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  Text('Heading 2 - Inventory Overview', style: getInterTextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  Text('Heading 3 - Product Categories', style: getInterTextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  Text('Body Large - This is body text with 14px and regular weight', style: getInterTextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
                  Text('Body - Standard body text for descriptions', style: getInterTextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
                  Text('Label - Form labels and small text', style: getInterTextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text('Caption - Small helper text', style: getInterTextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary)),
                  const SizedBox(height: space24),
                  Text('Font Weight Comparison:', style: h3),
                  const SizedBox(height: space16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Regular (400)', style: getInterTextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('400', style: caption.copyWith(color: Colors.blue[700])),
                                ),
                              ],
                            ),
                            const SizedBox(height: space8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Medium (500)', style: getInterTextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('500', style: caption.copyWith(color: Colors.green[700])),
                                ),
                              ],
                            ),
                            const SizedBox(height: space8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Semibold (600)', style: getInterTextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('600', style: caption.copyWith(color: Colors.purple[700])),
                                ),
                              ],
                            ),
                            const SizedBox(height: space8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Bold (700)', style: getInterTextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('700', style: caption.copyWith(color: Colors.orange[700])),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: space24),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Shopify Admin', style: h4.copyWith(color: Colors.blue[700])),
                              const SizedBox(height: space8),
                              Text('Uses Inter font family', style: body),
                              Text('Variable font support', style: body),
                              Text('Optimized for screens', style: body),
                              Text('High x-height for readability', style: body),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: space24),
                  Text('Font Loading Test:', style: h3),
                  const SizedBox(height: space16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Google Fonts Inter Status:', style: h4.copyWith(color: Colors.green[700])),
                        const SizedBox(height: space8),
                        Text('✅ Using GoogleFonts.inter()', style: body),
                        Text('✅ Font family: Inter', style: body),
                        Text('✅ Variable font support', style: body),
                        Text('✅ Fallback fonts available', style: body),
                        Text('✅ Same as Shopify admin', style: body),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Font Rendering Test Section
            _buildSection(
              title: 'Font Rendering Test',
              description: 'Testing actual font rendering and comparison with Shopify admin.',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Real-world Text Examples:', style: h3),
                  const SizedBox(height: space16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Product Management Dashboard', style: h1),
                        const SizedBox(height: space16),
                        Text('Manage your inventory and track product performance', style: bodyLarge),
                        const SizedBox(height: space24),
                        Text('Product Categories', style: h3),
                        const SizedBox(height: space8),
                        Text('Organize your products into logical groups for better management', style: body),
                        const SizedBox(height: space16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total Products', style: labelLarge),
                                  Text('1,234', style: h2),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Low Stock Items', style: labelLarge),
                                  Text('23', style: h2.copyWith(color: warningOrange)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: space24),
                  Text('Font Weight Clarity Test:', style: h3),
                  const SizedBox(height: space16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Regular (400) - Should be clearly readable', style: getInterTextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('400', style: caption.copyWith(color: Colors.blue[700])),
                            ),
                          ],
                        ),
                        const SizedBox(height: space8),
                        Row(
                          children: [
                            Expanded(
                              child: Text('Medium (500) - Slightly bolder for emphasis', style: getInterTextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('500', style: caption.copyWith(color: Colors.green[700])),
                            ),
                          ],
                        ),
                        const SizedBox(height: space8),
                        Row(
                          children: [
                            Expanded(
                              child: Text('Semibold (600) - Good for headings', style: getInterTextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('600', style: caption.copyWith(color: Colors.purple[700])),
                            ),
                          ],
                        ),
                        const SizedBox(height: space8),
                        Row(
                          children: [
                            Expanded(
                              child: Text('Bold (700) - Strong emphasis', style: getInterTextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('700', style: caption.copyWith(color: Colors.orange[700])),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: space24),
                  Text('Shopify Admin Comparison:', style: h3),
                  const SizedBox(height: space16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Shopify Admin uses:', style: h4),
                        const SizedBox(height: space8),
                        Text('• Inter font family (same as us)', style: body),
                        Text('• Font weights: 400, 500, 600, 700', style: body),
                        Text('• Variable font for smooth scaling', style: body),
                        Text('• High x-height for better readability', style: body),
                        Text('• Optimized for web interfaces', style: body),
                        const SizedBox(height: space16),
                        Text('Our implementation:', style: h4),
                        const SizedBox(height: space8),
                        Text('✅ Inter font via Google Fonts', style: body),
                        Text('✅ Same font weights as Shopify', style: body),
                        Text('✅ Variable font support', style: body),
                        Text('✅ Consistent with Shopify admin', style: body),
                      ],
                    ),
                  ),
                ],
              ),
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
              color: mainGreen.withAlpha(10),
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
        Text('Danh mục', style: labelLarge),
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