// lib/widgets/common/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme_config.dart';
import '../auth/auth_dialog.dart';
import './top_nav_bar.dart'; // Import the top navigation items structure
import 'package:collection/collection.dart'; // Needed for firstWhereOrNull if we use it

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentRoute = ModalRoute.of(context)?.settings.name; 
    const Color activeColor = Colors.amber; // Consistent active color

    // Helper to build ListTiles for sub-items
    List<Widget> buildSubItems(BuildContext context, NavItem hubItem, List<NavItem> subItems, String? currentRoute) {
      List<Widget> tiles = [];

      // 1. Add the main Hub link first
      bool isMainHubActive = currentRoute == hubItem.route;
      tiles.add(
        Padding(
          padding: const EdgeInsets.only(left: 16.0), // Indent main hub link slightly less
          child: ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(
              hubItem.title, // Title like "GM Hub Landing"
              style: TextStyle(
                fontWeight: isMainHubActive ? FontWeight.bold : FontWeight.normal,
                color: hubItem.isPlaceholder ? Colors.grey : (isMainHubActive ? activeColor : null),
              ),
            ),
            selected: isMainHubActive,
            selectedTileColor: activeColor.withOpacity(0.1),
            enabled: !hubItem.isPlaceholder,
            onTap: hubItem.isPlaceholder ? null : () {
              Navigator.pop(context); // Close drawer
              if (currentRoute != hubItem.route) {
                Navigator.pushNamed(context, hubItem.route);
              }
            },
          ),
        )
      );
      
      // Add a divider
       tiles.add(const Divider(height: 1, indent: 32, endIndent: 16));

      // 2. Sort and add sub-item links
      List<NavItem> sortedSubItems = List.from(subItems);
      sortedSubItems.sort((a, b) {
        if (a.isPlaceholder != b.isPlaceholder) {
          return a.isPlaceholder ? 1 : -1; // Non-placeholders first
        }
        return a.title.compareTo(b.title); // Then alphabetical
      });

      for (var subItem in sortedSubItems) {
        bool isSubItemActive = currentRoute == subItem.route;
        tiles.add(
          Padding(
            padding: const EdgeInsets.only(left: 24.0), // Indent sub-items more
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              title: Text(
                subItem.title + (subItem.isPlaceholder ? ' *' : ''),
                style: TextStyle(
                  fontWeight: isSubItemActive ? FontWeight.bold : FontWeight.normal,
                  color: subItem.isPlaceholder ? Colors.grey : (isSubItemActive ? activeColor : null),
                ),
              ),
              selected: isSubItemActive,
              selectedTileColor: activeColor.withOpacity(0.1),
              enabled: !subItem.isPlaceholder,
              onTap: subItem.isPlaceholder ? null : () {
                Navigator.pop(context); // Close drawer
                if (currentRoute != subItem.route) {
                  Navigator.pushNamed(context, subItem.route);
                }
              },
            ),
          )
        );
      }
      return tiles;
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              // Optional: Use a gradient or image? For now, keep primary color
              color: theme.primaryColor,
            ),
            child: const Text(
              'StickToTheModel', // Use App Name or similar
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Dynamically generate navigation items
          ...topNavItems.map((item) {
            bool isHubActive = isRouteInHub(currentRoute, item);
            bool isDirectlyActive = currentRoute == item.route;

            if (item.subItems == null || item.subItems!.isEmpty) {
              // Simple ListTile for items without sub-items (Home, Blog)
              return ListTile(
                leading: item.icon != null ? Icon(item.icon, color: isDirectlyActive ? activeColor : null) : null,
                title: Text(
                    item.title,
                     style: TextStyle(
                       fontWeight: isDirectlyActive ? FontWeight.bold : FontWeight.normal,
                       color: isDirectlyActive ? activeColor : null,
                     ),
                    ),
                selected: isDirectlyActive,
                selectedTileColor: activeColor.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                   if (currentRoute != item.route) {
                    Navigator.pushNamed(context, item.route);
                  }
                },
              );
            } else {
              // ExpansionTile for items with sub-items (Hubs)
              return ExpansionTile(
                 leading: item.icon != null ? Icon(item.icon, color: isHubActive ? activeColor : null) : null,
                 title: Text(
                   item.title,
                   style: TextStyle(
                      fontWeight: isHubActive ? FontWeight.bold : FontWeight.normal,
                      color: isHubActive ? activeColor : null,
                   ),
                 ),
                 // Maintain expanded state if a child route is active
                 initiallyExpanded: isHubActive,
                 // Use slightly different background if the hub is active
                 backgroundColor: isHubActive ? activeColor.withOpacity(0.05) : null,
                 // Carefully adjust icon colors on expansion
                 collapsedIconColor: isHubActive ? activeColor : null,
                 iconColor: isHubActive ? activeColor : null,
                 children: buildSubItems(context, item, item.subItems!, currentRoute),
               );
            }
          }).toList(),
          
           const Divider(), // Add a divider before potential auth actions

          // Updated Consumer<AuthProvider> block
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              // Check if user is authenticated (assuming 'user != null' is the correct check)
              if (authProvider.user != null) {
                return ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () {
                    Navigator.pop(context); 
                    authProvider.signOut();
                     Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  },
                );
              } else {
                return ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('Sign In / Sign Up'),
                  onTap: () {
                    Navigator.pop(context); 
                    showDialog(context: context, builder: (_) => const AuthDialog());
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }
}