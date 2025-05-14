---
1. App vision
Dành cho chủ tiệm thuốc thú y và nhân viên,
Những người cần một trợ lý kỹ thuật số đơn giản để kiểm soát sản phẩm, kiểm kê, và quản lý tồn kho,
Ứng dụng VET-POS là một mobile app quản lý sản phẩm – tồn kho,
Giúp tiết kiệm 30–50% thời gian kiểm kê, tránh thiếu hàng hoặc thất thoát,
Khác với các phần mềm phức tạp hoặc bảng tính thủ công,
VET-POS dễ sử dụng, hỗ trợ scan mã vạch và tương thích với iPad/điện thoại.

---
2.  User Roles & Permissions
Hiện tại, hệ thống chỉ có 1 vai trò duy nhất:
Admin (Chủ cửa hàng)
- Quyền hạn:
  - Truy cập tất cả các tính năng trong hệ thống.
  - Quản lý sản phẩm, danh mục
  - Kiểm kê kho, tạo – sửa – xóa sản phẩm.
  - Xem báo cáo, xuất dữ liệu.
- Đặc điểm:
  - Là người sử dụng chính của ứng dụng.
  - Có toàn quyền thao tác và kiểm soát toàn bộ hoạt động trong hệ thống.
  - Không có giới hạn tính năng theo phân quyền.
🔒 Lưu ý tương lai: Hệ thống có thể mở rộng để thêm các vai trò khác như: nhân viên bán hàng, nhân viên kho, nhân viên giao hàng – mỗi vai trò sẽ có giới hạn thao tác cụ thể. Tuy nhiên, trong phiên bản MVP 1, chỉ có Admin duy nhất.


4. Non-functional requirements
4.1 Hiệu năng
- Phản hồi thao tác dưới 2 giây.
- Xử lý mượt với 5.000 sản phẩm.
- Hoạt động ổn định trên iPad hoặc smartphone RAM ≥ 3GB.
4.2 Bảo mật
- Mã hóa dữ liệu nhà cung cấp & kiểm kê.
- Ghi log các thao tác thêm/sửa/xóa.
- Phân quyền người dùng để giới hạn quyền truy cập dữ liệu. (Có thể phân quyền cho các MVP sau)
4.3 Dễ sử dụng
- Giao diện thân thiện với người dùng không rành công nghệ.
- Tiếng Việt, từ ngữ dễ hiểu, thao tác trực quan.
- Biểu tượng, nút nhấn rõ ràng, dễ thao tác.
4.4 Độ tin cậy
- Tự động sao lưu dữ liệu mỗi ngày.
- Lưu tạm trên thiết bị khi mất mạng, đồng bộ sau.
4.5 Tương thích thiết bị
- Dùng tốt trên iPad, iPhone, Android (iOS 13+, Android 9+).
- Cần kết nối mạng và camera để quét barcode.
- Dung lượng bộ nhớ trống tối thiểu: 500MB.
5. Functional Requirements
5.1 Thêm sản phẩm mới
User Story:
Là chủ cửa hàng, tôi muốn thêm sản phẩm mới với đầy đủ thông tin để đảm bảo hệ thống lưu trữ đúng dữ liệu sản phẩm và phục vụ cho quản lý kho chính xác.
Acceptance Criteria:
- Người dùng nhập các thông tin:
  - Tên danh pháp (bắt buộc, duy nhất)
  - Tên thông dụng
  - Danh mục sản phẩm
  - Barcode (không bắt buộc, nếu có thì duy nhất)
  - SKU (không bắt buộc, nếu có thì duy nhất)
  - Đơn vị tính
  - Tags
  - Mô tả
  - Công dụng 
  - Thành phần
  - Ghi chú
  - Số lượng sản phẩm
  - Giá nhập 
  - Giá bán 
- Hệ thống hiển thị lỗi nếu barcode, SKU, tên danh pháp bị trùng.
- Nếu giá bán nhỏ hơn giá nhập, hệ thống hiển thị cảnh báo nhưng vẫn cho phép lưu nếu người dùng xác nhận.
- Sau khi lưu, sản phẩm mới sẽ hiển thị ở danh sách sản phẩm.
Lưu ý: Trong lần triển khai đầu tiên, phía khách hàng sẽ cung cấp một file Excel chứa khoảng 1.000 sản phẩm, bao gồm các trường thông tin cơ bản (tên danh pháp, tên thông dụng, giá, barcode, nhà cung cấp, v.v.). Developer cần tạo công cụ hỗ trợ import dữ liệu ban đầu để đưa toàn bộ danh sách sản phẩm lên hệ thống.


---
5.2 Xem và tìm kiếm sản phẩm
User Story:
Là chủ cửa hàng, tôi muốn xem và tìm kiếm danh sách sản phẩm để dễ dàng kiểm tra thông tin, tình trạng và thực hiện thao tác nhanh.
Acceptance Criteria:
- Có thể tìm sản phẩm theo tên, scan barcode, SKU.
- Có thể lọc theo: danh mục, tồn kho, giá bán, tag.
- Có thể sắp xếp theo: tên A–Z, giá cao/thấp, số lượng tồn kho.
- Khi nhấn nút quét barcode, hệ thống mở camera, quét mã và tìm đúng sản phẩm tương ứng

---
5.3 Xem chi tiết sản phẩm
User Story:
 Là chủ cửa hàng, tôi muốn xem chi tiết 1 sản phẩm để nắm được đầy đủ thông tin về sản phẩm đó.
Acceptance Criteria:
- Hiển thị đầy đủ các trường thông tin của sản phẩm.
- Có 2 nút thao tác: "Sửa sản phẩm" và "Xóa sản phẩm".
- Có nút "Quay lại" về danh sách sản phẩm.

---
5.4 Sửa sản phẩm
User Story:
 Là chủ cửa hàng, tôi muốn chỉnh sửa thông tin sản phẩm để đảm bảo dữ liệu luôn chính xác.
Acceptance Criteria:
- Người dùng có thể chỉnh sửa tất cả thông tin trừ:
  - Tên danh pháp (không thể thay đổi)
- Nếu Barcode, SKU bị trùng → hệ thống hiển thị lỗi.
- Nếu giá bán < giá nhập → hiển thị cảnh báo trước khi lưu.
- Sau khi lưu, cập nhật dữ liệu ngay trong danh sách sản phẩm.
- Hệ thống lưu lịch sử chỉnh sửa gồm: người chỉnh sửa, thời gian.

---
5.5 Xóa/Ngừng hoạt động sản phẩm
User Story:
 Là chủ cửa hàng, tôi muốn xóa/ngừng hoạt động sản phẩm không còn sử dụng để danh sách luôn gọn gàng.
Acceptance Criteria:
- Khi nhấn "Xóa sản phẩm", hệ thống hiển thị cảnh báo xác nhận trước khi xóa:
 "Bạn có chắc chắn muốn xóa sản phẩm này? Thao tác này không thể hoàn tác."
- Nếu sản phẩm còn tồn kho → không được phép xóa, hiển thị thông báo:
 "Không thể xóa sản phẩm còn tồn kho."
- Nếu đã từng kiểm kê hoặc có giao dịch → chỉ cho ngừng hoạt động, không được phép xóa.
- Sau khi xóa/ngừng hoạt động thành công, sản phẩm không hiển thị trong danh sách chính.

---
5.6 Tạo danh mục sản phẩm mới
User Story:
Là chủ cửa hàng, tôi muốn tạo danh mục sản phẩm để thuận tiện cho việc nhóm, xem và tìm kiếm sản phẩm
Condition:
Người dùng đang ở màn hình danh sách danh mục sản phẩm, người dùng chọn button "Thêm danh mục"
Acceptance Criteria:
- Người dùng nhập các thông tin:
  - Tên danh mục (bắt buộc)
  - Mô tả danh mục 
  - Thêm sản phẩm theo 2 cách
    - Cách 1: Thêm thủ công: Tìm kiếm sản phẩm, thêm sản phẩm
    - Cách 2: Thêm tự động: Chọn điều kiện theo giá, tag, nhà cung cấp,.. 
- Sau khi lưu, danh mục mới hiển thị trong danh sách danh mục
5.7 Xem danh mục sản phẩm mới
User Story:
Là chủ cửa hàng, tôi muốn xem danh sách danh mục hiện nay, có thể sắp xếp, tìm kiểm danh mục
Condition:
Người dùng đang ở màn hình danh sách danh mục sản phẩm
Acceptance Criteria:
- Có thể tìm sản phẩm theo tên 
- Có thể sắp xếp theo: tên A–Z, số lượng sản phẩm trong danh mục
5.8 Xem chi tiết danh mục sản phẩm
User Story:
 Là chủ cửa hàng, tôi muốn xem chi tiết danh mục sản phẩm để nắm được đầy đủ thông tin về sản phẩm đó.
Condition:
Người dùng đang ở màn hình danh sách danh mục sản phẩm, người dùng chọn 1 danh mục sản phẩm
Acceptance Criteria:
- Hiển thị đầy đủ các trường thông tin của danh mục
- Có 2 nút thao tác: "Sửa sản phẩm" và "Xóa sản phẩm".
- Có nút "Quay lại" về danh sách danh mục sản phẩm
5.9 Sửa danh mục sản phẩm
User Story:
 Là chủ cửa hàng, tôi muốn chỉnh sửa thông tin trong danh mục sản phẩm để đảm bảo dữ liệu luôn chính xác.
Condition:
Người dùng đang ở màn hình danh sách danh mục sản phẩm, người dùng chọn 1 danh mục sản phẩm
Acceptance Criteria:
- Người dùng có thể chỉnh sửa tất cả thông tin bao gồm: Tên danh mục, mô tả và sản phẩm trong danh mục
5.9 Xóa danh mục sản phẩm
User Story:
 Là chủ cửa hàng, tôi muốn xóa danh mục sản phẩm không còn sử dụng để danh sách luôn gọn gàng.
Acceptance Criteria:
- Khi nhấn "Xóa", hệ thống hiển thị cảnh báo xác nhận trước khi xóa:
 "Bạn có chắc chắn muốn xóa danh mục sản phẩm này? Thao tác này không thể hoàn tác."
- Sau khi xóa thành công, danh mục không hiển thị trong danh sách chính.
5.10 Kiểm kê kho
User Story:
Là chủ cửa hàng, tôi muốn thực hiện kiểm kê hàng hóa mỗi tháng để đảm bảo số lượng thực tế đúng với hệ thống.
Acceptance Criteria:
- Có 2 hình thức kiểm kê:
  - Kiểm kê từ danh sách có sẵn: hệ thống hiển thị danh sách cần kiểm kê theo tháng.
  - Kiểm kê bằng barcode: quét mã → hiện popup nhập số lượng → thêm vào danh sách kiểm kê.
- Có thể lưu phiên kiểm kê kèm ghi chú.
- Lưu lịch sử kiểm kê: ngày, người thực hiện, danh sách sản phẩm, lệch số lượng (nếu có).
- Nếu đã kiểm kê trong tháng → chỉ hiện lịch sử + cho phép "yêu cầu kiểm kê lại".

---
5.11 Báo cáo tồn kho
User Story:
Là chủ cửa hàng, tôi muốn xem báo cáo tồn kho để có kế hoạch nhập hàng và bán hàng hợp lý.
Acceptance Criteria:
- Có các loại báo cáo:
  - Sản phẩm sắp hết hàng (Số lượng dưới 5)
  - Sản phẩm tồn kho nhiều (Số lượng trên 500)
  - Lịch sử kiểm kê
- Có thể lọc báo cáo theo thời gian: tháng này, 30 ngày gần nhất, tùy chọn khoảng thời gian.
- Có thể xuất báo cáo ra PDF/Excel.