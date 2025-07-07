import 'package:flutter/material.dart';
import '../widgets/common/design_system.dart';

/// Màn hình chuẩn hóa layout cho toàn bộ app
/// - Heading lớn, icon back
/// - Padding đồng bộ
/// - Block nội dung bo góc, border, nền trắng
/// - Text style, button style theo design_system.dart
class StandardScreenLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const StandardScreenLayout({
    Key? key,
    required this.title,
    required this.child,
    this.onBack,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: textPrimary),
                      onPressed: onBack,
                    ),
                  Expanded(
                    child: Text(
                      title,
                      style: h2Mobile,
                      textAlign: TextAlign.left,
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
            Container(
              height: 1,
              color: borderColor,
            ),
            // Body
            Expanded(
              child: Container(
                color: appBackground,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                width: double.infinity,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ví dụ sử dụng màn hình chuẩn
class ExampleStandardScreen extends StatelessWidget {
  const ExampleStandardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      floatingActionButton: FloatingActionButton(
        backgroundColor: mainGreen,
        elevation: 8,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      body: SafeArea(
        child: StandardScreenLayout(
          title: 'Tiêu đề màn hình',
          onBack: () => Navigator.pop(context),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: textPrimary),
              onPressed: () {},
            ),
          ],
          child: ListView.separated(
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Item ${i + 1}', style: h3Mobile),
                      const SizedBox(height: 4),
                      Text('Mô tả ngắn cho item này', style: bodyMobile),
                    ],
                  ),
                  Icon(Icons.chevron_right, color: textSecondary, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 