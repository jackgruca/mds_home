// lib/widgets/blog/simple_rich_text_editor.dart
import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';

class SimpleRichTextEditor extends StatefulWidget {
  final String initialContent;
  final Function(String) onContentChanged;
  final double height;

  const SimpleRichTextEditor({
    super.key,
    this.initialContent = '',
    required this.onContentChanged,
    this.height = 400,
  });

  @override
  State<SimpleRichTextEditor> createState() => _SimpleRichTextEditorState();
}

class _SimpleRichTextEditorState extends State<SimpleRichTextEditor> {
  late HtmlEditorController controller;

  @override
  void initState() {
    super.initState();
    controller = HtmlEditorController();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: HtmlEditor(
        controller: controller,
        htmlEditorOptions: HtmlEditorOptions(
          hint: 'Start typing...',
          initialText: widget.initialContent,
        ),
        callbacks: Callbacks(
          onChangeContent: (String? changed) {
            if (changed != null) {
              widget.onContentChanged(changed);
            }
          },
        ),
      ),
    );
  }
}