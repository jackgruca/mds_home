import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull

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

// Define the main navigation structure - Updated
final List<NavItem> topNavItems = [
  NavItem(title: 'Home', route: '/', icon: Icons.home), // Implemented
  NavItem(
    title: 'GM Hub', // Renamed back
    route: '/gm-hub', // Renamed route for clarity
    icon: Icons.assignment_ind, // Changed Icon back
    isPlaceholder: false, // <<< Changed to false: Landing page exists
    subItems: [
      // --- Implemented --- 
      NavItem(title: 'Mock Draft Simulator', route: '/draft', isPlaceholder: false),
      NavItem(title: 'Draft Big Board', route: '/draft/big-board', isPlaceholder: false),
      // --- Placeholders --- 
      // DRAFT
      NavItem(title: 'Team Needs Analyzer', route: '/team-builder/needs', isPlaceholder: true),
      NavItem(title: 'Prospect Comparisons', route: '/team-builder/prospects', isPlaceholder: true),
      // FREE AGENCY
      NavItem(title: 'Free Agent Tracker', route: '/team-builder/fa-tracker', isPlaceholder: true),
      NavItem(title: 'Contract Projections', route: '/team-builder/contracts', isPlaceholder: true),
      NavItem(title: 'Cap Space Analysis', route: '/team-builder/cap', isPlaceholder: true),
      NavItem(title: 'Team Fit Evaluator', route: '/team-builder/fit', isPlaceholder: true),
      // TEAM MANAGEMENT
      NavItem(title: 'Roster Builder', route: '/team-builder/roster', isPlaceholder: true),
      NavItem(title: 'Trade Finder', route: '/team-builder/trade', isPlaceholder: true),
      NavItem(title: 'Team Performance Forecaster', route: '/team-builder/forecast', isPlaceholder: true),
      NavItem(title: 'Depth Chart Analyzer', route: '/team-builder/depth', isPlaceholder: true),
    ],
  ),
  NavItem(
    title: 'Betting Hub',
    route: '/betting', // Landing page route
    icon: Icons.paid,
    isPlaceholder: false, // Already false: Landing page exists (points to analytics)
    subItems: [
      // --- Implemented --- 
      // NavItem(title: 'Betting Analytics', route: '/betting', isPlaceholder: false), // This is being moved
      // --- Placeholders --- 
      // ANALYZE
      NavItem(title: 'Line Movement Tracker', route: '/betting/lines', isPlaceholder: true),
      NavItem(title: 'Historical Matchup Analysis', route: '/betting/matchups', isPlaceholder: true),
      NavItem(title: 'Advanced Stats Breakdown', route: '/betting/stats', isPlaceholder: true),
      NavItem(title: 'Weather Impact Tool', route: '/betting/weather', isPlaceholder: true),
      // DISCOVER
      NavItem(title: 'Betting Angles Dashboard', route: '/betting/angles', isPlaceholder: true),
      NavItem(title: 'Under-the-Radar Values', route: '/betting/value', isPlaceholder: true),
      NavItem(title: 'Public vs. Sharp Money', route: '/betting/money', isPlaceholder: true),
      NavItem(title: 'Situational Spots Finder', route: '/betting/spots', isPlaceholder: true),
      // MY BETTING
      NavItem(title: 'Custom Indicators Builder', route: '/betting/indicators', isPlaceholder: true),
      NavItem(title: 'Saved Angles', route: '/betting/saved-angles', isPlaceholder: true),
      NavItem(title: 'Performance Tracker', route: '/betting/performance', isPlaceholder: true),
      NavItem(title: 'Betting Journal', route: '/betting/journal', isPlaceholder: true),
    ],
  ),
   NavItem(
    title: 'Fantasy Hub',
    route: '/fantasy', // Landing page route
    icon: Icons.sports_football,
    isPlaceholder: false,
    subItems: [
      // --- Implemented --- 
      NavItem(title: 'Fantasy Draft Simulator', route: '/draft/fantasy', isPlaceholder: false),
      NavItem(title: 'Rest-of-Season Projections', route: '/projections', isPlaceholder: false),
      NavItem(title: 'Fantasy Big Board', route: '/fantasy/big-board', isPlaceholder: false),
       // --- Placeholders --- 
      // PREPARE
      NavItem(title: 'Player Rankings', route: '/fantasy/rankings', isPlaceholder: true),
      NavItem(title: 'Draft Strategy Planner', route: '/fantasy/strategy', isPlaceholder: true),
      NavItem(title: 'ADP Analysis Tool', route: '/fantasy/adp', isPlaceholder: true),
      // COMPETE
      NavItem(title: 'Trade Analyzer', route: '/fantasy/trade', isPlaceholder: true),
      NavItem(title: 'Waiver Wire Assistant', route: '/fantasy/waiver', isPlaceholder: true),
      NavItem(title: 'Start/Sit Optimizer', route: '/fantasy/start-sit', isPlaceholder: true),
      NavItem(title: 'Matchup Analyzer', route: '/fantasy/matchups', isPlaceholder: true),
      // ANALYZE
      NavItem(title: 'Performance Tracker', route: '/fantasy/performance', isPlaceholder: true),
      NavItem(title: 'League Analyzer', route: '/fantasy/league', isPlaceholder: true),
      NavItem(title: 'Historical Comparisons', route: '/fantasy/historical', isPlaceholder: true),
   ]),
   NavItem(
    title: 'Data Explorer',
    route: '/data', // Landing page route
    icon: Icons.analytics,
    isPlaceholder: false, // Landing page exists
    subItems: [
      NavItem(title: 'Historical Game Results', route: '/historical-data', icon: Icons.history, isPlaceholder: false),
      NavItem(title: 'WR Season Stats', route: '/wr-model', icon: Icons.analytics, isPlaceholder: false),
      NavItem(title: 'Player Season Stats', route: '/player-season-stats', icon: Icons.query_stats, isPlaceholder: false),
      NavItem(title: 'Historical Game Data', route: '/betting', icon: Icons.paid, isPlaceholder: false), // Renamed
      // --- Placeholders ---
      NavItem(title: 'Player Career Statistics', route: '/data/player-stats', isPlaceholder: true),
      NavItem(title: 'Team Performance Trends', route: '/data/team-trends', isPlaceholder: true),
      NavItem(title: 'Advanced Metrics Database', route: '/data/metrics', isPlaceholder: true),
      NavItem(title: 'Interactive Charts', route: '/data/charts', isPlaceholder: true),
      NavItem(title: 'Comparison Tools', route: '/data/compare', isPlaceholder: true),
      NavItem(title: 'Trend Spotters', route: '/data/trends', isPlaceholder: true),
      NavItem(title: 'Situational Analysis', route: '/data/situational', isPlaceholder: true),
      NavItem(title: 'Custom Query Builder', route: '/data/query', isPlaceholder: true),
      NavItem(title: 'Data Export Tools', route: '/data/export', isPlaceholder: true),
      NavItem(title: 'Statistical Significance Tester', route: '/data/sig-test', isPlaceholder: true),
      NavItem(title: 'Correlation Finder', route: '/data/correlation', isPlaceholder: true),
    ],
  ),
   NavItem(title: 'Blog', route: '/blog', icon: Icons.article), // Implemented
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
    const Color activeColor = Colors.amber; // Gold color for active item
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

                // 2. Sort sub-items: implemented first, then placeholders, then alphabetically
                List<NavItem> sortedSubItems = List.from(item.subItems!);
                sortedSubItems.sort((a, b) {
                  if (a.isPlaceholder != b.isPlaceholder) {
                    return a.isPlaceholder ? 1 : -1; // Non-placeholders first
                  }
                  return a.title.compareTo(b.title); // Then alphabetical
                });

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