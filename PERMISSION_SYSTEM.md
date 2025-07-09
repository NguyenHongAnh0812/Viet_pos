# Hệ Thống Phân Quyền - VET-POS

## Tổng Quan
Hệ thống phân quyền được thiết kế đơn giản với 2 vai trò chính để phù hợp với nhu cầu của cửa hàng thú y.

## Vai Trò (UserRole)

### 1. Admin (Quản trị viên)
- **Mô tả**: Chủ cửa hàng hoặc người quản lý chính
- **Màu sắc**: Đỏ (#DC2626)
- **Quyền hạn**: Toàn quyền truy cập tất cả tính năng

### 2. Employee (Nhân viên)
- **Mô tả**: Nhân viên bán hàng, thu ngân
- **Màu sắc**: Xanh lá (#059669)
- **Quyền hạn**: Hạn chế, chỉ các thao tác cơ bản

## Danh Sách Quyền (Permissions)

### Sản phẩm
- `viewProducts`: Xem danh sách sản phẩm
- `addProducts`: Thêm sản phẩm mới
- `editProducts`: Chỉnh sửa sản phẩm
- `deleteProducts`: Xóa sản phẩm

### Khách hàng
- `viewCustomers`: Xem danh sách khách hàng
- `addCustomers`: Thêm khách hàng mới
- `editCustomers`: Chỉnh sửa thông tin khách hàng
- `deleteCustomers`: Xóa khách hàng

### Đơn hàng
- `viewOrders`: Xem danh sách đơn hàng
- `createOrders`: Tạo đơn hàng mới
- `editOrders`: Chỉnh sửa đơn hàng
- `deleteOrders`: Xóa đơn hàng

### Kiểm kê
- `viewInventory`: Xem danh sách kiểm kê
- `createInventory`: Tạo phiên kiểm kê mới
- `editInventory`: Chỉnh sửa thông tin kiểm kê
- `confirmInventory`: Xác nhận kiểm kê

### Công ty/Nhà cung cấp
- `viewCompanies`: Xem danh sách công ty
- `addCompanies`: Thêm công ty mới
- `editCompanies`: Chỉnh sửa thông tin công ty
- `deleteCompanies`: Xóa công ty

### Danh mục
- `viewCategories`: Xem danh mục sản phẩm
- `addCategories`: Thêm danh mục mới
- `editCategories`: Chỉnh sửa danh mục
- `deleteCategories`: Xóa danh mục

### Cài đặt
- `viewSettings`: Xem cài đặt hệ thống
- `editSettings`: Chỉnh sửa cài đặt

### Quản lý nhân viên
- `viewUsers`: Xem danh sách nhân viên
- `addUsers`: Thêm nhân viên mới
- `editUsers`: Chỉnh sửa thông tin nhân viên
- `deleteUsers`: Xóa nhân viên

## Phân Quyền Theo Vai Trò

### Admin - Toàn quyền
```
Tất cả permissions trong hệ thống
```

### Employee - Quyền hạn chế
```
- viewProducts (Xem sản phẩm)
- viewCustomers (Xem khách hàng)
- addCustomers (Thêm khách hàng)
- editCustomers (Sửa khách hàng)
- viewOrders (Xem đơn hàng)
- createOrders (Tạo đơn hàng)
- editOrders (Sửa đơn hàng)
- viewInventory (Xem kiểm kê)
- createInventory (Tạo kiểm kê)
- editInventory (Sửa kiểm kê)
- viewCompanies (Xem công ty)
- viewCategories (Xem danh mục)
```

## Cách Sử Dụng

### 1. Kiểm tra quyền trong code
```dart
// Kiểm tra quyền cụ thể
if (user.hasPermission(Permission.addProducts)) {
  // Hiển thị nút thêm sản phẩm
}

// Kiểm tra vai trò
if (user.hasRole(UserRole.admin)) {
  // Hiển thị menu quản trị
}
```

### 2. Ẩn/hiện menu theo quyền
```dart
// Trong MainLayout
if (currentUser?.hasPermission(Permission.viewUsers) == true) {
  // Hiển thị menu "Quản lý nhân viên"
}
```

### 3. Bảo vệ màn hình
```dart
// Trong màn hình
if (!user.hasPermission(Permission.addProducts)) {
  Navigator.pop(context);
  return;
}
```

## Lưu Ý Quan Trọng

1. **Admin có toàn quyền**: Không cần kiểm tra từng permission riêng lẻ
2. **Employee bị hạn chế**: Không thể thêm/sửa/xóa sản phẩm, danh mục, công ty
3. **Bảo mật**: Luôn kiểm tra quyền trước khi cho phép thao tác
4. **UI/UX**: Ẩn các nút/menu mà user không có quyền truy cập

## Cập Nhật Tương Lai

Hệ thống được thiết kế để dễ dàng mở rộng:
- Thêm vai trò mới (ví dụ: Manager, Cashier)
- Thêm permission mới
- Tùy chỉnh quyền cho từng vai trò 