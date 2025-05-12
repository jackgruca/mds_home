// lib/widgets/common/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme_config.dart';
import '../auth/auth_dialog.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.primaryColor,
            ),
            child: const Text(
              'Navigation',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context); // Close drawer first
              Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.drafts),
            title: const Text('Mock Draft Sim'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/draft', (Route<dynamic> route) => false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Historical Data'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/data', (Route<dynamic> route) => false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Betting Analytics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/betting', (Route<dynamic> route) => false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_search),
            title: const Text('Player Projections'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/projections', (Route<dynamic> route) => false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.article),
            title: const Text('Blog'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/blog', (Route<dynamic> route) => false);
            },
          ),
        ],
      ),
    );
  }
}