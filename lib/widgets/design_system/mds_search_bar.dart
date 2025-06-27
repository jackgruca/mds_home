import 'package:flutter/material.dart';
import 'package:mds_home/utils/theme_config.dart';

class MdsSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool enabled;
  final bool showFilter;
  final VoidCallback? onFilterTap;
  final List<String>? suggestions;
  final bool autofocus;

  const MdsSearchBar({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.enabled = true,
    this.showFilter = false,
    this.onFilterTap,
    this.suggestions,
    this.autofocus = false,
  });

  @override
  State<MdsSearchBar> createState() => _MdsSearchBarState();
}

class _MdsSearchBarState extends State<MdsSearchBar> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasFocus 
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.withOpacity(0.3),
          width: _hasFocus ? 2 : 1,
        ),
        boxShadow: _hasFocus ? [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              decoration: InputDecoration(
                hintText: widget.hint ?? 'Search...',
                hintStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: _hasFocus 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
                suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _controller.clear();
                        widget.onClear?.call();
                        widget.onChanged?.call('');
                      },
                    )
                  : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          if (widget.showFilter) ...[
            Container(
              width: 1,
              height: 24,
              color: Colors.grey.withOpacity(0.3),
            ),
            IconButton(
              icon: Icon(
                Icons.tune,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: widget.onFilterTap,
            ),
          ],
        ],
      ),
    );
  }
} 