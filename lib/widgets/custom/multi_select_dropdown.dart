import 'package:flutter/material.dart';
import '../../widgets/common/design_system.dart';
import '../../models/product_category.dart';

// Một class chung để đại diện cho một item có thể chọn
class MultiSelectItem<T> {
  final T value;
  final String label;

  MultiSelectItem({required this.value, required this.label});
}

class MultiSelectDropdown<T> extends StatefulWidget {
  final String label;
  final List<MultiSelectItem<T>> items;
  final List<T> initialSelectedValues;
  final ValueChanged<List<T>> onSelectionChanged;
  final String hint;
  final bool isTreeMode;
  final String? selectedLabel; // Thêm tham số này

  const MultiSelectDropdown({
    super.key,
    required this.label,
    required this.items,
    this.initialSelectedValues = const [],
    required this.onSelectionChanged,
    this.hint = 'Chọn một hoặc nhiều',
    this.isTreeMode = false,
    this.selectedLabel,
  });

  @override
  _MultiSelectDropdownState<T> createState() => _MultiSelectDropdownState<T>();
}

class _MultiSelectDropdownState<T> extends State<MultiSelectDropdown<T>> {
  bool _isDropdownOpen = false;
  late List<T> _currentSelectedValues;
  final GlobalKey<State<StatefulWidget>> _dropdownKey = GlobalKey();
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentSelectedValues = List.from(widget.initialSelectedValues);
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim();
      });
    });
  }
  
  @override
  void didUpdateWidget(covariant MultiSelectDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync state if the initial values are changed from outside
    if (widget.initialSelectedValues != oldWidget.initialSelectedValues) {
      _currentSelectedValues = List.from(widget.initialSelectedValues);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openMultiSelectDialog() async {
    final result = await showDialog<List<T>>(
      context: context,
      builder: (context) {
        List<T> tempSelected = List.from(_currentSelectedValues);
        String tempSearch = '';
        final tempSearchController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final filteredItems = widget.items.where((item) =>
              tempSearch.isEmpty || item.label.toLowerCase().contains(tempSearch.toLowerCase())
            ).toList();
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadiusLarge)),
              contentPadding: const EdgeInsets.all(0),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: mutedBackground,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(borderRadiusLarge),
                          topRight: Radius.circular(borderRadiusLarge),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Chọn ${widget.label}', style: h3),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    // Search box
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: TextField(
                        controller: tempSearchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm...',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        style: body,
                        onChanged: (val) => setStateDialog(() { tempSearch = val.trim(); }),
                      ),
                    ),
                    // Nếu tree mode thì không hiển thị chip/tag đã chọn
                    if (!widget.isTreeMode && tempSelected.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tempSelected.map((id) {
                            final item = widget.items.firstWhere((e) => e.value == id);
                            return Chip(
                              label: Text(item.label, style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w600, fontSize: 14)),
                              backgroundColor: const Color(0xFFD1FADF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              deleteIcon: const Icon(Icons.close, size: 16, color: Color(0xFF22C55E)),
                              onDeleted: () => setStateDialog(() => tempSelected.remove(id)),
                              labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: BorderSide.none,
                            );
                          }).toList(),
                        ),
                      ),
                    // List
                    Flexible(
                      child: filteredItems.isEmpty
                        ? Center(child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Không tìm thấy kết quả', style: mutedText),
                          ))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              final isSelected = tempSelected.contains(item.value);
                              int level = 0;
                              if (widget.isTreeMode && item.value is ProductCategory && (item.value as ProductCategory).level != null) {
                                level = (item.value as ProductCategory).level!;
                              }
                              return Padding(
                                padding: EdgeInsets.only(left: widget.isTreeMode ? level * 20.0 : 0),
                                child: ListTile(
                                  title: Text(item.label, style: body),
                                  leading: Checkbox(
                                    value: isSelected,
                                    onChanged: (bool? checked) {
                                      setStateDialog(() {
                                        if (checked == true) {
                                          if (!tempSelected.contains(item.value)) tempSelected.add(item.value);
                                        } else {
                                          tempSelected.remove(item.value);
                                        }
                                      });
                                    },
                                    activeColor: mainGreen,
                                  ),
                                  onTap: () {
                                    setStateDialog(() {
                                      if (isSelected) {
                                        tempSelected.remove(item.value);
                                      } else {
                                        tempSelected.add(item.value);
                                      }
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                    ),
                    // Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Hủy'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(tempSelected),
                            style: primaryButtonStyle,
                            child: const Text('Xác nhận'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (result != null) {
      setState(() {
        _currentSelectedValues = result;
      });
      widget.onSelectionChanged(result);
    }
  }

  String _getDisplayText() {
    if (_currentSelectedValues.isEmpty) {
      return widget.hint;
    }
    final count = _currentSelectedValues.length;
    if (widget.selectedLabel != null && widget.selectedLabel!.isNotEmpty) {
      return '$count ${widget.selectedLabel} được chọn';
    }
    return '$count mục được chọn'; // fallback mặc định
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openMultiSelectDialog,
      child: Container(
        height: inputHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
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
            Expanded(
              child: Text(
                _getDisplayText(),
                style: body,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: textSecondary,
            ),
          ],
        ),
      ),
    );
  }
} 