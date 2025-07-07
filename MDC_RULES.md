# MDC (Machine-Readable Design Convention) Rules for viet_pos_flutter

## 1. Màu sắc chủ đạo
- Sử dụng `mainGreen` cho màu xanh lá chủ đạo, không dùng tên gây nhầm lẫn như `primaryBlue`.
- Các màu khác phải lấy từ file `design_system.dart`.

## 2. Input Fields
- Tất cả input phải cao 40px (`inputHeight`).
- Padding, borderRadius, màu nền, border phải lấy từ biến trong `design_system.dart`.
- Không hardcode giá trị style cho input.

## 3. UI Block & Card
- UI block/card phải phẳng, không có box-shadow.
- Bo góc, padding, màu nền phải lấy từ `design_system.dart`.
- Nếu cần border, chỉ dùng border đơn giản.

## 4. Typography
- Text style phải lấy từ các getter trong `design_system.dart`.
- Tiêu đề block lớn phải dùng màu `mainGreen`.
- Không tự định nghĩa inline TextStyle cho thành phần quan trọng.

## 5. Button
- Button phải dùng style từ `design_system.dart`.
- Không hardcode màu, border, padding cho button.

## 6. Đặt tên biến
- Tên biến màu phải đúng với màu thực tế.
- Tên biến style phải rõ ràng, nhất quán với file design system.

## 7. Sử dụng design system
- Mọi giá trị style đều phải lấy từ file `design_system.dart`.
- Nếu cần thêm style mới, phải bổ sung vào file này trước khi sử dụng.

## 8. Đồng bộ style
- Khi thay đổi style ở bất kỳ đâu, phải cập nhật lại file `design_system.dart`.
- Không sửa style cục bộ mà không cập nhật design system.

## 9. Kiểm tra và refactor
- Khi phát hiện tên biến style/màu không đúng thực tế, phải refactor lại cho đúng và đồng bộ toàn dự án.
- Ưu tiên refactor tên biến hơn là tạo alias hoặc giữ tên cũ.

## 10. Responsive Design

- Định nghĩa breakpoint rõ ràng cho mobile, tablet, desktop (ví dụ: mobile < 600px, tablet 600–1024px, desktop > 1024px).
- Sử dụng LayoutBuilder, MediaQuery, hoặc hàm responsive từ design system để điều chỉnh layout, spacing, sizing.
- Text style, padding, margin phải responsive theo breakpoint, ưu tiên dùng getter/hàm responsive trong design_system.dart.
- Ẩn/hiện thành phần phù hợp với từng loại thiết bị (ví dụ: sidebar chỉ desktop, bottom nav chỉ mobile).
- Đảm bảo không tràn nội dung (overflow) trên mọi kích thước màn hình, layout phải scroll được trên mobile nếu cần.
- Luôn kiểm tra UI trên mobile, tablet, desktop trước khi release.
- Ưu tiên tạo component có thể tái sử dụng và tự động điều chỉnh theo kích thước màn hình.

---

**Luôn lấy style từ design_system.dart, dùng tên biến đúng bản chất, không hardcode, không box-shadow, input cao 40px, tiêu đề dùng mainGreen, và đồng bộ mọi thay đổi về style.** 