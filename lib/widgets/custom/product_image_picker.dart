import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class ProductImagePicker extends StatefulWidget {
  final List<File> initialFiles;
  final List<Uint8List> initialWebImages;
  final List<String> initialUrls;
  final int mainImageIndex;
  final int maxImages;
  final void Function(List<File> files, List<Uint8List> webImages, List<String> urls, int mainIndex) onChanged;
  final Future<List<String>> Function(List<File> files, List<Uint8List> webImages) onUploadImages;
  final bool enabled;
  const ProductImagePicker({
    super.key,
    this.initialFiles = const [],
    this.initialWebImages = const [],
    this.initialUrls = const [],
    this.mainImageIndex = 0,
    this.maxImages = 5,
    required this.onChanged,
    required this.onUploadImages,
    this.enabled = true,
  });

  @override
  State<ProductImagePicker> createState() => _ProductImagePickerState();
}

class _ProductImagePickerState extends State<ProductImagePicker> {
  late List<File> _files;
  late List<Uint8List> _webImages;
  late List<String> _urls;
  late int _mainIndex;
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _files = List<File>.from(widget.initialFiles);
    _webImages = List<Uint8List>.from(widget.initialWebImages);
    _urls = List<String>.from(widget.initialUrls);
    _mainIndex = widget.mainImageIndex;
  }

  void _notifyChange() {
    widget.onChanged(_files, _webImages, _urls, _mainIndex);
  }

  int get _totalCount => (kIsWeb ? _webImages.length : _files.length) + _urls.length;

  void _removeAt(int index) {
    setState(() {
      if (kIsWeb && _webImages.isNotEmpty && index < _webImages.length) {
        _webImages.removeAt(index);
      } else if (!kIsWeb && _files.isNotEmpty && index < _files.length) {
        _files.removeAt(index);
      } else if (_urls.isNotEmpty) {
        int urlIdx = index - (kIsWeb ? _webImages.length : _files.length);
        if (urlIdx >= 0 && urlIdx < _urls.length) {
          _urls.removeAt(urlIdx);
        }
      }
      if (_mainIndex >= _totalCount) {
        _mainIndex = 0;
      }
      _notifyChange();
    });
  }

  void _setMain(int index) {
    setState(() {
      _mainIndex = index;
      _notifyChange();
    });
  }

  Future<void> _pickMultiImageFromGallery() async {
    if (!widget.enabled) return;
    if (_totalCount >= widget.maxImages) return;
    
    if (kIsWeb) {
      // Web: use image_picker for web as well
      final pickedFiles = await _picker.pickMultiImage(imageQuality: 80);
      if (pickedFiles.isNotEmpty) {
        int remain = widget.maxImages - _totalCount;
        setState(() {
          // For web, we'll convert to Uint8List
          for (final pickedFile in pickedFiles.take(remain)) {
            pickedFile.readAsBytes().then((bytes) {
              setState(() {
                _webImages.add(bytes);
                _notifyChange();
              });
            });
          }
        });
      }
    } else {
      // Mobile: sử dụng image_picker
      final pickedFiles = await _picker.pickMultiImage(imageQuality: 80);
      if (pickedFiles.isNotEmpty) {
        int remain = widget.maxImages - _totalCount;
        setState(() {
          _files.addAll(pickedFiles.take(remain).map((e) => File(e.path)));
          _notifyChange();
        });
      }
    }
  }

  Widget _buildGridImage(Widget image, {required VoidCallback onRemove, required bool isMain, required VoidCallback onSetMain}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFF3F4F6),
            child: image,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
              ),
              child: const Icon(Icons.close, size: 18, color: Colors.red),
            ),
          ),
        ),
        if (isMain)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Chính', style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
          )
        else
          Positioned(
            bottom: 4,
            left: 4,
            child: GestureDetector(
              onTap: onSetMain,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: const Icon(Icons.star_border, color: Colors.orange, size: 14),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGridAddButton() {
    return GestureDetector(
      onTap: _pickMultiImageFromGallery,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: Icon(Icons.add_a_photo, size: 36, color: Color(0xFF9CA3AF)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> imageWidgets = [];
    int localImageCount = 0;
    if (kIsWeb && _webImages.isNotEmpty) {
      for (int i = 0; i < _webImages.length; i++) {
        imageWidgets.add(_buildGridImage(
          Image.memory(_webImages[i], fit: BoxFit.cover),
          onRemove: () => _removeAt(i),
          isMain: _mainIndex == i,
          onSetMain: () => _setMain(i),
        ));
        localImageCount++;
      }
    } else if (!kIsWeb && _files.isNotEmpty) {
      for (int i = 0; i < _files.length; i++) {
        imageWidgets.add(_buildGridImage(
          Image.file(_files[i], fit: BoxFit.cover),
          onRemove: () => _removeAt(i),
          isMain: _mainIndex == i,
          onSetMain: () => _setMain(i),
        ));
        localImageCount++;
      }
    }
    for (int i = 0; i < _urls.length; i++) {
      int idx = localImageCount + i;
      imageWidgets.add(_buildGridImage(
        Image.network(_urls[i], fit: BoxFit.cover),
        onRemove: () => _removeAt(idx),
        isMain: _mainIndex == idx,
        onSetMain: () => _setMain(idx),
      ));
    }
    final canAddMore = _totalCount < widget.maxImages;
    if (canAddMore) {
      imageWidgets.add(_buildGridAddButton());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ảnh sản phẩm', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.green)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          physics: const NeverScrollableScrollPhysics(),
          children: imageWidgets,
        ),
      ],
    );
  }
} 