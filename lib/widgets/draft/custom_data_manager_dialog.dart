// lib/widgets/draft/custom_data_manager_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/custom_draft_data.dart';
import '../../providers/auth_provider.dart';

class CustomDataManagerDialog extends StatefulWidget {
  final Function(CustomDraftData) onDataSelected;
  final int currentYear;
  final List<List<dynamic>>? currentTeamNeeds;
  final List<List<dynamic>>? currentPlayerRankings;
  
  const CustomDataManagerDialog({
    super.key,
    required this.onDataSelected,
    required this.currentYear,
    this.currentTeamNeeds,
    this.currentPlayerRankings,
  });

  @override
  State<CustomDataManagerDialog> createState() => _CustomDataManagerDialogState();
}

class _CustomDataManagerDialogState extends State<CustomDataManagerDialog> {
  final TextEditingController _nameController = TextEditingController();
  List<CustomDraftData> _savedDataSets = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  void _loadSavedData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      _savedDataSets = authProvider.getUserCustomDraftData();
      
      // Sort by last modified (most recent first)
      _savedDataSets.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    } catch (e) {
      _errorMessage = 'Error loading saved data: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveCurrentData() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a name for this data set';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Create a new data set with the current data
      final newDataSet = CustomDraftData(
        name: _nameController.text.trim(),
        year: widget.currentYear,
        lastModified: DateTime.now(),
        teamNeeds: widget.currentTeamNeeds,
        playerRankings: widget.currentPlayerRankings,
      );
      
      // Save to user's profile
      final success = await authProvider.saveCustomDraftData(newDataSet);
      
      if (success) {
        // Reload the data
        _loadSavedData();
        _nameController.clear();
      } else {
        setState(() {
          _errorMessage = authProvider.error ?? 'Failed to save data';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteDataSet(CustomDraftData dataSet) async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Data Set'),
        content: Text('Are you sure you want to delete "${dataSet.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (shouldDelete != true) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Delete the data set
      final success = await authProvider.deleteCustomDraftData(dataSet.name);
      
      if (success) {
        // Reload the data
        _loadSavedData();
      } else {
        setState(() {
          _errorMessage = authProvider.error ?? 'Failed to delete data';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error deleting data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.save_alt,
                  color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Draft Data Manager',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const Divider(),
            
            // Save new data section
            Text(
              'Save Current Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name for this data set',
                      hintText: 'e.g., My Custom Rankings 2025',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveCurrentData,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
            
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Saved data sets section
            Text(
              'Saved Data Sets',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _savedDataSets.isEmpty
                      ? Center(
                          child: Text(
                            'No saved data sets found',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _savedDataSets.length,
                          itemBuilder: (context, index) {
                            final dataSet = _savedDataSets[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(dataSet.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Year: ${dataSet.year}'),
                                    Text(
                                      'Last Modified: ${_formatDate(dataSet.lastModified)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red.shade400,
                                      ),
                                      onPressed: () => _deleteDataSet(dataSet),
                                      tooltip: 'Delete',
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        widget.onDataSelected(dataSet);
                                      },
                                      child: const Text('Load'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${_formatTime(date)}';
  }
  
  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
  }
}