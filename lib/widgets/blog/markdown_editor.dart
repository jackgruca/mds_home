// lib/widgets/blog/markdown_editor.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownEditor extends StatefulWidget {
  final String initialContent;
  final Function(String) onContentChanged;
  final double height;

  const MarkdownEditor({
    super.key,
    this.initialContent = '',
    required this.onContentChanged,
    this.height = 400,
  });

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late TextEditingController _controller;
  final ScrollController _scrollController = ScrollController();
  bool _isPreview = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
    _controller.addListener(() {
      widget.onContentChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          child: Row(
            children: [
              // Bold
              IconButton(
                icon: const Icon(Icons.format_bold),
                tooltip: 'Bold',
                onPressed: () => _insertMarkdown('**', '**', 'bold text'),
                iconSize: 20,
              ),
              // Italic
              IconButton(
                icon: const Icon(Icons.format_italic),
                tooltip: 'Italic',
                onPressed: () => _insertMarkdown('*', '*', 'italic text'),
                iconSize: 20,
              ),
              // Header
              IconButton(
                icon: const Icon(Icons.title),
                tooltip: 'Heading',
                onPressed: () => _insertMarkdown('## ', '', 'Heading'),
                iconSize: 20,
              ),
              // Link
              IconButton(
                icon: const Icon(Icons.link),
                tooltip: 'Link',
                onPressed: () => _insertMarkdown('[', '](https://example.com)', 'link text'),
                iconSize: 20,
              ),
              // List
              IconButton(
                icon: const Icon(Icons.format_list_bulleted),
                tooltip: 'Bullet List',
                onPressed: () => _insertMarkdown('- ', '', 'List item'),
                iconSize: 20,
              ),
              // Quote
              IconButton(
                icon: const Icon(Icons.format_quote),
                tooltip: 'Quote',
                onPressed: () => _insertMarkdown('> ', '', 'Quote'),
                iconSize: 20,
              ),
              // Code
              IconButton(
                icon: const Icon(Icons.code),
                tooltip: 'Code',
                onPressed: () => _insertMarkdown('`', '`', 'code'),
                iconSize: 20,
              ),
              const Spacer(),
              // Preview toggle
              TextButton.icon(
                icon: Icon(_isPreview ? Icons.edit : Icons.visibility),
                label: Text(_isPreview ? 'Edit' : 'Preview'),
                onPressed: () {
                  setState(() {
                    _isPreview = !_isPreview;
                  });
                },
              ),
            ],
          ),
        ),
        
        // Editor area
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
          ),
          child: _isPreview
              ? Markdown(
                  data: _controller.text,
                  selectable: true,
                  controller: _scrollController,
                )
              : TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: 'Type your content in Markdown format...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(8),
                  ),
                ),
        ),
        
        // Help text
        if (!_isPreview)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Use Markdown for formatting: **bold**, *italic*, ## headings, [links](url), - lists, > quotes',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  // Helper to insert Markdown syntax at cursor position
  void _insertMarkdown(String prefix, String suffix, String placeholder) {
    final text = _controller.text;
    final selection = _controller.selection;
    
    // Get the selected text or use placeholder
    final selectedText = selection.textInside(text).isNotEmpty
        ? selection.textInside(text)
        : placeholder;
    
    // Create the new text with markdown
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$prefix$selectedText$suffix',
    );
    
    // Update the controller
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + prefix.length + selectedText.length + suffix.length,
      ),
    );
  }
}