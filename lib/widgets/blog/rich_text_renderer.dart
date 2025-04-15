// lib/widgets/blog/rich_text_renderer.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class RichTextRenderer extends StatefulWidget {
  final String content;
  final bool isRichContent;

  const RichTextRenderer({
    super.key,
    required this.content,
    this.isRichContent = false,
  });

  @override
  _RichTextRendererState createState() => _RichTextRendererState();
}

class _RichTextRendererState extends State<RichTextRenderer> {
  late quill.QuillController _controller;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    if (!widget.isRichContent || widget.content.isEmpty) {
      // Handle as plain text
      _controller = quill.QuillController(
        document: quill.Document.fromPlainText(widget.content),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else {
      try {
        // Try to parse the content as Quill Delta JSON
        final doc = quill.Document.fromJson(jsonDecode(widget.content));
        _controller = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        // Fallback to plain text if parsing fails
        _controller = quill.QuillController(
          document: quill.Document.fromPlainText(widget.content),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    }
  }

  @override
  void didUpdateWidget(RichTextRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content || 
        oldWidget.isRichContent != widget.isRichContent) {
      _initializeController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return quill.QuillEditor(
      controller: _controller,
      scrollController: ScrollController(),
      scrollable: true,
      focusNode: FocusNode(),
      autoFocus: false,
      readOnly: true,
      expands: false,
      padding: EdgeInsets.zero,
      // Remove embedBuilders
    );
  }
}