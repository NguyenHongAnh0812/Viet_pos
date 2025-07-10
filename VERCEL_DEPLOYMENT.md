# Vercel Deployment Guide

## Cấu hình hiện tại

Dự án đã được cấu hình để deploy lên Vercel với đầy đủ assets:

### Files đã tạo:
- `vercel.json` - Cấu hình Vercel
- `build.sh` - Script build tự động
- `.vercelignore` - Loại trừ files không cần thiết

### Cấu hình Assets:
Assets được khai báo trong `pubspec.yaml`:
```yaml
assets:
  - assets/icons/
  - assets/icons/new_icon/
  - assets/images/
```

## Các bước deploy:

1. **Commit và push code:**
   ```bash
   git add .
   git commit -m "Add Vercel configuration with assets"
   git push origin main
   ```

2. **Trên Vercel Dashboard:**
   - Connect repository
   - Framework: Flutter
   - Build Command: `chmod +x build.sh && ./build.sh`
   - Output Directory: `build/web`
   - Install Command: `flutter pub get`

3. **Kiểm tra deployment:**
   - Vercel sẽ tự động build và deploy
   - Kiểm tra logs để đảm bảo assets được include
   - Test các icon và hình ảnh trên website

## Troubleshooting:

### Nếu assets không hiển thị:
1. Kiểm tra console browser để xem lỗi
2. Verify rằng assets được copy vào `build/web/assets/`
3. Kiểm tra network tab để xem requests assets

### Nếu build fail:
1. Kiểm tra Vercel logs
2. Đảm bảo Flutter SDK được cài đặt trên Vercel
3. Kiểm tra `pubspec.yaml` có đúng syntax

## Cấu trúc Assets:
```
assets/
├── icons/
│   ├── add.svg
│   ├── databoard.svg
│   ├── inventory.svg
│   ├── list_products.svg
│   ├── menu.svg
│   ├── order.svg
│   ├── products.svg
│   ├── report.svg
│   ├── sale.svg
│   ├── setting.svg
│   ├── supplier.svg
│   ├── tag_icon.svg
│   ├── user.svg
│   └── new_icon/
│       ├── cart.svg
│       ├── companies.svg
│       ├── favorite.svg
│       ├── other.svg
│       ├── overview.svg
│       ├── product.svg
│       └── sell.svg
├── images/
│   └── logo.png
└── ckeditor5_editor.html
``` 