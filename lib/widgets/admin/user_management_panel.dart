// lib/widgets/admin/user_management_panel.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user.dart' as app_user;

class UserManagementPanel extends StatefulWidget {
  const UserManagementPanel({super.key});

  @override
  _UserManagementPanelState createState() => _UserManagementPanelState();
}

class _UserManagementPanelState extends State<UserManagementPanel> {
  bool _isLoading = true;
  List<app_user.User> _users = [];
  app_user.User? _selectedUser;
  String? _searchQuery;
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final query = FirebaseFirestore.instance.collection('users');
      final snapshot = await query.get();
      
      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        return app_user.User.fromJson(data);
      }).toList();
      
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  List<app_user.User> get _filteredUsers {
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      return _users;
    }
    
    final query = _searchQuery!.toLowerCase();
    return _users.where((user) {
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
    }).toList();
  }
  
  Future<void> _toggleAdminStatus(app_user.User user) async {
    try {
      final isAdmin = user.draftPreferences?['isAdmin'] == true;
      
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'draftPreferences.isAdmin': !isAdmin,
      });
      
      // Reload the users
      await _loadUsers();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} admin status updated')),
      );
    } catch (e) {
      debugPrint('Error toggling admin status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'User Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          // Search and refresh
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search Users',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadUsers,
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // User list and details
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User list
                      Expanded(
                        flex: 2,
                        child: Card(
                          child: ListView.builder(
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              final isSelected = _selectedUser?.id == user.id;
                              final isAdmin = user.draftPreferences?['isAdmin'] == true;
                              // lib/widgets/admin/user_management_panel.dart (continued)
                              
                              return ListTile(
                                title: Text(user.name),
                                subtitle: Text(user.email),
                                leading: CircleAvatar(
                                  child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                                ),
                                trailing: isAdmin 
                                  ? const Icon(Icons.admin_panel_settings, color: Colors.blue)
                                  : null,
                                selected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _selectedUser = user;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // User details
                      Expanded(
                        flex: 3,
                        child: _selectedUser == null
                            ? const Center(child: Text('Select a user to view details'))
                            : _buildUserDetails(_selectedUser!),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserDetails(app_user.User user) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = user.draftPreferences?['isAdmin'] == true;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // User Details
            _buildDetailRow('User ID', user.id),
            _buildDetailRow('Created', _formatDate(user.createdAt)),
            _buildDetailRow('Last Login', _formatDate(user.lastLoginAt)),
            _buildDetailRow('Subscribed', user.isSubscribed ? 'Yes' : 'No'),
            _buildDetailRow('Admin Status', isAdmin ? 'Admin' : 'Regular User'),
            
            const SizedBox(height: 24),
            
            // User Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Toggle Admin Status Button
                ElevatedButton.icon(
                  onPressed: () => _toggleAdminStatus(user),
                  icon: Icon(isAdmin ? Icons.person : Icons.admin_panel_settings),
                  label: Text(isAdmin ? 'Remove Admin' : 'Make Admin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAdmin ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}