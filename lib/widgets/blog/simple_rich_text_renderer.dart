// lib/widgets/blog/simple_rich_text_renderer.dart
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class SimpleRichTextRenderer extends StatelessWidget {
  final String content;
  final bool isRichContent;

  const SimpleRichTextRenderer({
    super.key,
    required this.content,
    this.isRichContent = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isRichContent) {
      // Render as plain text
      return Text(
        content,
        style: const TextStyle(
          fontSize: 16,
          height: 1.6,
        ),
      );
    }

    // Render as HTML
    return Html(
      data: content,
      style: {
        "body": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        "p": Style(
          margin: Margins.only(bottom: 16),
        ),
        "h1, h2, h3, h4, h5, h6": Style(
          margin: Margins.only(bottom: 16, top: 24),
        ),
        "ul, ol": Style(
          margin: Margins.only(bottom: 16),
        ),
        "blockquote": Style(
          backgroundColor: Colors.grey.withOpacity(0.1),
          padding: HtmlPaddings.all(16),
          margin: Margins.symmetric(vertical: 16),
          border: const Border(
            left: BorderSide(
              color: Colors.grey,
              width: 4,
            ),
          ),
        ),
      },
    );
  }
}