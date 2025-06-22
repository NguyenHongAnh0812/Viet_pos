import 'package:flutter/material.dart';
import '../../widgets/common/design_system.dart';

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

  const MultiSelectDropdown({
    Key? key,
    required this.label,
    required this.items,
    this.initialSelectedValues = const [],
    required this.onSelectionChanged,
    this.hint = 'Chọn một hoặc nhiều',
  }) : super(key: key);

  @override
  _MultiSelectDropdownState<T> createState() => _MultiSelectDropdownState<T>();
}

class _MultiSelectDropdownState<T> extends State<MultiSelectDropdown<T>> {
  bool _isDropdownOpen = false;
  late OverlayEntry _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  late List<T> _currentSelectedValues;
  final GlobalKey<State<StatefulWidget>> _dropdownKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentSelectedValues = List.from(widget.initialSelectedValues);
  }
  
  @override
  void didUpdateWidget(covariant MultiSelectDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync state if the initial values are changed from outside
    if (widget.initialSelectedValues != oldWidget.initialSelectedValues) {
      _currentSelectedValues = List.from(widget.initialSelectedValues);
    }
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _overlayEntry.remove();
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry);
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
          // This positions the dropdown content below the input field
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 45), // Offset from button
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(borderRadiusMedium),
              child: Container(
                width: size.width, // Use button width
                constraints: const BoxConstraints(maxHeight: 250),
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
                            'Chọn ${widget.label}',
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
                    // Items list
                    Flexible(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: widget.items.length,
                        itemBuilder: (context, index) {
                          final item = widget.items[index];
                          final isSelected = _currentSelectedValues.contains(item.value);
                          return ListTile(
                            title: Text(item.label, style: body),
                            leading: Checkbox(
                              value: isSelected,
                              onChanged: (bool? checked) {
                                _onItemCheckedChange(item.value, checked ?? false);
                              },
                              activeColor: primaryBlue,
                            ),
                            onTap: () {
                               _onItemCheckedChange(item.value, !isSelected);
                            },
                          );
                        },
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

  void _onItemCheckedChange(T itemValue, bool isSelected) {
    final newSelectedValues = List<T>.from(_currentSelectedValues);
    if (isSelected) {
      if (!newSelectedValues.contains(itemValue)) {
        newSelectedValues.add(itemValue);
      }
    } else {
      newSelectedValues.remove(itemValue);
    }
    
    setState(() {
      _currentSelectedValues = newSelectedValues;
    });
    
    // Force the overlay to rebuild to show the new state
    _overlayEntry.markNeedsBuild();
    
    // Inform the parent widget about the change
    widget.onSelectionChanged(newSelectedValues);
  }

  String _getDisplayText() {
    if (_currentSelectedValues.isEmpty) {
      return widget.hint;
    }
    final count = _currentSelectedValues.length;
    return '$count nhà cung cấp được chọn';
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

  @override
  void dispose() {
    super.dispose();
  }
} 