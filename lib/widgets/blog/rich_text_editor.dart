// lib/widgets/blog/rich_text_editor.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class RichTextEditor extends StatefulWidget {
  final String initialContent;
  final Function(String) onContentChanged;
  final double height;

  const RichTextEditor({
    super.key,
    this.initialContent = '',
    required this.onContentChanged,
    this.height = 300,
  });

  @override
  _RichTextEditorState createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  late quill.QuillController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    if (widget.initialContent.isEmpty) {
      _controller = quill.QuillController.basic();
    } else {
      try {
        // Try to parse the content as Quill Delta JSON
        final doc = quill.Document.fromJson(jsonDecode(widget.initialContent));
        _controller = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        // If parsing fails, treat it as plain text
        _controller = quill.QuillController(
          document: quill.Document.fromPlainText(widget.initialContent),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    }

    // Listen for changes
    _controller.document.changes.listen((event) {
      final json = jsonEncode(_controller.document.toDelta().toJson());
      widget.onContentChanged(json);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Editor toolbar
        quill.QuillToolbar.basic(
          controller: _controller,
          multiRowsDisplay: false,
          showAlignmentButtons: true,
          showBackgroundColorButton: true,
          showColorButton: true,
          showHeaderStyle: true,
          showListCheck: true,
          showSearchButton: true,
          showSubscript: true,
          showSuperscript: true,
          showInlineCode: true,
          showQuote: true,
          showIndent: true,
          showLink: true,
          showDirection: false,
          showFontFamily: false,
        ),
        
        const SizedBox(height: 8),
        
        // Editor area
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: quill.QuillEditor(
            controller: _controller,
            scrollController: ScrollController(),
            scrollable: true,
            focusNode: _focusNode,
            autoFocus: false,
            readOnly: false,
            placeholder: 'Enter post content here...',
            expands: true,
            padding: const EdgeInsets.all(8),
            // Remove embedBuilders
          ),
        ),
      ],
    );
  }
}