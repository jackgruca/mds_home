// lib/widgets/blog/markdown_renderer.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownRenderer extends StatelessWidget {
  final String content;
  final bool isRichContent;

  const MarkdownRenderer({
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

    // Render as Markdown
    return Markdown(
      data: content,
      selectable: true,
      onTapLink: (text, href, title) {
        if (href != null) {
          launchUrl(Uri.parse(href));
        }
      },
    );
  }
}