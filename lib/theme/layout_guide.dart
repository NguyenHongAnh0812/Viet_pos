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
    super.key,
    required this.title,
    required this.child,
    this.onBack,
    this.actions,
  });

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
  const ExampleStandardScreen({super.key});

  void _showProductSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductSearchSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      floatingActionButton: FloatingActionButton(
        backgroundColor: mainGreen,
        elevation: 8,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white, size: 32),
        shape: const CircleBorder(),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading xanh, chữ trắng
            Container(
              color: mainGreen,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Tiêu đề màn hình',
                      style: h2Mobile.copyWith(color: Colors.white),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () => _showProductSearchSheet(context),
                  ),
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
                            Text('Item', style: h3Mobile),
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
          ],
        ),
      ),
    );
  }
}

// Widget search sản phẩm (bottom sheet)
class _ProductSearchSheet extends StatefulWidget {
  const _ProductSearchSheet();
  @override
  State<_ProductSearchSheet> createState() => _ProductSearchSheetState();
}
class _ProductSearchSheetState extends State<_ProductSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  List<String> _results = [];
  bool _loading = false;

  void _onChanged() async {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    // Giả lập kết quả
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() {
      _results = List.generate(3, (i) => 'Sản phẩm tìm được $i: $query');
      _loading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.98,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Tìm kiếm sản phẩm...',
                        border: InputBorder.none,
                      ),
                      onChanged: (val) => _onChanged(),
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _results = []);
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else if (_results.isEmpty && _controller.text.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('Không tìm thấy sản phẩm phù hợp', style: TextStyle(color: Colors.grey)),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = _results[index];
                    return ListTile(
                      title: Text(p),
                      onTap: () => Navigator.of(context).pop(),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
} 