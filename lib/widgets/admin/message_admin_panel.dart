// lib/widgets/admin/message_admin_panel.dart
import 'package:flutter/material.dart';
import '../../services/message_service.dart';
import '../../utils/theme_config.dart';
import '../../main.dart'; 

/// Admin panel to view and manage user messages
/// This would be hidden behind authentication in a production app
class MessageAdminPanel extends StatefulWidget {
  const MessageAdminPanel({super.key});

  @override
  _MessageAdminPanelState createState() => _MessageAdminPanelState();
}

class _MessageAdminPanelState extends State<MessageAdminPanel> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _selectedMessageId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messages = await MessageService.getAllMessages();
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }

  Future<void> _clearAllMessages() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete all messages? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      await MessageService.clearAllMessages();
      await _loadMessages();
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  Widget _buildMessageDetails(Map<String, dynamic> message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              message['feedbackType'] ?? 'Unknown Type',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.blue.shade800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From: ${message['name']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Email: ${message['email']}',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Status: ${message['status'] ?? 'unknown'}',
                    style: TextStyle(
                      color: (message['status'] == 'pending')
                          ? Colors.orange
                          : (message['status'] == 'sent')
                              ? Colors.green
                              : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatTimestamp(message['timestamp'] ?? ''),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          const Text(
            'Message:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade700 : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
              ),
            ),
            width: double.infinity,
            child: Text(
              message['message'] ?? 'No message content',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (message['status'] == 'pending')
                ElevatedButton.icon(
                  onPressed: () async {
                    await MessageService.markMessageAsSent(message['timestamp']);
                    _loadMessages();
                  },
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Mark as Sent'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Admin Panel'),
        actions: [
          IconButton(
      icon: const Icon(Icons.admin_panel_settings),
      tooltip: 'Main Admin Panel',
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AdminPanel(), // You'll need to import this
          ),
        );
      },
    ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadMessages,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear All Messages',
            onPressed: _clearAllMessages,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No messages found',
                        style: TextStyle(
                          fontSize: 18,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      color: isDarkMode ? ThemeConfig.darkNavy : ThemeConfig.deepRed.withOpacity(0.1),
                      child: Text(
                        '${_messages.length} Message${_messages.length != 1 ? 's' : ''} Found',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                                                      color: isDarkMode ? Colors.white : ThemeConfig.deepRed,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Message list (left sidebar)
                          SizedBox(
                            width: 250,
                            child: ListView.builder(
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                final isSelected = _selectedMessageId == message['timestamp'];
                                final name = message['name'] ?? 'Unknown';
                                final timestamp = message['timestamp'] ?? '';
                                final type = message['feedbackType'] ?? 'Unknown Type';

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  color: isSelected
                                      ? (isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50)
                                      : (isDarkMode ? Colors.grey.shade800 : Colors.white),
                                  elevation: isSelected ? 4 : 1,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedMessageId = message['timestamp'];
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: isSelected
                                                        ? (isDarkMode ? Colors.white : Colors.blue.shade800)
                                                        : null,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: message['status'] == 'pending'
                                                      ? Colors.orange
                                                      : Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            type,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatTimestamp(timestamp),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          // Vertical divider
                          VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                          ),
                          
                          // Message details (right panel)
                          Expanded(
                            child: _selectedMessageId == null
                                ? Center(
                                    child: Text(
                                      'Select a message to view details',
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                                      ),
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: _buildMessageDetails(
                                      _messages.firstWhere(
                                        (msg) => msg['timestamp'] == _selectedMessageId,
                                        orElse: () => {},
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}