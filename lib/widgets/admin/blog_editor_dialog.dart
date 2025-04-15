// lib/widgets/admin/blog_editor_dialog.dart
import 'package:flutter/material.dart';
import '../../models/blog_post.dart';
import '../../services/blog_service.dart';
import '../../utils/theme_config.dart';

class BlogEditorDialog extends StatefulWidget {
  final BlogPost? post;  // Null for new post, non-null for edit
  final Function(BlogPost) onSave;

  const BlogEditorDialog({super.key, this.post, required this.onSave});

  @override
  _BlogEditorDialogState createState() => _BlogEditorDialogState();
}

class _BlogEditorDialogState extends State<BlogEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _authorController;
  late TextEditingController _thumbnailController;
  
  List<String> _allCategories = [];
  List<String> _selectedCategories = [];
  List<String> _tags = [];
  bool _isPublished = false;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _titleController = TextEditingController(text: widget.post?.title ?? '');
    _contentController = TextEditingController(text: widget.post?.content ?? '');
    _authorController = TextEditingController(text: widget.post?.author ?? '');
    _thumbnailController = TextEditingController(text: widget.post?.thumbnailUrl ?? '');
    
    // Initialize selections
    _selectedCategories = widget.post?.categories ?? [];
    _tags = widget.post?.tags ?? [];
    _isPublished = widget.post?.isPublished ?? false;
    
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _authorController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await BlogService.getAllCategories();
      setState(() {
        _allCategories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    }
  }

  void _saveDraft() {
    if (_formKey.currentState?.validate() ?? false) {
      final title = _titleController.text.trim();
      final slug = BlogPost.generateSlug(title);
      
      final post = BlogPost(
        id: widget.post?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: _contentController.text.trim(),
        author: _authorController.text.trim(),
        publishedDate: widget.post?.publishedDate ?? DateTime.now(),
        updatedDate: DateTime.now(),
        thumbnailUrl: _thumbnailController.text.trim().isEmpty ? null : _thumbnailController.text.trim(),
        isPublished: false,  // Always save as draft
        categories: _selectedCategories,
        tags: _tags,
        slug: slug,
        viewCount: widget.post?.viewCount ?? 0,
      );
      
      widget.onSave(post);
      Navigator.of(context).pop();
    }
  }

  void _publishPost() {
    if (_formKey.currentState?.validate() ?? false) {
      final title = _titleController.text.trim();
      final slug = BlogPost.generateSlug(title);
      
      final post = BlogPost(
        id: widget.post?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: _contentController.text.trim(),
        author: _authorController.text.trim(),
        publishedDate: widget.post?.publishedDate ?? DateTime.now(),
        updatedDate: DateTime.now(),
        thumbnailUrl: _thumbnailController.text.trim().isEmpty ? null : _thumbnailController.text.trim(),
        isPublished: true,  // Publish immediately
        categories: _selectedCategories,
        tags: _tags,
        slug: slug,
        viewCount: widget.post?.viewCount ?? 0,
      );
      
      widget.onSave(post);
      Navigator.of(context).pop();
    }
  }

  Widget _buildCategoriesSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allCategories.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(category);
                  } else {
                    _selectedCategories.remove(category);
                  }
                });
              },
            );
          }).toList()..add(
            InputChip(
              label: const Text('+ Add Category'),
              onPressed: () {
                // Show dialog to add new category
                final TextEditingController controller = TextEditingController();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Add New Category'),
                    content: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                      ),
                      autofocus: true,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final newCategory = controller.text.trim();
                          if (newCategory.isNotEmpty && !_allCategories.contains(newCategory)) {
                            setState(() {
                              _allCategories.add(newCategory);
                              _selectedCategories.add(newCategory);
                              _allCategories.sort();
                            });
                          }
                          Navigator.of(context).pop();
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                );
              },
            ) as FilterChip,
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tags.map((tag) {
            return Chip(
              label: Text(tag),
              onDeleted: () {
                setState(() {
                  _tags.remove(tag);
                });
              },
            );
          }).toList()..add(
            InputChip(
              label: const Text('+ Add Tag'),
              onPressed: () {
                // Show dialog to add new tag
                final TextEditingController controller = TextEditingController();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Add New Tag'),
                    content: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Tag Name',
                      ),
                      autofocus: true,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final newTag = controller.text.trim();
                          if (newTag.isNotEmpty && !_tags.contains(newTag)) {
                            setState(() {
                              _tags.add(newTag);
                            });
                          }
                          Navigator.of(context).pop();
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                );
              },
            ) as Chip,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isNewPost = widget.post == null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Text(
                          isNewPost ? 'Create New Blog Post' : 'Edit Blog Post',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Form fields in a scrollable container
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Title',
                                border: OutlineInputBorder(),
                                hintText: 'Enter post title',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a title';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _authorController,
                              decoration: const InputDecoration(
                                labelText: 'Author',
                                border: OutlineInputBorder(),
                                hintText: 'Enter author name',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter an author';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _thumbnailController,
                              decoration: const InputDecoration(
                                labelText: 'Thumbnail URL (optional)',
                                border: OutlineInputBorder(),
                                hintText: 'Enter URL for thumbnail image',
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _contentController,
                              decoration: const InputDecoration(
                                labelText: 'Content',
                                border: OutlineInputBorder(),
                                hintText: 'Enter post content',
                                alignLabelWithHint: true,
                              ),
                              maxLines: 10,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter content';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            _buildCategoriesSection(),
                            const SizedBox(height: 16),
                            
                            _buildTagsSection(),
                            
                            if (!isNewPost) ...[
                              const SizedBox(height:
                                24),
                              Row(
                                children: [
                                  const Text('Status:'),
                                  const SizedBox(width: 8),
                                  Chip(
                                    label: Text(
                                      widget.post!.isPublished ? 'Published' : 'Draft',
                                    ),
                                    backgroundColor: widget.post!.isPublished
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.2),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Views: ${widget.post!.viewCount}',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Bottom action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _saveDraft,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Save as Draft'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _publishPost,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Publish'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}