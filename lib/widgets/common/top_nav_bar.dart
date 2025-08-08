import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull
import '../../utils/theme_config.dart'; // Added import for ThemeConfig

// Define the structure for navigation items
class NavItem {
  final String title;
  final String route;
  final IconData? icon;
  final List<NavItem>? subItems;
  final bool isPlaceholder; // Flag for placeholder items

  NavItem({
    required this.title,
    required this.route,
    this.icon,
    this.subItems,
    this.isPlaceholder = false, // Default to false
  });
}

// Define the main navigation structure - Updated per user requirements
final List<NavItem> topNavItems = [
  NavItem(title: 'Home', route: '/', icon: Icons.home),
  
  // 1. Fantasy Hub
  NavItem(
    title: 'Fantasy Hub',
    route: '/fantasy',
    icon: Icons.sports_football,
    isPlaceholder: false,
    subItems: [
      NavItem(title: 'Fantasy Big Board', route: '/fantasy/big-board', isPlaceholder: false),
      NavItem(title: 'ADP Analysis', route: '/fantasy/adp', isPlaceholder: false),
      NavItem(title: 'Custom Rankings', route: '/fantasy/custom-rankings', isPlaceholder: false),
      NavItem(title: 'Stat Predictor', route: '/projections/stat-predictor', isPlaceholder: false),
      NavItem(title: 'Fantasy Mock Draft Sim', route: '/mock-draft-sim', isPlaceholder: false),
      NavItem(title: 'Player Comparison', route: '/fantasy/player-comparison', isPlaceholder: false),
      NavItem(title: 'Player Trends', route: '/fantasy/trends', isPlaceholder: false),
      NavItem(title: 'My Custom Rankings', route: '/vorp/my-custom-rankings', isPlaceholder: false),
    ],
  ),
  
  // 2. Be a GM
  NavItem(
    title: 'Be a GM',
    route: '/gm-hub',
    icon: Icons.assignment_ind,
    isPlaceholder: false,
    subItems: [
      NavItem(title: 'Draft Big Board', route: '/draft-big-board', isPlaceholder: false),
      NavItem(title: 'Draft Mock Draft Simulator', route: '/draft', isPlaceholder: false),
      NavItem(title: 'NFL Trade Analyzer', route: '/nfl-trade-analyzer', isPlaceholder: false),
      NavItem(title: 'Historical Drafts', route: '/draft/historical-drafts', isPlaceholder: false),
      NavItem(title: 'Bust or Brilliant', route: '/fantasy/bust-evaluation', isPlaceholder: false),
      NavItem(title: 'Depth Chart', route: '/depth-charts', isPlaceholder: false),
      NavItem(title: 'Rosters', route: '/nfl-rosters', isPlaceholder: false),
    ],
  ),
  
  // 3. Rankings
  NavItem(
    title: 'Rankings',
    route: '/rankings',
    icon: Icons.leaderboard,
    isPlaceholder: false,
    subItems: [
      NavItem(title: 'Rankings Hub', route: '/rankings', isPlaceholder: false),
      NavItem(title: 'QB', route: '/rankings/qb', isPlaceholder: false),
      NavItem(title: 'WR', route: '/rankings/wr', isPlaceholder: false),
      NavItem(title: 'TE', route: '/rankings/te', isPlaceholder: false),
      NavItem(title: 'RB', route: '/rankings/rb', isPlaceholder: false),
      NavItem(title: 'EDGE', route: '/rankings/edge', isPlaceholder: false),
      NavItem(title: 'IDL', route: '/rankings/idl', isPlaceholder: false),
      NavItem(title: 'Pass Offense', route: '/rankings/pass-offense', isPlaceholder: false),
      NavItem(title: 'Run Offense', route: '/rankings/run-offense', isPlaceholder: false),
    ],
  ),
  
  // 4. Data Center
  NavItem(
    title: 'Data Center',
    route: '/data',
    icon: Icons.analytics,
    isPlaceholder: false,
    subItems: [
      NavItem(title: 'Historical Game Data', route: '/historical-game-data', isPlaceholder: false),
      NavItem(title: 'Player Season Stats', route: '/player-season-stats', isPlaceholder: false),
      NavItem(title: 'Player Data', route: '/players', isPlaceholder: false),
    ],
  ),
  
  NavItem(title: 'Blog', route: '/blog', icon: Icons.article),
];

// Helper function to check if a route belongs to a hub (more robustly)
bool isRouteInHub(String? currentRoute, NavItem hubItem) {
  if (currentRoute == null) return false;
  // Check 1: Direct match with the hub's landing page route
  if (currentRoute == hubItem.route) return true; 
  if (hubItem.subItems == null) return false;
  
  // Check 2: Match with *any* subItem route within this hub (including placeholders)
  return hubItem.subItems!.any((subItem) => subItem.route == currentRoute);
}


// The TopNavBarContent widget - returns the Row of navigation items
class TopNavBarContent extends StatelessWidget {
  final String? currentRoute;
  final double fontSize; // Added for consistent font size

  const TopNavBarContent({super.key, this.currentRoute, this.fontSize = 14.0}); // Default size

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const activeColor = ThemeConfig.gold; // Keep gold for active navigation items
    const Color inactiveColor = Colors.white; // White color for inactive items

    // Find the active top-level item (hub) using the updated helper function
     final String? activeTopLevelRoute = topNavItems.firstWhereOrNull(
       (item) => isRouteInHub(currentRoute, item)
     )?.route;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: topNavItems.map((item) {
          // Determine if this top-level item or its children are active
          bool isHubActive = activeTopLevelRoute == item.route || (item.route == '/' && currentRoute == '/'); // Special case for Home
          bool isDirectlyActive = currentRoute == item.route;
          bool highlightItem = isDirectlyActive || isHubActive;
          
          final Color itemColor = highlightItem ? activeColor : inactiveColor;
          final FontWeight itemWeight = highlightItem ? FontWeight.bold : FontWeight.normal;

          Widget navElement;
          if (item.subItems == null || item.subItems!.isEmpty) {
            // Simple navigation item (Home, Blog)
            navElement = TextButton.icon(
              icon: item.icon != null ? Icon(item.icon, color: itemColor, size: 18) : const SizedBox.shrink(),
              label: Text(
                  item.title,
                  style: TextStyle(color: itemColor, fontWeight: itemWeight, fontSize: fontSize), // Use fontSize
              ),
              onPressed: () {
                final currentRouteName = ModalRoute.of(context)?.settings.name;
                if (currentRouteName != item.route) {
                  Navigator.pushNamed(context, item.route);
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            );
          } else {
            // Navigation item with dropdown (Hubs)
            navElement = PopupMenuButton<String>(
              tooltip: "Open ${item.title} Menu",
              onSelected: (String route) {
                 final currentRouteName = ModalRoute.of(context)?.settings.name;
                 if (currentRouteName != route) {
                   Navigator.pushNamed(context, route);
                 }
              },
              itemBuilder: (BuildContext context) {
                // 1. Create the Hub Landing Page item
                PopupMenuItem<String> hubLandingPageItem = PopupMenuItem<String>(
                    value: item.route,
                    enabled: !item.isPlaceholder, // Use placeholder status of the main hub item
                    child: Text(
                      item.title, // Use the Hub's title
                      style: TextStyle(
                        fontWeight: currentRoute == item.route ? FontWeight.bold : FontWeight.normal,
                        color: currentRoute == item.route 
                               ? activeColor 
                               : (item.isPlaceholder ? Colors.grey : null),
                      ),
                    ),
                  );

                // 2. Keep sub-items in the exact order specified (no sorting)
                List<NavItem> sortedSubItems = List.from(item.subItems!);

                // 3. Create menu items for sub-items
                List<PopupMenuItem<String>> subMenuItems = sortedSubItems.map((subItem) {
                   bool isSubItemActive = currentRoute == subItem.route;
                   String displayTitle = subItem.title + (subItem.isPlaceholder ? ' *' : '');
                  return PopupMenuItem<String>(
                    value: subItem.route,
                     enabled: !subItem.isPlaceholder, // Disable clicks on placeholders
                    child: Text(
                      displayTitle,
                      style: TextStyle(
                        fontWeight: isSubItemActive ? FontWeight.bold : FontWeight.normal,
                        color: isSubItemActive ? activeColor : (subItem.isPlaceholder ? Colors.grey : null),
                      ),
                    ),
                  );
                }).toList();

                // 4. Combine Hub item and sub-items
                return [hubLandingPageItem, ...subMenuItems];
              },
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       if (item.icon != null) ...[
                         Icon(item.icon, color: itemColor, size: 18),
                         const SizedBox(width: 6),
                       ],
                       Text(
                          item.title,
                          style: TextStyle(color: itemColor, fontWeight: itemWeight, fontSize: fontSize), // Use fontSize
                       ),
                       Icon(Icons.arrow_drop_down, color: itemColor, size: 20),
                    ],
                  ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: navElement,
          );
        }).toList(),
      ),
    );
  }
} 