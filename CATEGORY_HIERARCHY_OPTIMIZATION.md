# Tối ưu hóa Category Hierarchy - So sánh các Approach

## 1. **Approach hiện tại: Adjacency List (Danh sách kề)**

### Cấu trúc:
```dart
class ProductCategory {
  final String id;
  final String name;
  final String? parentId; // Chỉ lưu ID của parent trực tiếp
}
```

### Ưu điểm:
- ✅ Đơn giản, dễ hiểu
- ✅ Dễ dàng thêm/sửa/xóa category
- ✅ Ít dữ liệu lưu trữ
- ✅ Dễ dàng query children trực tiếp

### Nhược điểm:
- ❌ Query ancestors cần recursive (nhiều lần query)
- ❌ Query descendants cần recursive
- ❌ Không có index tự động cho hierarchy
- ❌ Performance kém khi hierarchy sâu

### Ví dụ query:
```dart
// Lấy ancestors - cần nhiều query
Future<List<String>> getAllParentCategoryIds(String categoryId) async {
  List<String> parentIds = [];
  String currentId = categoryId;
  
  while (currentId.isNotEmpty) {
    final doc = await FirebaseFirestore.instance.collection('categories').doc(currentId).get();
    // ... recursive logic
  }
  return parentIds;
}
```

---

## 2. **Approach 1: Materialized Path (Đường dẫn vật chất hóa)**

### Cấu trúc:
```dart
class ProductCategoryOptimized {
  final String id;
  final String name;
  final String? parentId;
  final String path; // "/Thuốc/Vitamin/Vitamin B"
  final List<String> pathArray; // ["Thuốc", "Vitamin", "Vitamin B"]
  final int level; // 0 = root, 1 = first level, etc.
}
```

### Ưu điểm:
- ✅ Query ancestors/descendants nhanh (1 query)
- ✅ Dễ dàng hiển thị full path
- ✅ Có thể search theo path
- ✅ Natural ordering theo hierarchy
- ✅ Index-friendly

### Nhược điểm:
- ❌ Phức tạp hơn khi thêm/sửa/xóa
- ❌ Cần update tất cả children khi move category
- ❌ Path có thể dài với hierarchy sâu

### Ví dụ query:
```dart
// Lấy descendants - chỉ 1 query
Future<List<ProductCategoryOptimized>> getDescendants(String categoryId) async {
  final categoryPath = await getCategoryPath(categoryId);
  
  return _firestore
      .collection('categories')
      .where('path', isGreaterThan: categoryPath)
      .where('path', isLessThan: '$categoryPath\uf8ff')
      .get();
}

// Lấy ancestors - chỉ 1 query
Future<List<ProductCategoryOptimized>> getAncestors(String categoryId) async {
  final pathArray = await getCategoryPathArray(categoryId);
  final ancestorNames = pathArray.sublist(0, pathArray.length - 1);
  
  return _firestore
      .collection('categories')
      .where('name', whereIn: ancestorNames)
      .get();
}
```

---

## 3. **Approach 2: Nested Sets (Tập hợp lồng nhau)**

### Cấu trúc:
```dart
class ProductCategoryNestedSets {
  final String id;
  final String name;
  final int left; // Left boundary
  final int right; // Right boundary
  final int level; // Hierarchy level
}
```

### Ví dụ cấu trúc:
```
Thuốc (left: 1, right: 10, level: 0)
├── Vitamin (left: 2, right: 7, level: 1)
│   ├── Vitamin B (left: 3, right: 4, level: 2)
│   └── Vitamin C (left: 5, right: 6, level: 2)
└── Thuốc giảm đau (left: 8, right: 9, level: 1)
```

### Ưu điểm:
- ✅ Query ancestors/descendants cực nhanh (1 query)
- ✅ Hiệu quả cho read-heavy applications
- ✅ Dễ dàng tính toán số lượng descendants
- ✅ Index-friendly với left/right values

### Nhược điểm:
- ❌ Rất phức tạp khi thêm/sửa/xóa
- ❌ Cần update nhiều records khi thay đổi structure
- ❌ Không phù hợp cho write-heavy applications
- ❌ Khó debug và maintain

### Ví dụ query:
```dart
// Lấy descendants - chỉ 1 query
Future<List<ProductCategoryNestedSets>> getDescendants(String categoryId) async {
  final category = await getCategory(categoryId);
  
  return _firestore
      .collection('categories')
      .where('left', isGreaterThan: category.left)
      .where('right', isLessThan: category.right)
      .get();
}

// Lấy ancestors - chỉ 1 query
Future<List<ProductCategoryNestedSets>> getAncestors(String categoryId) async {
  final category = await getCategory(categoryId);
  
  return _firestore
      .collection('categories')
      .where('left', isLessThan: category.left)
      .where('right', isGreaterThan: category.right)
      .get();
}
```

---

## 4. **Approach 3: Closure Table (Bảng đóng)**

### Cấu trúc:
```dart
// Categories table
class ProductCategory {
  final String id;
  final String name;
  final String? parentId;
}

// Category relationships table
class CategoryRelationship {
  final String ancestorId;
  final String descendantId;
  final int depth; // 0 = self, 1 = parent, 2 = grandparent, etc.
}
```

### Ví dụ dữ liệu:
```
Categories:
- cat1: "Thuốc"
- cat2: "Vitamin" (parent: cat1)
- cat3: "Vitamin B" (parent: cat2)

Relationships:
- cat1 -> cat1 (depth: 0)
- cat1 -> cat2 (depth: 1)
- cat1 -> cat3 (depth: 2)
- cat2 -> cat2 (depth: 0)
- cat2 -> cat3 (depth: 1)
- cat3 -> cat3 (depth: 0)
```

### Ưu điểm:
- ✅ Query ancestors/descendants nhanh
- ✅ Dễ dàng thêm/sửa/xóa category
- ✅ Linh hoạt cho complex queries
- ✅ Có thể query theo depth

### Nhược điểm:
- ❌ Cần 2 collections
- ❌ Dữ liệu redundant
- ❌ Phức tạp hơn để implement

---

## 5. **Khuyến nghị cho Pharmacy Management System**

### **Recommendation: Materialized Path**

**Lý do:**
1. **Performance tốt**: Query ancestors/descendants chỉ cần 1 lần
2. **Dễ implement**: Không quá phức tạp như Nested Sets
3. **Phù hợp với use case**: Pharmacy system thường read-heavy
4. **Search-friendly**: Có thể search theo full path
5. **Natural ordering**: Categories tự động sắp xếp theo hierarchy

### **Implementation Plan:**

1. **Phase 1**: Tạo optimized model và service
2. **Phase 2**: Migration tool để convert existing data
3. **Phase 3**: Update UI components
4. **Phase 4**: Performance testing và optimization

### **Migration Strategy:**
```dart
// Migration từ Adjacency List sang Materialized Path
Future<void> migrateToMaterializedPath() async {
  final oldCategories = await getOldCategories();
  
  for (final oldCat in oldCategories) {
    final pathData = await calculatePath(oldCat.parentId, oldCat.name);
    
    await createOptimizedCategory({
      'name': oldCat.name,
      'description': oldCat.description,
      'parentId': oldCat.parentId,
      'path': pathData['path'],
      'pathArray': pathData['pathArray'],
      'level': pathData['level'],
    });
  }
}
```

### **Performance Comparison:**

| Operation | Adjacency List | Materialized Path | Nested Sets |
|-----------|----------------|-------------------|-------------|
| Get children | ✅ Fast | ✅ Fast | ✅ Fast |
| Get ancestors | ❌ Slow (N queries) | ✅ Fast (1 query) | ✅ Fast (1 query) |
| Get descendants | ❌ Slow (N queries) | ✅ Fast (1 query) | ✅ Fast (1 query) |
| Add category | ✅ Fast | ⚠️ Medium | ❌ Slow |
| Move category | ✅ Fast | ❌ Slow | ❌ Very Slow |
| Delete category | ✅ Fast | ⚠️ Medium | ❌ Slow |

### **Firestore Indexes cần thiết:**
```javascript
// categories_optimized collection
{
  "path": "ASCENDING",
  "level": "ASCENDING"
}

{
  "level": "ASCENDING", 
  "name": "ASCENDING"
}

{
  "parentId": "ASCENDING",
  "name": "ASCENDING"
}
```

---

## 6. **Kết luận**

**Materialized Path** là lựa chọn tốt nhất cho pharmacy management system vì:
- Cân bằng tốt giữa performance và complexity
- Phù hợp với read-heavy nature của pharmacy system
- Dễ dàng implement và maintain
- Có thể scale tốt với hierarchy sâu

**Next Steps:**
1. Implement Materialized Path approach
2. Create migration tool
3. Update existing screens
4. Performance testing
5. Gradual rollout 