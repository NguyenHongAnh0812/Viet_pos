import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: undefined_prefixed_name
import 'dart:ui_web' as ui;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class CKEditor5Widget extends StatefulWidget {
  final String? initialContent;
  final void Function(String html)? onContentChanged;
  final void Function(String html)? onAutoSave;
  final void Function(int wordCount)? onWordCountChanged;
  final double? minHeight;
  final double? maxHeight;
  final bool enableAutoSave;
  final Duration autoSaveDelay;
  
  const CKEditor5Widget({
    Key? key, 
    this.initialContent, 
    this.onContentChanged,
    this.onAutoSave,
    this.onWordCountChanged,
    this.minHeight = 200,
    this.maxHeight = 800,
    this.enableAutoSave = true,
    this.autoSaveDelay = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  State<CKEditor5Widget> createState() => _CKEditor5WidgetState();
}

class _CKEditor5WidgetState extends State<CKEditor5Widget> {
  static bool _viewTypeRegistered = false;
  html.IFrameElement? _iframeElement;
  double _currentHeight = 200;
  bool _isEditorReady = false;
  String _lastContent = '';
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _currentHeight = widget.minHeight ?? 200;
    _lastContent = widget.initialContent ?? '';
    if (kIsWeb && !_viewTypeRegistered) {
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        'ckeditor5-editor',
        (int viewId) {
          _iframeElement = html.IFrameElement()
            ..src = '/assets/ckeditor5_editor.html'
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '${_currentHeight}px';
          
          // Listen for messages from iframe
          html.window.addEventListener('message', (event) {
            if (event is html.MessageEvent && event.data is Map) {
              _handleMessage(event.data);
            }
          });
          
          return _iframeElement!;
        },
      );
      _viewTypeRegistered = true;
    }
  }

  void _handleMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    
    switch (type) {
      case 'editorHeightChange':
        final height = data['height'] as num?;
        if (height != null) {
          _updateHeight(height.toDouble());
        }
        break;
        
      case 'editorReady':
        _isEditorReady = true;
        final height = data['height'] as num?;
        if (height != null) {
          _updateHeight(height.toDouble());
        }
        // Set initial content after editor is ready
        if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
          _setContent(widget.initialContent!);
        }
        break;
        
      case 'contentChanged':
        final content = data['content'] as String?;
        if (content != null && content != _lastContent) {
          _lastContent = content;
          widget.onContentChanged?.call(content);
          _updateWordCount(content);
        }
        break;
        
      case 'editorError':
        final error = data['error'] as String?;
        if (error != null) {
          print('CKEditor error: $error');
        }
        break;
    }
  }

  void _updateHeight(double newHeight) {
    if (mounted) {
      setState(() {
        _currentHeight = newHeight.clamp(
          widget.minHeight ?? 200, 
          widget.maxHeight ?? 800
        );
      });
      
      // Update iframe height
      if (_iframeElement != null) {
        _iframeElement!.style.height = '${_currentHeight}px';
      }
    }
  }

  void _setContent(String content) {
    if (_isEditorReady && _iframeElement != null) {
      try {
        // Call JavaScript function to set content
        js.context.callMethod('setCKContent', [content]);
      } catch (e) {
        print('Error setting content: $e');
      }
    }
  }

  void _updateWordCount(String content) {
    if (_isEditorReady && _iframeElement != null) {
      try {
        final wordCount = js.context.callMethod('getWordCount') as int? ?? 0;
        if (wordCount != _wordCount) {
          _wordCount = wordCount;
          widget.onWordCountChanged?.call(_wordCount);
        }
      } catch (e) {
        print('Error getting word count: $e');
      }
    }
  }

  void _focusEditor() {
    if (_isEditorReady && _iframeElement != null) {
      try {
        js.context.callMethod('focusEditor');
      } catch (e) {
        print('Error focusing editor: $e');
      }
    }
  }

  String _getContent() {
    if (_isEditorReady && _iframeElement != null) {
      try {
        return js.context.callMethod('getCKContent') as String? ?? '';
      } catch (e) {
        print('Error getting content: $e');
        return '';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Center(child: Text('Tính năng này chỉ hỗ trợ trên trình duyệt web.'));
    }
    
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _currentHeight,
          child: HtmlElementView(viewType: 'ckeditor5-editor'),
        ),
        if (widget.onWordCountChanged != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Số từ: $_wordCount',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (widget.enableAutoSave)
                  Text(
                    'Tự động lưu sau ${widget.autoSaveDelay.inSeconds}s',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
} 