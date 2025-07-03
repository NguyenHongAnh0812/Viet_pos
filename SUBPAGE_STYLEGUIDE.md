# Subpage Styleguide - VET-POS Flutter App

## Tổng quan

Styleguide này định nghĩa các quy tắc và best practices để tạo subpage trong MainLayout của ứng dụng VET-POS. Mục tiêu là đảm bảo tính nhất quán trong UI/UX và dễ dàng maintain code.

## Các nguyên tắc cơ bản

### 1. Kiến trúc Subpage
- **Không sử dụng Scaffold**: Thay vào đó sử dụng Container
- **Tích hợp vào MainLayout**: Sử dụng MainLayout navigation thay vì Navigator.push
- **Responsive design**: Hỗ trợ cả desktop và mobile
- **Consistent styling**: Sử dụng design system đã định nghĩa

### 2. Cấu trúc Layout

```
Container (appBackground)
├── Header Section (white background, border bottom)
│   ├── Back Button
│   ├── Title (24px, FontWeight.w600)
│   └── Actions (Cancel, Save, etc.)
└── Main Content (Expanded)
    └── Row (2 columns layout)
        ├── Left Column (flex: 11)
        │   └── SingleChildScrollView (padding: 24)
        │       └── Content Sections
        ├── Divider (1px width, borderColor)
        └── Right Column (flex: 9)
            └── Container (white background)
                └── Side Content
```

## Quy tắc bắt buộc

### 1. Structure Rules
- ✅ Sử dụng `Container` thay vì `Scaffold`
- ✅ Header section với `padding: EdgeInsets.all(24)`
- ✅ Main content với `Expanded` widget
- ❌ Không sử dụng `AppBar`

### 2. Header Section Rules
- ✅ Background: `Colors.white`
- ✅ Border bottom: `borderColor`
- ✅ Layout: Row với IconButton (back), Expanded (title), Actions
- ✅ Title: `fontSize: 24`, `fontWeight: FontWeight.w600`

### 3. Main Content Rules
- ✅ Sử dụng `Row` cho layout 2 cột (nếu cần)
- ✅ Left column: `flex: 11`, `SingleChildScrollView` với `padding: 24`
- ✅ Right column: `flex: 9`, `Container` với background white
- ✅ Divider: `Container` width 1, color `borderColor`

### 4. Navigation Rules
- ✅ Sử dụng MainLayout navigation thay vì `Navigator.push`
- ✅ Thêm `MainPage` enum mới cho subpage
- ✅ Thêm biến state để lưu trữ data cần thiết
- ✅ Thêm method để mở subpage
- ✅ Cập nhật `_buildMainContent()` case

## Template Code

### Basic Subpage Template

```dart
import 'package:flutter/material.dart';
import '../widgets/common/design_system.dart';
import '../widgets/main_layout.dart';

class ExampleSubpage extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(MainPage)? onNavigate;
  final ExampleData? data;
  
  const ExampleSubpage({
    super.key, 
    this.onBack, 
    this.onNavigate, 
    this.data
  });

  @override
  State<ExampleSubpage> createState() => _ExampleSubpageState();
}

class _ExampleSubpageState extends State<ExampleSubpage> {
  // Controllers
  final _nameController = TextEditingController();
  
  // State variables
  bool isSaving = false;
  String? _nameError;
  
  @override
  void initState() {
    super.initState();
    // Initialize data
    if (widget.data != null) {
      _nameController.text = widget.data!.name;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  void _validateName() {
    final name = _nameController.text.trim();
    setState(() {
      if (name.isEmpty) {
        _nameError = 'Tên là bắt buộc';
      } else {
        _nameError = null;
      }
    });
  }
  
  Future<void> _saveData() async {
    _validateName();
    if (_nameError != null) return;
    
    setState(() => isSaving = true);
    try {
      // Save logic here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lưu thành công!')),
      );
      if (widget.onBack != null) widget.onBack!();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: appBackground,
      child: Column(
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: widget.onBack ?? () => Navigator.pop(context),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Example Subpage',
                    style: TextStyle(
                      color: Colors.black87, 
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onBack ?? () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isSaving || _nameError != null ? null : _saveData,
                  style: primaryButtonStyle,
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Lưu'),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column
                Expanded(
                  flex: 11,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Content sections
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thông tin cơ bản',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tên',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _nameController,
                                    decoration: designSystemInputDecoration(
                                      hint: 'Nhập tên',
                                      errorText: _nameError,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Right column
                Container(
                  width: 1,
                  height: double.infinity,
                  color: borderColor,
                ),
                Expanded(
                  flex: 9,
                  child: Container(
                    height: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.only(top: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thông tin bổ sung',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Nội dung bổ sung sẽ hiển thị ở đây.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### MainLayout Integration

```dart
// 1. Add to MainPage enum
enum MainPage { 
  // ... existing pages
  exampleSubpage 
}

// 2. Add state variable
ExampleData? _selectedExampleData;

// 3. Add method to open subpage
void _openExampleSubpage(ExampleData data) {
  setState(() {
    _previousPage = _currentPage;
    _currentPage = MainPage.exampleSubpage;
    _selectedExampleData = data;
  });
}

// 4. Add case in _buildMainContent()
case MainPage.exampleSubpage:
  if (_selectedExampleData == null) return const SizedBox();
  return ExampleSubpage(
    data: _selectedExampleData!,
    onBack: () => onSidebarTap(MainPage.previousPage),
  );

// 5. Reset state in onSidebarTap()
if (page != MainPage.exampleSubpage) {
  _selectedExampleData = null;
}
```

### Sidebar Integration (if needed)

```dart
_SidebarItem(
  icon: Icon(Icons.example, size: 16),
  label: 'Example Subpage',
  selected: widget.currentPage == MainPage.exampleSubpage,
  isOpen: widget.isOpen,
  onTap: () => widget.onItemTap(MainPage.exampleSubpage),
),
```

## Design System Components

### Input Fields
```dart
TextField(
  controller: _controller,
  decoration: designSystemInputDecoration(
    hint: 'Placeholder text',
    errorText: _errorText,
  ),
)
```

### Buttons
```dart
// Primary button
ElevatedButton(
  onPressed: _onPressed,
  style: primaryButtonStyle,
  child: const Text('Primary Action'),
)

// Secondary button
OutlinedButton(
  onPressed: _onPressed,
  style: secondaryButtonStyle,
  child: const Text('Secondary Action'),
)
```

### Dropdowns
```dart
ShopifyDropdown<String>(
  items: ['Option 1', 'Option 2'],
  value: _selectedValue,
  getLabel: (value) => value,
  onChanged: (value) => setState(() => _selectedValue = value),
  hint: 'Chọn tùy chọn',
)
```

### Search Fields
```dart
TextField(
  controller: _searchController,
  decoration: searchInputDecoration(
    hint: 'Tìm kiếm...',
  ),
  onChanged: (value) => setState(() => _searchText = value),
)
```

## Best Practices

### 1. Code Organization
- ✅ Tách logic phức tạp thành methods riêng
- ✅ Sử dụng meaningful variable names
- ✅ Thêm comments cho logic phức tạp
- ✅ Dispose controllers trong dispose()

### 2. State Management
- ✅ Load data trong initState()
- ✅ Use setState() cho UI updates
- ✅ StreamBuilder cho real-time data
- ✅ Handle loading states

### 3. Error Handling
- ✅ Hiển thị error messages trong SnackBar
- ✅ Validation với errorText trong input decoration
- ✅ Loading states với CircularProgressIndicator
- ✅ Handle edge cases (null data, loading states)

### 4. Performance
- ✅ Sử dụng const constructor khi có thể
- ✅ Tối ưu rebuild với setState()
- ✅ Sử dụng ListView.builder cho danh sách dài
- ✅ Lazy loading cho data lớn

## Common Pitfalls to Avoid

### ❌ Don't Do This
```dart
// Wrong: Using Scaffold
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Title')),
    body: Container(),
  );
}

// Wrong: Using Navigator.push
onTap: () {
  Navigator.push(context, MaterialPageRoute(
    builder: (context) => Subpage(),
  ));
}

// Wrong: Hardcoding styles
Text(
  'Title',
  style: TextStyle(
    fontSize: 20, // Hardcoded
    color: Colors.black, // Hardcoded
  ),
)
```

### ✅ Do This Instead
```dart
// Correct: Using Container
@override
Widget build(BuildContext context) {
  return Container(
    color: appBackground,
    child: Column(
      children: [
        // Header section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: widget.onBack,
              ),
              const Expanded(
                child: Text(
                  'Title',
                  style: TextStyle(
                    color: Colors.black87, 
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Main content
        Expanded(child: Container()),
      ],
    ),
  );
}

// Correct: Using MainLayout navigation
onTap: () {
  if (widget.onNavigate != null) {
    widget.onNavigate!(MainPage.subpage);
  }
}

// Correct: Using design system
Text(
  'Title',
  style: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  ),
)
```

## Testing Checklist

### Navigation Testing
- [ ] Back button works correctly
- [ ] Navigation between pages is smooth
- [ ] State is preserved when navigating
- [ ] Error states are handled properly

### UI Testing
- [ ] Layout looks correct on different screen sizes
- [ ] All interactive elements are accessible
- [ ] Loading states are displayed properly
- [ ] Error messages are clear and helpful

### Data Testing
- [ ] Data is loaded correctly
- [ ] Form validation works
- [ ] Save operations complete successfully
- [ ] Error handling works for failed operations

## Table Design Guidelines

### Overview
Tables are used to display structured data in rows and columns. This section provides guidelines for creating consistent and accessible tables throughout the application.

### Table Structure

#### 1. Table Container
```dart
// Use StandardTableContainer for consistent styling
StandardTableContainer(
  child: Column(
    children: [
      StandardTableHeader(...),
      // Table content
    ],
  ),
)

// Or use manual styling
Container(
  decoration: TableDesignSystem.tableContainerDecoration,
  child: Column(...),
)
```

#### 2. Table Header
```dart
StandardTableHeader(
  children: [
    TableColumn(
      flex: 3,
      child: Text('Column Name', style: TableDesignSystem.tableHeaderTextStyle),
    ),
    TableColumnFixed(
      width: 120,
      child: Text('Fixed Width', style: TableDesignSystem.tableHeaderTextStyle),
    ),
  ],
)
```

#### 3. Table Rows
```dart
StandardTableRow(
  onTap: () => handleRowTap(),
  children: [
    TableColumn(
      flex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Primary Text', style: TableDesignSystem.tableRowTextStyle),
          Text('Secondary Text', style: TableDesignSystem.tableRowSubtitleStyle),
        ],
      ),
    ),
    TableColumnFixed(
      width: 120,
      child: Text('Data', style: TableDesignSystem.tableRowTextStyle),
    ),
  ],
)
```

### Table Patterns

#### 1. Simple Data Table
```dart
StandardTableContainer(
  child: Column(
    children: [
      StandardTableHeader(
        children: [
          TableColumn(
            flex: 2,
            child: Text('Name', style: TableDesignSystem.tableHeaderTextStyle),
          ),
          TableColumn(
            flex: 1,
            child: Text('Count', style: TableDesignSystem.tableHeaderTextStyle),
          ),
        ],
      ),
      ...data.map((item) => StandardTableRow(
        onTap: () => onItemTap(item),
        children: [
          TableColumn(
            flex: 2,
            child: Text(item.name, style: TableDesignSystem.tableRowTextStyle),
          ),
          TableColumn(
            flex: 1,
            child: Text(item.count.toString(), style: TableDesignSystem.tableRowTextStyle),
          ),
        ],
      )),
    ],
  ),
)
```

#### 2. Hierarchical Table (Tree Structure)
```dart
StandardTableContainer(
  child: Column(
    children: [
      StandardTableHeader(...),
      ...buildTreeItems(items, level: 0),
    ],
  ),
)

List<Widget> buildTreeItems(List<Item> items, {int level = 0}) {
  return items.map((item) => Column(
    children: [
      StandardTableRow(
        onTap: () => onItemTap(item),
        children: [
          TableColumn(
            flex: 1,
            child: Row(
              children: [
                SizedBox(width: level * 32), // Indentation
                if (item.hasChildren) 
                  Icon(Icons.keyboard_arrow_right)
                else
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[600],
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(child: Text(item.name)),
              ],
            ),
          ),
          // Other columns...
        ],
      ),
      if (item.hasChildren && item.isExpanded)
        ...buildTreeItems(item.children, level: level + 1),
    ],
  )).toList();
}
```

#### 3. Table with Actions
```dart
StandardTableRow(
  children: [
    // Data columns...
    TableColumnFixed(
      width: 100,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => onEdit(item),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => onDelete(item),
          ),
        ],
      ),
    ),
  ],
)
```

### Table States

#### 1. Loading State
```dart
StandardTableContainer(
  child: TableDesignSystem.tableLoadingState,
)
```

#### 2. Empty State
```dart
StandardTableContainer(
  child: TableDesignSystem.tableEmptyState('No data available'),
)
```

#### 3. Error State
```dart
StandardTableContainer(
  child: TableDesignSystem.tableErrorState('Failed to load data'),
)
```

### Best Practices

#### 1. Column Sizing
- Use `TableColumn` with flex for flexible width columns
- Use `TableColumnFixed` for fixed-width columns (e.g., action buttons, counts)
- Common flex ratios: 3:1, 2:1, 1:1

#### 2. Text Hierarchy
- Primary text: `TableDesignSystem.tableRowTextStyle`
- Secondary text: `TableDesignSystem.tableRowSubtitleStyle`
- Header text: `TableDesignSystem.tableHeaderTextStyle`

#### 3. Interactive Elements
- Always use `StandardTableRow` with `onTap` for clickable rows
- Use `Material` + `InkWell` for proper touch feedback
- Provide visual indicators for interactive elements

#### 4. Responsive Design
- Use flexible columns for content that should adapt
- Set minimum widths for critical columns
- Consider mobile layout with stacked columns

#### 5. Accessibility
- Ensure sufficient color contrast
- Provide alternative text for icons
- Use semantic labels for interactive elements

### Common Patterns

#### 1. Product List Table
```dart
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
      ...products.map((product) => StandardTableRow(
        onTap: () => onProductTap(product),
        children: [
          TableColumn(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: TableDesignSystem.tableRowTextStyle),
                Text(product.category, style: TableDesignSystem.tableRowSubtitleStyle),
              ],
            ),
          ),
          TableColumn(
            flex: 1,
            child: Text(product.stock.toString(), style: TableDesignSystem.tableRowTextStyle),
          ),
          TableColumn(
            flex: 1,
            child: Text('\$${product.price}', style: TableDesignSystem.tableRowTextStyle),
          ),
        ],
      )),
    ],
  ),
)
```

#### 2. Category Tree Table
```dart
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
      ...buildCategoryTree(categories),
    ],
  ),
)
```

## Examples in Codebase

### Existing Subpages
1. **AddProductCategoryScreen** - Tạo danh mục mới
2. **ProductCategoryDetailScreen** - Chi tiết danh mục
3. **AddProductScreen** - Tạo sản phẩm mới
4. **ProductDetailScreen** - Chi tiết sản phẩm

### Reference Implementation
Xem các file sau để tham khảo:
- `lib/screens/add_product_category_screen.dart`
- `lib/screens/product_category_detail_screen.dart`
- `lib/widgets/main_layout.dart`

## Maintenance

### Version History
- **v1.0** - Initial styleguide creation
- **v1.1** - Added template code and best practices
- **v1.2** - Added testing checklist and examples

### Updates
Styleguide này sẽ được cập nhật khi có thay đổi trong design system hoặc architecture của ứng dụng.

---

**Lưu ý**: Tuân thủ styleguide này sẽ đảm bảo tính nhất quán và dễ dàng maintain code trong tương lai. 