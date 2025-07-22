# MDS Design System
## Modern Data Sports - A comprehensive design system for NFL analytics platforms

The MDS Design System provides a cohesive set of components that capture the essence of professional sports analytics while maintaining modern UI/UX standards. Built specifically for your NFL analytics platform, these components ensure consistency, accessibility, and a distinct visual identity.

## Design Philosophy

- **Data-Driven**: Components designed to showcase complex NFL statistics elegantly
- **Professional**: Clean, sophisticated aesthetic appropriate for serious analytics
- **Engaging**: Interactive elements that make data exploration enjoyable
- **Consistent**: Unified visual language across all components
- **Accessible**: Built with accessibility best practices

## Core Components

### 1. MdsButton
Versatile button component with multiple variants and built-in loading states.

```dart
MdsButton(
  onPressed: () {},
  text: 'Primary Action',
  type: MdsButtonType.primary,
  icon: Icons.sports_football,
)
```

**Variants:**
- `primary` - Main call-to-action buttons
- `secondary` - Secondary actions
- `text` - Subtle actions
- Built-in loading states
- Icon support

### 2. MdsCard
Flexible card component with multiple styles for different content types.

```dart
MdsCard(
  type: MdsCardType.feature,
  gradientColors: [Colors.blue, Colors.purple],
  onTap: () {},
  child: YourContent(),
)
```

**Types:**
- `standard` - Basic content cards
- `elevated` - Enhanced shadow for prominence
- `outlined` - Subtle border styling
- `player` - Optimized for player information
- `stat` - Perfect for displaying statistics
- `feature` - Hero cards with gradient backgrounds
- `gradient` - Customizable gradient cards

### 3. MdsPlayerCard
Specialized card for displaying NFL player information with team colors and stats.

```dart
MdsPlayerCard(
  type: MdsPlayerCardType.featured,
  playerName: 'Josh Allen',
  team: 'BUF',
  position: 'QB',
  teamColor: Colors.blue,
  primaryStat: 'Passing Yards',
  primaryStatValue: '4,306',
  showBadge: true,
  badgeText: 'Elite',
  onTap: () {},
)
```

**Features:**
- Team color integration
- Flexible stat display
- Badge system for player status
- Multiple layout options
- Touch interactions

### 4. MdsStatDisplay
Purpose-built component for showcasing NFL statistics with trend indicators.

```dart
MdsStatDisplay(
  type: MdsStatType.performance,
  label: 'Performance Score',
  value: '94.2',
  subtitle: 'Above Average',
  showTrend: true,
  trendValue: 12.5,
  icon: Icons.trending_up,
)
```

**Types:**
- `standard` - Basic stat display
- `performance` - Performance metrics
- `comparison` - Comparative statistics
- `trend` - Trending data with indicators
- `highlight` - Featured statistics

### 5. MdsInput
Comprehensive input system with specialized variants for different data types.

```dart
MdsInput(
  label: 'Player Name',
  hint: 'Enter player name',
  type: MdsInputType.search,
  prefixIcon: Icons.person,
  onChanged: (value) {},
)
```

**Types:**
- `standard` - General text input
- `search` - Search functionality
- `filter` - Filtering inputs
- `numeric` - Number inputs
- `email` - Email validation
- `password` - Secure password input

### 6. MdsSearchBar
Dedicated search component with advanced features for player/team search.

```dart
MdsSearchBar(
  hint: 'Search players, teams, or stats...',
  onChanged: (query) {},
  showFilter: true,
  onFilterTap: () {},
)
```

**Features:**
- Real-time search
- Clear functionality
- Filter integration
- Focus management
- Suggestions support

### 7. MdsFilterChip
Interactive filter chips for data categorization and selection.

```dart
MdsFilterChip(
  label: 'Quarterback',
  isSelected: true,
  icon: Icons.sports_football,
  onTap: () {},
)
```

**Features:**
- Selection states
- Icon support
- Custom colors
- Animation transitions
- Accessibility support

### 8. MdsLoading
Sophisticated loading states that match your platform's aesthetic.

```dart
MdsLoading(
  type: MdsLoadingType.skeleton,
  width: double.infinity,
  height: 20,
)
```

**Types:**
- `spinner` - Traditional spinner
- `skeleton` - Skeleton loading
- `pulse` - Pulsing animation
- `dots` - Animated dots
- `card` - Card-shaped skeleton
- `stat` - Stat display skeleton

## Usage

### Import the design system:
```dart
import 'package:mds_home/widgets/design_system/index.dart';
```

### Theme Integration
All components automatically adapt to your app's theme and support both light and dark modes. They use colors from your `ThemeConfig`:

- `ThemeConfig.darkNavy` - Primary brand color
- `ThemeConfig.brightRed` - Accent color
- `ThemeConfig.gold` - Highlight color

### Consistency Guidelines

1. **Use appropriate component variants** - Each component type serves a specific purpose
2. **Maintain spacing consistency** - Use standard spacing increments (8, 16, 24, 32)
3. **Follow color hierarchy** - Primary colors for main actions, secondary for supporting actions
4. **Respect loading states** - Always provide loading feedback for async operations
5. **Consider accessibility** - All components include proper accessibility support

## Examples

### Player Dashboard Card
```dart
MdsCard(
  type: MdsCardType.player,
  child: Column(
    children: [
      MdsPlayerCard(
        playerName: 'Patrick Mahomes',
        team: 'KC',
        position: 'QB',
        teamColor: Colors.red,
        primaryStat: 'TD Passes',
        primaryStatValue: '41',
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: MdsStatDisplay(
              label: 'QBR',
              value: '112.8',
              type: MdsStatType.highlight,
            ),
          ),
          Expanded(
            child: MdsStatDisplay(
              label: 'Completion %',
              value: '69.3%',
              type: MdsStatType.standard,
            ),
          ),
        ],
      ),
    ],
  ),
)
```

### Search and Filter Interface
```dart
Column(
  children: [
    MdsSearchBar(
      hint: 'Search NFL players...',
      onChanged: (query) => _performSearch(query),
    ),
    const SizedBox(height: 16),
    Wrap(
      spacing: 8,
      children: ['All', 'QB', 'RB', 'WR', 'TE'].map((filter) =>
        MdsFilterChip(
          label: filter,
          isSelected: _selectedFilter == filter,
          onTap: () => _selectFilter(filter),
        ),
      ).toList(),
    ),
  ],
)
```

## Migration Guide

When updating existing screens to use the design system:

1. **Replace generic Flutter widgets** with MDS components
2. **Update import statements** to use the design system index
3. **Review spacing and padding** for consistency
4. **Test both light and dark themes**
5. **Verify accessibility** with screen readers

## Performance Considerations

- Components are optimized for Flutter's widget tree
- Animations use efficient Flutter animation APIs
- Loading states prevent UI blocking
- Memory-efficient implementations

## Customization

Components can be customized through:
- Theme configuration
- Custom colors via parameters
- Gradient customization
- Icon selection
- Size variants

The design system is built to be flexible while maintaining visual consistency across your NFL analytics platform. 