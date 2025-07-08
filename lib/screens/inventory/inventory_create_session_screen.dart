import 'package:flutter/material.dart';

import '../../services/product_service.dart';

import '../../services/inventory_service.dart';

import '../../services/inventory_item_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/common/design_system.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';
import 'inventory_detail_screen.dart';

class InventoryCreateSessionScreen extends StatefulWidget {
  const InventoryCreateSessionScreen({super.key});

  @override
  State<InventoryCreateSessionScreen> createState() => _InventoryCreateSessionScreenState();
}

class _InventoryCreateSessionScreenState extends State<InventoryCreateSessionScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _creatorController = TextEditingController();
  DateTime? _selectedDate = DateTime.now();

  int _selectMode = 0; // 0: all, 1: by category, 2: specific
  String? _selectedCategory;
  final _productService = ProductService();
  final Set<String> _selectedProducts = {};
  final _inventoryService = InventoryService();
  final _itemService = InventoryItemService();
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();
  List<Product> _allProducts = [];
  List<Product> _selectedProductList = [];
  List<String> _allCategories = ['Kháng sinh', 'Vitamin', 'Thức ăn', 'Vaccine']; // TODO: lấy từ service thực tế
  List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _productService.getProducts().first;
    setState(() {
      _allProducts = products;
    });
  }

  void _showProductPicker() async {
    final result = await showModalBottomSheet<List<Product>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final Set<String> tempSelected = Set.from(_selectedProducts);
        TextEditingController searchController = TextEditingController();
        List<Product> filteredProducts = List.from(_allProducts);
        return StatefulBuilder(
          builder: (context, setModalState) {
            void filterProducts(String query) {
              setModalState(() {
                filteredProducts = _allProducts.where((p) {
                  final q = query.toLowerCase();
                  return p.tradeName.toLowerCase().contains(q) ||
                         (p.sku ?? '').toLowerCase().contains(q) ||
                         (p.barcode ?? '').toLowerCase().contains(q);
                }).toList();
              });
            }
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chọn sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: mainGreen)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm sản phẩm, SKU, mã vạch...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        ),
                        onChanged: filterProducts,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, i) {
                            final p = filteredProducts[i];
                            final selected = tempSelected.contains(p.id);
                            return InkWell(
                              onTap: () {
                                setModalState(() {
                                  if (selected) {
                                    tempSelected.remove(p.id);
                                  } else {
                                    tempSelected.add(p.id);
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                                decoration: BoxDecoration(
                                  color: selected ? Color(0xFFF0FDF4) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p.tradeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          Text('SKU: ${p.sku ?? ''} | Tồn: ${p.stockSystem} ${p.unit}', style: const TextStyle(color: textSecondary, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      selected ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: selected ? mainGreen : Colors.grey[300],
                                      size: 28,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Hủy'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final selected = _allProducts.where((p) => tempSelected.contains(p.id)).toList();
                                Navigator.pop(context, selected);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: mainGreen),
                              child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
    if (result != null) {
      setState(() {
        _selectedProducts.clear();
        _selectedProducts.addAll(result.map((e) => e.id));
        _selectedProductList = result;
      });
    }
  }

  void _showCategoryPicker() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        List<String> tempSelected = List.from(_selectedCategories);
        TextEditingController searchController = TextEditingController();
        List<String> filteredCategories = List.from(_allCategories);
        return StatefulBuilder(
          builder: (context, setModalState) {
            void filterCategories(String query) {
              setModalState(() {
                filteredCategories = _allCategories.where((cat) => cat.toLowerCase().contains(query.toLowerCase())).toList();
              });
            }
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chọn danh mục', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: mainGreen)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm danh mục...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        ),
                        onChanged: filterCategories,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: filteredCategories.length,
                          itemBuilder: (context, i) {
                            final cat = filteredCategories[i];
                            final selected = tempSelected.contains(cat);
                            return InkWell(
                              onTap: () {
                                setModalState(() {
                                  if (selected) {
                                    tempSelected.remove(cat);
                                  } else {
                                    tempSelected.add(cat);
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                                decoration: BoxDecoration(
                                  color: selected ? Color(0xFFF0FDF4) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(cat, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    const SizedBox(width: 8),
                                    Icon(
                                      selected ? Icons.check_box : Icons.check_box_outline_blank,
                                      color: selected ? mainGreen : Colors.grey[300],
                                      size: 28,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Hủy'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context, tempSelected);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: mainGreen),
                              child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
    if (result != null) {
      setState(() {
        _selectedCategories = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: const BoxDecoration(
                        color: mainGreen,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(0),
                          topRight: Radius.circular(0),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () {
                              final mainLayoutState = context.findAncestorStateOfType<MainLayoutState>();
                              if (mainLayoutState != null) {
                                mainLayoutState.onSidebarTap(MainPage.inventory);
                              }
                            },
                          ),
                          const SizedBox(width: 4),
                          Text('Tạo phiếu kiểm kê', style: h2Mobile.copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Form
                    Container(
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: space16, vertical: space16),
                      margin: const EdgeInsets.only(bottom: space12),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tên phiếu kiểm kê *', style: bodyLarge.copyWith(color: textPrimary)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              style: bodyMobile.copyWith(color: textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Nhập tên phiếu kiểm kê',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: mainGreen, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập tên phiếu kiểm kê';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Text('Mô tả', style: bodyLarge.copyWith(color: textPrimary)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _noteController,
                              minLines: 2,
                              maxLines: 4,
                              style: bodyMobile.copyWith(color: textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Nhập mô tả (tùy chọn)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: mainGreen, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('Người tạo phiếu *', style: bodyLarge.copyWith(color: textPrimary)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _creatorController,
                              style: bodyMobile.copyWith(color: textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Nhập tên người tạo',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: mainGreen, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập tên người tạo';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Text('Ngày kiểm kê', style: bodyLarge.copyWith(color: textPrimary)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                  builder: (context, child) => Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: mainGreen,
                                        onPrimary: Colors.white,
                                        surface: cardBackground,
                                        onSurface: textPrimary,
                                      ),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: borderColor),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedDate != null
                                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                          : 'Chọn ngày',
                                      style: bodyMobile.copyWith(color: textPrimary),
                                    ),
                                    const Icon(Icons.calendar_today, color: textSecondary, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Danh sách sản phẩm kiểm kê
                    Container(
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: space16, vertical: space16),
                      margin: const EdgeInsets.only(bottom: space12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Danh sách sản phẩm', style: h3Mobile.copyWith(color: mainGreen)),
                          const SizedBox(height: 12),
                          Column(
                            children: [
                              RadioListTile<int>(
                                value: 0,
                                groupValue: _selectMode,
                                onChanged: (v) => setState(() => _selectMode = v ?? 0),
                                title: const Text('Tất cả các sản phẩm'),
                              ),
                              RadioListTile<int>(
                                value: 1,
                                groupValue: _selectMode,
                                onChanged: (v) => setState(() => _selectMode = v ?? 1),
                                title: const Text('Theo danh mục'),
                              ),
                              if (_selectMode == 1) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text('Chọn danh mục:', style: TextStyle(fontWeight: FontWeight.w500)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _showCategoryPicker,
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('Chọn danh mục'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: mainGreen,
                                          side: const BorderSide(color: mainGreen),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ..._selectedCategories.map((cat) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(cat, style: const TextStyle(fontWeight: FontWeight.w600))),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _selectedCategories.remove(cat);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                              RadioListTile<int>(
                                value: 2,
                                groupValue: _selectMode,
                                onChanged: (v) => setState(() => _selectMode = v ?? 2),
                                title: const Text('Sản phẩm cụ thể'),
                              ),
                              if (_selectMode == 2) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Sản phẩm đã chọn:', style: TextStyle(fontWeight: FontWeight.w500)),
                                    ElevatedButton.icon(
                                      onPressed: _showProductPicker,
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Thêm sản phẩm'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: mainGreen,
                                        side: const BorderSide(color: mainGreen),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_selectedProductList.isEmpty)
                                  const Text('Chưa có sản phẩm nào được chọn.'),
                                ..._selectedProductList.map((p) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(p.tradeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                            Text('SKU: ${p.sku ?? ''} | Tồn: ${p.stockSystem} ${p.unit}', style: const TextStyle(color: textSecondary, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _selectedProducts.remove(p.id);
                                            _selectedProductList.removeWhere((item) => item.id == p.id);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Ghim bottom 2 nút Hủy và Tạo phiếu
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        final mainLayoutState = context.findAncestorStateOfType<MainLayoutState>();
                        if (mainLayoutState != null) {
                          mainLayoutState.onSidebarTap(MainPage.inventory);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: const BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : () async {
                        if (!_formKey.currentState!.validate()) {
                          setState(() => _saving = false);
                          return;
                        }
                        setState(() => _saving = true);
                        // Tạo phiên kiểm kê
                        final products = await _productService.getProducts().first;
                        List<Product> selectedProducts;
                        if (_selectMode == 0) {
                          selectedProducts = products;
                        } else if (_selectMode == 1) {
                          List<Product> filtered = [];
                          if (_selectedCategories.isNotEmpty) {
                            final productCategoryDocs = await FirebaseFirestore.instance
                              .collection('product_categories')
                              .where('category_id', whereIn: _selectedCategories)
                              .get();
                            final productIds = productCategoryDocs.docs.map((doc) => doc['product_id']).toSet();
                            filtered = products.where((p) => productIds.contains(p.id)).toList();
                          } else {
                            filtered = products;
                          }
                          selectedProducts = filtered;
                        } else {
                          selectedProducts = _selectedProductList;
                        }
                        final now = DateTime.now();
                        final user = FirebaseAuth.instance.currentUser;
                        String? userName;
                        if (user != null) {
                          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                          userName = userDoc.data()?['name'] ?? user.email;
                        }
                        final sessionData = {
                          'name': _nameController.text.trim(),
                          'created_at': now,
                          'created_by': _creatorController.text.trim().isNotEmpty ? _creatorController.text.trim() : (userName ?? 'Không rõ'),
                          'created_by_id': user?.uid,
                          'note': _noteController.text,
                          'status': 'draft',
                        };
                        final sessionRef = await FirebaseFirestore.instance.collection('inventory_sessions').add(sessionData);
                        final sessionId = sessionRef.id;
                        // Tạo các inventory_items
                        for (final p in selectedProducts) {
                          await _itemService.addItem({
                            'session_id': sessionId,
                            'product_id': p.id,
                            'product_name': p.tradeName,
                            'stock_system': p.stockSystem,
                            'stock_actual': p.stockSystem,
                            'diff': 0,
                            'note': '',
                          });
                        }
                        setState(() => _saving = false);
                        if (!mounted) return;
                        
                        // Debug log để kiểm tra
                        print('Session created with ID: $sessionId');
                        
                        final mainLayoutState = context.findAncestorStateOfType<MainLayoutState>();
                        if (mainLayoutState != null) {
                          print('MainLayoutState found, navigating to inventory detail');
                          mainLayoutState.openInventoryDetail(sessionId);
                        } else {
                          print('MainLayoutState is null, using Navigator.push');
                          // Fallback: sử dụng Navigator.push nếu không tìm thấy MainLayoutState
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InventoryDetailScreen(sessionId: sessionId),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Tạo phiếu'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 