1. Overview 
- Mục tiêu: Xây dựng hệ thống quản lý bán hàng, đáp ứng quy trình thực tế tại quầy và hậu cần kế toán.
- Stakeholders chính: Chủ cửa hàng, nhân viên bán hàng, kế toán, khách hàng.

---
2. Actor & Vai trò
This content is only supported in a Lark Docs

---
3. User Stories 
Epic 1: Tạo đơn bán hàng
User story 1: Thêm sản phẩm vào đơn hàng bằng cách tìm kiếm thủ công
Là một nhân viên bán hàng, 
Tôi muốn tìm kiếm sản phẩm bằng tên sản phẩm hoặc mã code của sản phẩm, 
Để tôi có thể nhanh chóng tìm thấy sản phẩm và thêm vào đơn hàng
Acceptance Criteria:
- Cho phép tìm theo tên hoặc mã sản phẩm.
- Hiển thị danh sách gợi ý động ngay bên dưới thanh tìm kiếm khi gõ từ khóa.
- Nếu người dùng nhấn Enter, hoặc biểu tượng tìm kiếm (🔍), hệ thống chuyển sang màn hình danh sách đầy đủ các sản phẩm gợi ý liên quan đến từ khóa. 
- Danh sách sản phẩm gợi ý cần được sắp xếp theo thứ tự như sau:
  - Sản phẩm càng khớp với từ khoá hoặc mã code thì càng được ưu tiên hiện thị ở vị trí đầu
  - Sản phẩm hết hàng luôn được hiển thị ở cuối cùng
- Nếu không tìm thấy, hệ thống hiển thị “Không có sản phẩm nào khớp với mã hoặc từ khoá bạn đã nhập.”
- Khi người dùng chọn sản phẩm từ danh sách gợi ý, hệ thống tự động thêm vào đơn hàng với số lượng mặc định là 1
- Nếu số lượng vượt quá tồn kho:
  - Hệ thống không cho phép thêm vượt quá.
  - Hiển thị cảnh báo bằng màu đỏ tại ô nhập số lượng.
  - Hiển thị thông báo: "Số lượng yêu cầu vượt quá tồn kho hiện tại"
  
User story 2: Thêm sản phẩm vào đơn hàng bằng cách quét mã vạch sản phẩm
Là một nhân viên bán hàng,
Tôi muốn quét mã vạch của sản phẩm,
Để tôi có thể thêm sản phẩm đó vào đơn hàng một cách nhanh chóng.
Acceptance Criteria:
- Cho phép người dùng quét mã barcode để nhận diện sản phẩm.
- Khi sản phẩm được nhận diện thành công:
  - Sản phẩm được tự động thêm vào đơn hàng với số lượng mặc định là 1.
  - Camera vẫn tiếp tục hoạt động để người dùng có thể tiếp tục quét các sản phẩm khác.
- Chỉ khi người dùng nhấn nút “X” hoặc nút thoát, camera mới được tắt.
- Nếu barcode không hợp lệ hoặc không khớp sản phẩm nào:
  - Hiển thị popup thông báo: "Không tìm thấy sản phẩm tương ứng với mã vạch."
  - Không thêm sản phẩm vào đơn.
- Nếu sản phẩm hết hàng (tồn kho bằng 0):
  - Hiển thị popup thông báo: "Sản phẩm đã hết hàng."
  - Không thêm vào đơn.
- Nếu sản phẩm đã có trong đơn, hệ thống tăng số lượng sản phẩm đó. Nếu số lượng vượt quá lượng số lượng tồn kho thì hiển thị popup thông báo "Sản phẩm đã đạt số lượng tối đa theo tồn kho hiện tại."

User story 3: Quản lý đơn hàng
Là một Nhân viên bán hàng,
Tôi muốn xem lại và cập nhật các mặt hàng trong đơn,
để tôi có thể đảm bảo độ chính xác trước khi hoàn tất đơn hàng.

Acceptance Criteria:
- Cho phép xem toàn bộ danh sách sản phẩm đã thêm vào đơn hàng.
- Cho phép thay đổi số lượng từng sản phẩm trong đơn hàng thông qua:
  - Nút “+” hoặc “−”.
  - Hoặc nhập trực tiếp số lượng.
- Nếu sản phẩm đã được thay đổi số lượng:
  - Hệ thống kiểm tra tồn kho ngay lập tức.
  - Nếu số lượng mới vượt quá tồn kho:
    - Không cho phép tăng thêm.
    - Hiển thị ô số lượng bằng màu đỏ.
    - Thông báo: "Số lượng vượt quá tồn kho hiện tại."
- Cho phép xóa sản phẩm khỏi đơn.
- Tổng tiền được cập nhật tự động theo thời gian thực mỗi khi có thay đổi trong đơn hàng.
- Có nút "Làm mới đơn hàng" để xóa toàn bộ và bắt đầu lại nếu cần.

User story 4: Thêm thông tin khách hàng vào đơn hàng
Là một nhân viên bán hàng,
Tôi muốn nhập hoặc chọn thông tin khách hàng (nếu có) sau khi đã chọn sản phẩm,
Để đơn hàng có thể lưu kèm thông tin khách hàng nhằm phục vụ chăm sóc, ưu đãi hoặc hỗ trợ sau này.

Acceptance Criteria:
- Màn hình hiển thị các trường thông tin của khách hàng bao gồm:
  - Số điện thoại 
  - Họ và tên 
  - Giới tính 
  - Ngày sinh 
  - Địa chỉ 
  - Ghi chú 
- Nhân viên bán hàng nhập số điện thoại khách hàng vào trường tương ứng:
  - Nếu số điện thoại đã tồn tại trong hệ thống => Hệ thống tự động điền đầy đủ các trường thông tin khách hàng còn lại dựa trên dữ liệu đã lưu.
  - Nếu số điện thoại chưa tồn tại trong hệ thống => Nhân viên bán hàng nhập thủ công các trường thông tin còn lại (trong đó trường tên và bắt buộc) sau đó hệ thống tự động lưu thông tin khách hàng mới.

User Story 7: Áp dụng giảm giá cho từng sản phẩm
Là một nhân viên bán hàng,
Tôi muốn áp dụng giảm giá cho từng sản phẩm riêng lẻ trong đơn hàng,
Để tôi có thể linh hoạt về giá bán với từng khách hàng hoặc từng tình huống cụ thể.
Acceptance Criteria:
- Nhân viên bán hàng có thể chọn 1 trong 3 cách sau để áp dụng giảm giá:
  1. Nhập số % giảm giá
  2. Nhập số tiền giảm giá (amount)
  3. Nhập trực tiếp giá bán cuối cùng
- Nếu người dùng nhập giá cuối cùng ⇒ hệ thống tự động tính ngược lại % hoặc amount và hiển thị ra.
- Nếu người dùng nhập % hoặc amount ⇒ hệ thống tự động tính và cập nhật giá bán cuối cùng của sản phẩm.
- Chỉ cho phép nhập 1 trong 3 giá trị tại cùng một thời điểm (nếu nhập giá bán cuối cùng thì 2 trường còn lại sẽ bị làm mờ hoặc disabled, và ngược lại).
- Giá bán cuối cùng không được nhỏ hơn 0.
- Tổng tiền của đơn hàng được cập nhật theo giá sau giảm của từng sản phẩm.
- Nếu sản phẩm đã có giảm giá, cần hiển thị icon/tag (ví dụ: “Giảm giá”) bên cạnh tên sản phẩm trong danh sách đơn hàng.
- Cho phép bỏ giảm giá đã áp dụng để quay về giá gốc.

---
User Story 8: Áp dụng giảm giá cho toàn bộ đơn hàng
Là một nhân viên bán hàng,
Tôi muốn áp dụng giảm giá cho toàn bộ đơn hàng,
Để tôi có thể đưa ra mức giá tổng ưu đãi cho khách mua số lượng lớn hoặc trong các chương trình khuyến mãi.
Acceptance Criteria:
- Cho phép áp dụng giảm giá theo:
  1. % tổng giá trị đơn hàng
  2. Số tiền cụ thể (amount)
  3. Hoặc nhập giá trị thanh toán cuối cùng cho đơn hàng (hệ thống tự động tính số tiền giảm tương ứng).
- Nếu nhập % giảm hoặc amount ⇒ app tự động tính ra giá thanh toán sau giảm.
- Nếu nhập giá cuối cùng ⇒ app tự động tính ngược ra amount và % giảm.
- Không cho phép giảm giá vượt quá tổng tiền đơn hàng (ví dụ: tổng là 500.000 thì không thể giảm 600.000).
- Khi áp dụng giảm giá cho toàn bộ đơn hàng, tổng tiền hiển thị ở phần cuối sẽ được cập nhật theo giá trị đã giảm.
- Có thể kết hợp cả giảm giá từng sản phẩm và giảm giá toàn đơn hàng, nhưng hệ thống cần đảm bảo hiển thị rõ ràng mức giảm ở từng cấp độ để tránh nhầm lẫn.
- Cho phép xoá giảm giá đã áp dụng với một nút "Bỏ giảm giá".
User story 7: Thanh toán đơn hàng
Là một nhân viên bán hàng,
Tôi muốn xác nhận thanh toán của một đơn hàng,
để tôi có thể hoàn tất giao dịch và lưu lại hóa đơn.

Acceptance Criteria:
- Cho phép lựa chọn phương thức thanh toán giữa chuyển khoản và tiền mặt
- Trường hợp người bán hàng chọn tiền mặt => App hiển thị thanh toán thành công và hiển thị hoá đơn => tự động lưu trữ hoá đơn
- Trường hợp người bán hàng chọn chuyển khoản => App hiển thị mã QR với số tiền tương ứng => Khi người dùng chuyển khoản thành công => Hiển thị Popup "thanh toán thành công" => Hiển thị hoá đơn => tự động lưu trữ hoá đơn

User story 8: Huỷ đơn hàng
Với vai trò là nhân viên bán hàng,
Tôi muốn huỷ đơn hàng trước khi thanh toán,
để có thể loại bỏ những giao dịch không mong muốn.

Acceptance Criteria:
- Chỉ được phép hủy đơn hàng khi chưa thực hiện thanh toán.
- Nhân viên bán hàng nhấn vào nút “Hủy đơn” từ màn hình đơn hàng.
- Hệ thống hiển thị popup xác nhận với nội dung: “Bạn có chắc chắn muốn hủy đơn hàng này không?” và hai lựa chọn: “Hủy đơn” và “Quay lại”.
- Nếu người dùng xác nhận:
  - Hệ thống hiển thị thông báo: “Đơn hàng đã được hủy.”
  - Toàn bộ sản phẩm trong đơn hàng bị xóa.
  - Trạng thái đơn hàng trở về trạng thái rỗng.
- Nếu người dùng chọn “Quay lại”, hệ thống không thực hiện hành động nào.

Epic 2: Xuất file đơn hàng cuối ngày
User story 7: Xuất file đơn hàng cuối ngày
Là một Kế toán,
Tôi muốn xuất tất cả các đơn hàng đã hoàn tất trong khoảng thời gian cụ thể,
để tôi có thể tính thuế và thực hiện công việc ghi sổ kế toán.

Acceptance Criteria:
- Chọn khoảng thời gian để xuất file; Cho phép chọn nhanh các mốc thời gian phổ biến: "Hôm nay", "Hôm qua", "7 ngày qua", "Tháng này", "Tuỳ chọn". (Với "Tuỳ chọn", hệ thống hiển thị giao diện chọn ngày bắt đầu và kết thúc.)
- Cho phép xuất ra định dạng Excel (hoặc CSV).
- File bao gồm: mã đơn, khách hàng, tổng tiền, ngày giờ.
- Nếu không có đơn hàng trong khoảng thời gian đã chọn, hiển thị popup: “Không có đơn hàng nào trong khoảng thời gian này.”

Epic 3: Thêm sản phẩm mới và chỉnh sửa thông tin sản phẩm 
User story 7: Thêm sản phẩm mới
Là một chủ cửa hàng,
Tôi muốn thêm sản phẩm mới vào hệ thống,
để nhân viên bán hàng có thể bán chúng tại quầy.
Acceptance Criteria:
- Cho phép nhập các trường: tên sản phẩm, mã sản phẩm, giá bán, đơn vị tính và số lượng tồn kho. (Tất cả trường này đều là bắt buộc)
- Nếu không nhập mã sản phẩm, hệ thống tự động tạo mã.
- Kiểm tra trùng mã trước khi lưu:
  - Nếu mã đã tồn tại, hiển thị cảnh báo: "Mã sản phẩm đã tồn tại."
- Sau khi lưu thành công, sản phẩm có thể được tìm kiếm và bán ngay tại quầy.

User story 8: Chỉnh sửa thông tin sản phẩm 
Là một Chủ cửa hàng,
Tôi muốn chỉnh sửa thông tin sản phẩm,
để hệ thống phản ánh mới và chính xác nhất của sản phẩm.

Acceptance Criteria:
- Có thể chỉnh sửa các trường: tên sản phẩm, giá bán, tồn kho, đơn vị tính.
- Thay đổi được cập nhật theo thời gian thực cho tất cả các thiết bị đang hoạt động.
