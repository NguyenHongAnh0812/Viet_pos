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
          // This full-screen GestureDetector handles taps outside the dropdown
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleDropdown,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent), // Make sure it can be hit
            ),
          ),
          // This positions the dropdown content below the input field
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0.0, size.height + 5.0),
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(borderRadiusMedium),
              child: SizedBox(
                width: size.width,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(borderRadiusMedium),
                    border: Border.all(color: borderColor),
                  ),
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
    return CompositedTransformTarget(
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
    );
  }
} 