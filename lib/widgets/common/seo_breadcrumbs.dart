import 'package:flutter/material.dart';
import '../../utils/seo_helper.dart';

class SEOBreadcrumbs extends StatefulWidget {
  final List<BreadcrumbItem> items;
  final bool showOnMobile;

  const SEOBreadcrumbs({
    super.key,
    required this.items,
    this.showOnMobile = false,
  });

  @override
  State<SEOBreadcrumbs> createState() => _SEOBreadcrumbsState();
}

class _SEOBreadcrumbsState extends State<SEOBreadcrumbs> {
  @override
  void initState() {
    super.initState();
    
    // Update structured data for breadcrumbs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final breadcrumbData = widget.items.map((item) => {
        'name': item.title,
        'url': item.url,
      }).toList();
      
      SEOHelper.updateBreadcrumbs(breadcrumbData);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Hide on mobile unless explicitly shown
        if (constraints.maxWidth < 600 && !widget.showOnMobile) {
          return const SizedBox.shrink();
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            children: _buildBreadcrumbItems(context),
          ),
        );
      },
    );
  }

  List<Widget> _buildBreadcrumbItems(BuildContext context) {
    final List<Widget> items = [];
    
    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final isLast = i == widget.items.length - 1;
      
      // Add breadcrumb item
      items.add(
        GestureDetector(
          onTap: isLast ? null : () => _navigateToItem(context, item),
          child: Text(
            item.title,
            style: TextStyle(
              color: isLast 
                ? Theme.of(context).textTheme.bodyMedium?.color
                : Theme.of(context).primaryColor,
              fontSize: 14,
              fontWeight: isLast ? FontWeight.normal : FontWeight.w500,
            ),
          ),
        ),
      );
      
      // Add separator (except for last item)
      if (!isLast) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(
              Icons.chevron_right,
              size: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
        );
      }
    }
    
    return items;
  }

  void _navigateToItem(BuildContext context, BreadcrumbItem item) {
    if (item.route != null) {
      Navigator.of(context).pushNamed(item.route!);
    }
  }
}

class BreadcrumbItem {
  final String title;
  final String url;
  final String? route; // Flutter route for navigation

  const BreadcrumbItem({
    required this.title,
    required this.url,
    this.route,
  });
}

// Common breadcrumb configurations
class CommonBreadcrumbs {
  static List<BreadcrumbItem> fantasy({String? currentPage}) {
    final items = [
      const BreadcrumbItem(
        title: 'Home',
        url: 'https://sticktothemodel.com',
        route: '/',
      ),
      const BreadcrumbItem(
        title: 'Fantasy Football',
        url: 'https://sticktothemodel.com/fantasy',
        route: '/fantasy',
      ),
    ];
    
    if (currentPage != null) {
      items.add(BreadcrumbItem(
        title: currentPage,
        url: 'https://sticktothemodel.com${ModalRoute.of(NavigationService.navigatorKey.currentContext!)?.settings.name ?? ''}',
      ));
    }
    
    return items;
  }

  static List<BreadcrumbItem> rankings(String position) {
    return [
      const BreadcrumbItem(
        title: 'Home',
        url: 'https://sticktothemodel.com',
        route: '/',
      ),
      const BreadcrumbItem(
        title: 'Rankings',
        url: 'https://sticktothemodel.com/rankings',
        route: '/rankings',
      ),
      BreadcrumbItem(
        title: '$position Rankings',
        url: 'https://sticktothemodel.com/rankings/${position.toLowerCase()}',
      ),
    ];
  }

  static List<BreadcrumbItem> gmHub({String? currentPage}) {
    final items = [
      const BreadcrumbItem(
        title: 'Home',
        url: 'https://sticktothemodel.com',
        route: '/',
      ),
      const BreadcrumbItem(
        title: 'GM Hub',
        url: 'https://sticktothemodel.com/gm-hub',
        route: '/gm-hub',
      ),
    ];
    
    if (currentPage != null) {
      items.add(BreadcrumbItem(
        title: currentPage,
        url: 'https://sticktothemodel.com/gm-hub/${currentPage.toLowerCase().replaceAll(' ', '-')}',
      ));
    }
    
    return items;
  }

  static List<BreadcrumbItem> dataExplorer({String? currentPage}) {
    final items = [
      const BreadcrumbItem(
        title: 'Home',
        url: 'https://sticktothemodel.com',
        route: '/',
      ),
      const BreadcrumbItem(
        title: 'Data Explorer',
        url: 'https://sticktothemodel.com/data',
        route: '/data',
      ),
    ];
    
    if (currentPage != null) {
      items.add(BreadcrumbItem(
        title: currentPage,
        url: 'https://sticktothemodel.com/data/${currentPage.toLowerCase().replaceAll(' ', '-')}',
      ));
    }
    
    return items;
  }
}

// Navigation service for breadcrumbs (if not already exists)
class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}