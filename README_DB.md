# Database Structure: Bảng Product

| Tên trường         | Kiểu dữ liệu         | Mô tả                                                        |
|--------------------|---------------------|--------------------------------------------------------------|
| id                 | UUID / Integer      | Mã định danh sản phẩm                                        |
| trade_name         | String              | Tên thương mại (hiển thị)                                    |
| internal_name      | String              | Tên nội bộ dùng cho quản lý                                  |
| barcode            | String              | Mã barcode sản phẩm                                          |
| sku                | String              | Mã SKU sản phẩm                                              |                                       |
| ingredients        | Text                | Thành phần                                                   |
| usage              | Text                | Công dụng                                                    |
| description        | Text                | Mô tả chi tiết sản phẩm                                      |
| tags               | Array[String]       | Tags                                                         |
| cost_price         | Decimal             | Giá vốn (giá nhập)                                           |
| sale_price         | Decimal             | Giá bán                                                      |
| grcss_profit       | Decimal             | Lợi nhuận gộp (tính theo chênh lệch giá bán và giá vốn)     |
| auto_price         | Boolean             | Tự động tính giá bán theo lợi nhuận gộp                      |
| stock_system     | Integer             | Số lượng tồn kho hiện tại                                    |
| stock_invoice      | Integer             | Số lượng tồn kho hóa đơn                                     |
| status             | Enum                | Trạng thái sản phẩm (active/inactive/discontinued)           |
| discontinue_reason | Text (optional)     | Lý do ngừng bán nếu có                                       |
| notes              | Text (optional)     | Ghi chú thêm                                                 |
| created_at         | Timestamp           | Thời gian tạo                                                |
| updated_at         | Timestamp           | Thời gian cập nhật cuối                                      |

## Bảng: categories
| Tên trường   | Kiểu dữ liệu | Ghi chú                                  |
|--------------|--------------|------------------------------------------|
| id           | String       | ID danh mục (Firestore auto hoặc custom) |
| name         | String       | Tên danh mục                             |
| parent_id    | String/null  | ID danh mục cha (nếu có)                 |
| level        | Integer      | Cấp độ danh mục (0: gốc, 1: con, ...)    |
| description  | String       | Mô tả                                    |
| created_at   | Timestamp    | Ngày tạo                                 |
| updated_at   | Timestamp    | Ngày cập nhật                            |

## Bảng: product_category
| Tên trường   | Kiểu dữ liệu | Ghi chú                                  |
|--------------|--------------|------------------------------------------|
| product_id   | String       | ID sản phẩm                              |
| category_id  | String       | ID danh mục                              |
| created_at   | Timestamp    | Ngày tạo bản ghi                         |

## Bảng: customer (Khách hàng)
| Field      | Type   | Description                  |
|------------|--------|------------------------------|
| id         | UUID   | Unique customer ID           |
| name       | string | Full name                    |
| gender     | enum   | Male / Female / Other        |
| phone      | string | Phone number                 |
| email      | string | Email address                |
| address    | string | Contact address              |
| discount   | number | % discount (if any)          |
| tax_code   | string | Tax identification number    |
| tags       | array  | Optional tags                |
| company_id | UUID   | FK to associated company     |

## Bảng: company (Công ty)
| Field         | Type      | Description                        |
|---------------|-----------|------------------------------------|
| id            | UUID      | Unique company ID                  |
| name          | string    | Company name                       |
| tax_code      | string    | Company tax code                   |
| is_supplier   | boolean   | Whether this company is a supplier |
| address       | string    | Company address                    |
| email         | string    | General contact email              |
| hotline       | number    | Hotline                            |
| main_contact  | string    | Main point-of-contact (text)       |
| website       | string    | Website URL                        |
| bank_account  | string    | Bank account number                |
| bank_name     | string    | Bank name                          |
| payment_term  | string    | e.g., Net 30, Net 60               |
| status        | enum      | Active / Inactive                  |
| tags          | array     | Tags                               |
| note          | text      | Optional notes                     |
| created_at    | Timestamp | Thời gian tạo                      |
| updated_at    | Timestamp | Thời gian cập nhật                 |

## Bảng: product_company
| Field       | Type           | Description                                                    |
|-------------|----------------|----------------------------------------------------------------|
| product_id  | UUID / Integer | FK đến bảng product                                            |
| company_id  | UUID / Integer | FK đến bảng company (nếu company có is_supplier = true)        |
| created_at  | Timestamp      | Ngày liên kết                                                  |

## Bảng: order (Đơn nhập hàng)
| Field             | Type    | Description                                                                 |
|-------------------|---------|-----------------------------------------------------------------------------|
| id                | UUID    | Unique order ID                                                             |
| serial            | string  | Order serial (e.g., PO-00001)                                               |
| invoice_number    | string  | Invoice number                                                              |
| created_date      | date    | Order creation date                                                         |
| sub_total         | number  | Total before tax and discount                                               |
| total_discounts   | number  | Total discounts applied                                                     |
| tax               | number  | Tax amount                                                                  |
| total             | number  | Grand total                                                                 |
| payment_option    | string  | e.g., Bank transfer, Cash, etc.                                             |
| customer_id       | UUID    | Optional (in case of supplier as customer)                                  |
| company_id        | UUID    | Associated company                                                          |
| discounts         | string  | Text or rules for discount                                                  |
| item_count        | number  | Total number of items                                                       |
| order_items_list  | array   | JSON array of order_items                                                   |
| financial_status  | enum    | authorized / expired / paid / partially_paid / partially_refunded / pending / refunded / unpaid / voided |
| status            | enum    | completed / canceled                                                        |

## Bảng: order_item (Chi tiết sản phẩm trong đơn)
| Field           | Type    | Description                        |
|-----------------|---------|------------------------------------|
| id              | UUID    | Unique item ID                     |
| order_id        | UUID    | Foreign key to order               |
| product_id        | string  | FK to associated product           |
| quantity        | number  | Quantity ordered                   |
| price           | number  | Unit price                         |
| sub_total       | number  | quantity x price                   |
| discount_amount | number  | Discount on this item              |
| tax_rate        | number  | Tax %                              |
| taxable         | boolean | Is this item taxable?              |
| total           | number  | Final total after discount and tax |

## Bảng: discount (Khuyến mãi)
| Field              | Type        | Description                                      |
|--------------------|------------|--------------------------------------------------|
| id                 | UUID       | Mã khuyến mãi                                     |
| name               | string     | Tên chương trình khuyến mãi                      |
| code               | string     | Mã áp dụng (nếu có)                              |
| type               | enum       | amount / percent / gift_product                  |
| value              | number     | Số tiền hoặc % giảm                              |
| gift_product_id    | UUID/null  | Sản phẩm được tặng (nếu là gift)                 |
| apply_scope        | enum       | order / product / category                       |
| applied_products   | array      | Danh sách sản phẩm áp dụng (nếu type = product)  |
| applied_categories | array      | Danh sách danh mục áp dụng                       |
| customer_ids       | array      | Danh sách khách hàng áp dụng                     |
| customer_group_ids | array      | Nhóm khách hàng áp dụng                          |
| company_ids        | array      | Danh sách công ty áp dụng                        |
| min_order_value    | number     | Giá trị đơn hàng tối thiểu (nếu có)              |
| start_time         | datetime   | Thời gian bắt đầu                                |
| end_time           | datetime   | Thời gian kết thúc                               |
| status             | enum       | active / inactive / scheduled                    |
| description        | text       | Ghi chú chương trình                             |
| created_at         | datetime   | Ngày tạo                                         | 