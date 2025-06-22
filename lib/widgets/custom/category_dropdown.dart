import 'package:flutter/material.dart';
import '../../models/product_category.dart';
import '../../services/product_category_service.dart';
import '../common/design_system.dart';

class CategoryDropdownButton extends StatefulWidget {
  final List<String> selectedCategoryIds;
  final Function(List<String>) onChanged;
  final String? hint;
  final bool isMultiSelect;

  const CategoryDropdownButton({
    Key? key,
    required this.selectedCategoryIds,
    required this.onChanged,
    this.hint,
    this.isMultiSelect = true,
  }) : super(key: key);

  @override
  State<CategoryDropdownButton> createState() => _CategoryDropdownButtonState();
}

class _CategoryDropdownButtonState extends State<CategoryDropdownButton> {
  final ProductCategoryService _categoryService = ProductCategoryService();
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<State<StatefulWidget>> _dropdownKey = GlobalKey();
  
  bool _isDropdownOpen = false;
  OverlayEntry? _overlayEntry;
  List<ProductCategory> _categories = [];
  List<String> _currentSelectedValues = [];
  bool _isLoading = true;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _currentSelectedValues = List.from(widget.selectedCategoryIds);
    _loadCategories();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void didUpdateWidget(covariant CategoryDropdownButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategoryIds != oldWidget.selectedCategoryIds) {
      _currentSelectedValues = List.from(widget.selectedCategoryIds);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      print('Loading categories...');
      final categories = await _categoryService.getCategories().first;
      print('Loaded ${categories.length} categories');
      for (final cat in categories) {
        print('Category: ${cat.name} (ID: ${cat.id}, Parent: ${cat.parentId})');
      }
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<ProductCategory> get _filteredCategories {
    if (_searchText.isEmpty) {
      return _categories;
    }
    return _categories.where((category) {
      return category.name.toLowerCase().contains(_searchText);
    }).toList();
  }

  List<ProductCategory> _getChildren(String parentId) {
    return _categories.where((category) => category.parentId == parentId).toList();
  }

  List<ProductCategory> _getRootCategories() {
    return _categories.where((category) => 
      category.parentId == null || category.parentId!.isEmpty
    ).toList();
  }

  String _getDisplayText() {
    if (_currentSelectedValues.isEmpty) {
      return widget.hint ?? 'Chọn danh mục';
    }
    
    if (_currentSelectedValues.length == 1) {
      final category = _categories.firstWhere(
        (c) => c.id == _currentSelectedValues.first,
        orElse: () => ProductCategory(id: '', name: 'Unknown'),
      );
      return category.name;
    }
    
    return '${_currentSelectedValues.length} danh mục được chọn';
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _overlayEntry?.remove();
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    }
    setState(() {
      _isDropdownOpen = !_isDropdownOpen;
    });
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dropdown content
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 45), // Offset from button
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(borderRadiusMedium),
              child: Container(
                width: size.width, // Use button width
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(borderRadiusMedium),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with close button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: mutedBackground,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(borderRadiusMedium),
                          topRight: Radius.circular(borderRadiusMedium),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Chọn danh mục',
                            style: body.copyWith(fontWeight: FontWeight.w600),
                          ),
                          IconButton(
                            onPressed: _toggleDropdown,
                            icon: const Icon(Icons.close, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm danh mục...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadiusSmall),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        style: body,
                      ),
                    ),
                    // Categories list
                    Flexible(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredCategories.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('Không có danh mục nào'),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _getRootCategories().length,
                                  itemBuilder: (context, index) {
                                    final rootCategory = _getRootCategories()[index];
                                    return _buildCategoryItem(rootCategory, 0);
                                  },
                                ),
                    ),
                    // Footer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: mutedBackground,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(borderRadiusMedium),
                          bottomRight: Radius.circular(borderRadiusMedium),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_currentSelectedValues.length} danh mục được chọn',
                            style: body.copyWith(color: textSecondary),
                          ),
                          TextButton(
                            onPressed: () {
                              _onSelectionChanged([]);
                              _searchController.clear();
                            },
                            child: const Text('Xóa tất cả'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSelectionChanged(List<String> newSelection) {
    setState(() {
      _currentSelectedValues = newSelection;
    });
    
    // Force overlay rebuild
    if (_isDropdownOpen) {
      _overlayEntry?.markNeedsBuild();
    }
    
    // Inform parent
    widget.onChanged(newSelection);
  }

  void _toggleCategory(String categoryId) {
    final newSelection = List<String>.from(_currentSelectedValues);
    
    if (newSelection.contains(categoryId)) {
      newSelection.remove(categoryId);
    } else {
      newSelection.add(categoryId);
    }
    
    _onSelectionChanged(newSelection);
  }

  Widget _buildCategoryItem(ProductCategory category, int level) {
    final children = _getChildren(category.id);
    final isSelected = _currentSelectedValues.contains(category.id);
    final hasChildren = children.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(
            left: 16 + (level * 20),
            right: 16,
          ),
          title: Row(
            children: [
              if (hasChildren)
                Icon(
                  Icons.folder,
                  size: 16,
                  color: Colors.orange[600],
                )
              else
                Icon(
                  Icons.category,
                  size: 16,
                  color: Colors.blue[600],
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.name,
                  style: body.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? primaryBlue : textPrimary,
                  ),
                ),
              ),
            ],
          ),
          leading: widget.isMultiSelect
              ? Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleCategory(category.id),
                  activeColor: primaryBlue,
                )
              : null,
          onTap: () => _toggleCategory(category.id),
        ),
        if (hasChildren)
          ...children.map((child) => _buildCategoryItem(child, level + 1)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Close dropdown when scrolling
        if (_isDropdownOpen) {
          _toggleDropdown();
        }
        return false; // Allow scroll to continue
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: GestureDetector(
          onTap: _toggleDropdown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: borderColor),
                borderRadius: BorderRadius.circular(borderRadiusMedium),
              ),
              color: mutedBackground,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(_getDisplayText(), style: body),
                Icon(
                  _isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 