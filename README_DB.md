# Database Structure: Product Table

| Field Name         | Data Type         | Description                                                        |
|--------------------|------------------|--------------------------------------------------------------------|
| id                 | UUID / Integer   | Product unique identifier                                          |
| trade_name         | String           | Trade name (displayed)                                             |
| internal_name      | String           | Internal name for management                                       |
| barcode            | String           | Product barcode                                                    |
| sku                | String           | Product SKU                                                        |
| ingredients        | Text             | Ingredients                                                        |
| usage              | Text             | Usage                                                              |
| description        | Text             | Product detailed description                                       |
| tags               | Array[String]    | Tags                                                               |
| cost_price         | Decimal          | Cost price (purchase price)                                        |
| sale_price         | Decimal          | Sale price                                                         |
| grcss_profit       | Decimal          | Gross profit (difference between sale and cost price)              |
| auto_price         | Boolean          | Auto-calculate sale price by gross profit                          |
| stock_system       | Integer          | Current stock quantity                                             |
| stock_invoice      | Integer          | Invoice stock quantity                                             |
| status             | Enum             | Product status (active/inactive/discontinued)                      |
| discontinue_reason | Text (optional)  | Discontinue reason (if any)                                        |
| notes              | Text (optional)  | Additional notes                                                   |
| image_url          | String (optional)| Product image                                                      |
| unit               | String (optional)| Unit (box, bottle, tablet, ...)                                    |
| created_at         | Timestamp        | Created time                                                       |
| updated_at         | Timestamp        | Last updated time                                                  |

## Table: categories
| Field Name | Data Type | Description                                  |
|------------|-----------|----------------------------------------------|
| id         | String    | Category ID (Firestore auto or custom)       |
| name       | String    | Category name                                |
| parent_id  | String/null| Parent category ID (if any)                  |
| level      | Integer   | Category level (0: root, 1: child, ...)      |
| description| String    | Description                                  |
| created_at | Timestamp | Created date                                 |
| updated_at | Timestamp | Updated date                                 |

## Table: product_category
| Field Name | Data Type | Description                                  |
|------------|-----------|----------------------------------------------|
| product_id | String    | Product ID                                   |
| category_id| String    | Category ID                                  |
| created_at | Timestamp | Record created date                          |

## Table: customer
| Field Name        | Data Type | Description                              |
|------------------|-----------|------------------------------------------|
| id               | UUID      | Unique customer ID                       |
| name             | string    | Full name                                |
| gender           | enum      | Male / Female / Other                    |
| birthaday        | date      | Birthday                                 |
| phone            | string    | Phone number                             |
| email            | string    | Email address                            |
| address          | string    | Contact address                          |
| discount         | number    | % discount (if any)                      |
| tax_code         | string    | Tax identification number                |
| tags             | array     | Optional tags                            |
| company_id       | UUID      | FK to associated company                 |
| customer_group_id| UUID      | Customer group                           |
| loyalty_point    | number    | Loyalty points                           |
| debt             | number    | Current debt                             |

## Table: customer_group
| Field Name | Data Type | Description                  |
|------------|-----------|------------------------------|
| id         | UUID      | Unique group ID              |
| name       | string    | Group name                   |
| note       | text      | Notes                        |

## Table: company
| Field Name    | Data Type | Description                        |
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
| created_at    | Timestamp | Created time                       |
| updated_at    | Timestamp | Updated time                       |

## Table: product_company
| Field Name | Data Type      | Description                                                    |
|------------|---------------|----------------------------------------------------------------|
| product_id | UUID / Integer| FK to product table                                            |
| company_id | UUID / Integer| FK to company table (if company is_supplier = true)            |
| created_at | Timestamp     | Linked date                                                    |

## Table: order
| Field Name         | Data Type | Description                                                                 |
|--------------------|-----------|-----------------------------------------------------------------------------|
| id                 | UUID      | Unique order ID                                                             |
| serial             | string    | Order serial (e.g., PO-00001)                                               |
| invoice_number     | string    | Invoice number                                                              |
| created_date       | date      | Order creation date                                                         |
| sub_total          | number    | Total before tax and discount                                               |
| total_discounts    | number    | Total discounts applied                                                     |
| tax                | number    | Tax amount                                                                  |
| total              | number    | Grand total                                                                 |
| payment_option     | string    | e.g., Bank transfer, Cash, etc.                                             |
| customer_id        | UUID      | Optional (in case of supplier as customer)                                  |
| company_id         | UUID      | Associated company                                                          |
| discounts          | string    | Discount text or rules                                                      |
| item_count         | number    | Total number of items                                                       |
| order_items_list   | array     | JSON array of order_items                                                   |
| financial_status   | enum      | authorized / expired / paid / partially_paid / partially_refunded / pending / refunded / unpaid / voided |
| status             | enum      | completed / canceled                                                        |
| order_type         | enum      | sale / purchase / return / ...                                              |
| created_by         | UUID      | User who created the order                                                  |
| note               | text      | Order notes                                                                 |
| shipping_info      | string    | Shipping information (JSON/text)                                            |
| payment_status     | enum      | paid / unpaid / partial / ... (if separated)                                |

## Table: order_item
| Field Name           | Data Type | Description                        |
|---------------------|-----------|------------------------------------|
| id                  | UUID      | Unique item ID                     |
| order_id            | UUID      | Foreign key to order               |
| product_id          | string    | FK to associated product           |
| quantity            | number    | Quantity ordered                   |
| price               | number    | Unit price                         |
| sub_total           | number    | quantity x price                   |
| discount_amount     | number    | Discount on this item              |
| tax_rate            | number    | Tax %                              |
| taxable             | boolean   | Is this item taxable?              |
| total               | number    | Final total after discount and tax |
| unit                | string    | Unit                               |
| product_name_snapshot| string   | Product name at the time of sale   |
| vat_amount          | number    | VAT amount                         |

## Table: discount
| Field Name         | Data Type | Description                                      |
|--------------------|-----------|--------------------------------------------------|
| id                 | UUID      | Discount ID                                      |
| name               | string    | Promotion name                                   |
| code               | string    | Discount code (if any)                           |
| type               | enum      | amount / percent / gift_product                  |
| value              | number    | Discount value or percent                        |
| gift_product_id    | UUID/null | Gift product (if type = gift)                    |
| apply_scope        | enum      | order / product / category                       |
| applied_products   | array     | List of applied products (if type = product)     |
| applied_categories | array     | List of applied categories                       |
| customer_ids       | array     | List of applied customers                        |
| customer_group_ids | array     | List of applied customer groups                  |
| company_ids        | array     | List of applied companies                        |
| min_order_value    | number    | Minimum order value (if any)                     |
| start_time         | datetime  | Start time                                       |
| end_time           | datetime  | End time                                         |
| status             | enum      | active / inactive / scheduled                    |
| description        | text      | Promotion notes                                  |
| created_at         | datetime  | Created date                                     |
| is_auto            | boolean   | Auto apply or require code                       |
| max_uses           | number    | Maximum uses                                     |
| used_count         | number    | Used count                                       |

## Table: payment
| Field Name | Data Type | Description                  |
|------------|-----------|------------------------------|
| id         | UUID      | Unique payment ID            |
| order_id   | UUID      | FK to order table            |
| amount     | number    | Payment amount               |
| method     | string    | Payment method (cash, bank,...) |
| paid_at    | datetime  | Payment date                 |
| note       | text      | Notes                        | 