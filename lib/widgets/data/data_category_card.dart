// lib/widgets/data/data_category_card.dart
import 'package:flutter/material.dart';
import '../../models/data_category.dart';

class DataCategoryCard extends StatefulWidget {
  final DataCategory category;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(bool) onSelect;

  const DataCategoryCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
    required this.onSelect,
  });

  @override
  State<DataCategoryCard> createState() => _DataCategoryCardState();
}

class _DataCategoryCardState extends State<DataCategoryCard>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovering = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovering = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _isHovering
                        ? widget.category.color.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: _isHovering ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: _buildCardContent(isDarkMode),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardContent(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: widget.isSelected
            ? Border.all(
                color: widget.category.color,
                width: 2,
              )
            : Border.all(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                width: 1,
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and selection checkbox
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.category.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.category.icon,
                  color: widget.category.color,
                  size: 28,
                ),
              ),
              const Spacer(),
              Checkbox(
                value: widget.isSelected,
                onChanged: (value) => widget.onSelect(value ?? false),
                activeColor: widget.category.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Category name
          Text(
            widget.category.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Category description
          Text(
            widget.category.description,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          const Spacer(),
          
          // Field count and examples
          _buildFieldsPreview(isDarkMode),
          
          const SizedBox(height: 16),
          
          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isHovering
                    ? widget.category.color
                    : widget.category.color.withValues(alpha: 0.1),
                foregroundColor: _isHovering
                    ? Colors.white
                    : widget.category.color,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Explore ${widget.category.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldsPreview(bool isDarkMode) {
    final previewFields = widget.category.fields.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.category.fields.length} fields available',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: widget.category.color,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: previewFields.map((field) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black12 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                field.replaceAll('_', ' '),
                style: TextStyle(
                  fontSize: 10,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            );
          }).toList()
            ..addAll([
              if (widget.category.fields.length > 3)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.category.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+${widget.category.fields.length - 3} more',
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.category.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ]),
        ),
      ],
    );
  }
}