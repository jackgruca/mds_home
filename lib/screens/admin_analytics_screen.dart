// lib/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/admin/message_admin_panel.dart';
import '../widgets/admin/analytics_setup_widget.dart';
import '../widgets/admin/user_management_panel.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // Add this import


class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;
  
  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }
  
  Future<void> _checkAdminStatus() async {
    setState(() {
      _isCheckingAdmin = true;
    });
    
    try {
      // Check if current user is an admin
      final firebaseAuth = firebase_auth.FirebaseAuth.instance;
      final currentUser = firebaseAuth.currentUser;
      
      if (currentUser == null) {
        setState(() {
          _isAdmin = false;
          _isCheckingAdmin = false;
        });
        return;
      }
      
      // Get user document from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        setState(() {
          _isAdmin = userData['isAdmin'] == true;
          _isCheckingAdmin = false;
        });
      } else {
        setState(() {
          _isAdmin = false;
          _isCheckingAdmin = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      setState(() {
        _isAdmin = false;
        _isCheckingAdmin = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (_isCheckingAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Access Denied'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: isDarkMode ? Colors.red.shade300 : Colors.red.shade700,
              ),
              const SizedBox(height: 24),
              const Text(
                'You do not have admin privileges',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please contact an administrator if you need access.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: Row(
        children: [
          // Side navigation
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.selected,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('User Management'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.message),
                label: Text('Messages'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics),
                label: Text('Analytics'),
              ),
            ],
          ),
          
          // Content area
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                // Dashboard
                _buildDashboard(),
                
                // User Management
                const UserManagementPanel(),
                
                // Messages
                const MessageAdminPanel(),
                
                // Analytics
                const AnalyticsSetupWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          
          // Stats cards
          Row(
            children: [
              _buildStatCard('Total Users', '..', Icons.people),
              const SizedBox(width: 16),
              _buildStatCard('Active Today', '..', Icons.person_add),
              const SizedBox(width: 16),
              _buildStatCard('New Messages', '..', Icons.message),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Recent activity
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 5,
              itemBuilder: (context, index) {
                return const ListTile(
                  leading: Icon(Icons.access_time),
                  title: Text('Loading activity...'),
                  subtitle: Text('Just now'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}