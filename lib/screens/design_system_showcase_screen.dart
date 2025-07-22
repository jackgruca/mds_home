import 'package:flutter/material.dart';
import '../widgets/design_system/index.dart';
import '../utils/theme_config.dart';

class DesignSystemShowcaseScreen extends StatefulWidget {
  const DesignSystemShowcaseScreen({super.key});

  @override
  State<DesignSystemShowcaseScreen> createState() => _DesignSystemShowcaseScreenState();
}

class _DesignSystemShowcaseScreenState extends State<DesignSystemShowcaseScreen> {
  final TextEditingController _searchController = TextEditingController();
  final bool _isLoading = false;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'QB', 'RB', 'WR', 'TE'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MDS Design System'),
        backgroundColor: ThemeConfig.darkNavy,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Buttons'),
            _buildButtonsSection(),
            
            const SizedBox(height: 32),
            _buildSectionHeader('Cards'),
            _buildCardsSection(),
            
            const SizedBox(height: 32),
            _buildSectionHeader('Player Cards'),
            _buildPlayerCardsSection(),
            
            const SizedBox(height: 32),
            _buildSectionHeader('Stat Displays'),
            _buildStatsSection(),
            
            const SizedBox(height: 32),
            _buildSectionHeader('Input Components'),
            _buildInputsSection(),
            
            const SizedBox(height: 32),
            _buildSectionHeader('Loading States'),
            _buildLoadingSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: ThemeConfig.darkNavy,
        ),
      ),
    );
  }

  Widget _buildButtonsSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MdsButton(
                onPressed: () {},
                text: 'Primary Button',
                type: MdsButtonType.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MdsButton(
                onPressed: () {},
                text: 'Secondary Button',
                type: MdsButtonType.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MdsButton(
                onPressed: () {},
                text: 'Text Button',
                type: MdsButtonType.text,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: MdsButton(
                onPressed: null,
                text: 'Loading...',
                isLoading: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        MdsButton(
          onPressed: () {},
          text: 'Button with Icon',
          icon: Icons.sports_football,
        ),
      ],
    );
  }

  Widget _buildCardsSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MdsCard(
                type: MdsCardType.standard,
                child: Column(
                  children: [
                    const Icon(Icons.analytics, size: 32, color: ThemeConfig.darkNavy),
                    const SizedBox(height: 8),
                    Text('Standard Card', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Basic content card', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MdsCard(
                type: MdsCardType.elevated,
                child: Column(
                  children: [
                    const Icon(Icons.trending_up, size: 32, color: ThemeConfig.brightRed),
                    const SizedBox(height: 8),
                    Text('Elevated Card', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Enhanced shadow', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        MdsCard(
          type: MdsCardType.feature,
          gradientColors: const [ThemeConfig.darkNavy, ThemeConfig.brightRed],
          child: Column(
            children: [
              const Icon(Icons.psychology, color: Colors.white, size: 40),
              const SizedBox(height: 12),
              Text(
                'Feature Card',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Perfect for highlighting key features with gradient backgrounds',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCardsSection() {
    return Column(
      children: [
        MdsPlayerCard(
          type: MdsPlayerCardType.featured,
          playerName: 'Josh Allen',
          team: 'BUF',
          position: 'QB',
          teamColor: Colors.blue,
          primaryStat: 'Passing Yards',
          primaryStatValue: '4,306',
          secondaryStat: 'TD Passes',
          secondaryStatValue: '29',
          showBadge: true,
          badgeText: 'Elite',
          badgeColor: ThemeConfig.gold,
          onTap: () {},
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MdsPlayerCard(
                type: MdsPlayerCardType.compact,
                playerName: 'Stefon Diggs',
                team: 'BUF',
                position: 'WR',
                teamColor: Colors.blue,
                primaryStat: 'Rec',
                primaryStatValue: '107',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MdsPlayerCard(
                type: MdsPlayerCardType.compact,
                playerName: 'James Cook',
                team: 'BUF',
                position: 'RB',
                teamColor: Colors.blue,
                primaryStat: 'Rush Yds',
                primaryStatValue: '1,122',
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MdsStatDisplay(
                type: MdsStatType.highlight,
                label: 'League Leader',
                value: '4,306',
                subtitle: 'Passing Yards',
                icon: Icons.sports_football,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: MdsStatDisplay(
                type: MdsStatType.performance,
                label: 'Performance Score',
                value: '94.2',
                subtitle: 'Above Average',
                icon: Icons.trending_up,
                showTrend: true,
                trendValue: 12.5,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MdsStatDisplay(
                type: MdsStatType.standard,
                label: 'Completions',
                value: '359',
                icon: Icons.check_circle,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: MdsStatDisplay(
                type: MdsStatType.comparison,
                label: 'Rank',
                value: '#3',
                subtitle: 'Among QBs',
                icon: Icons.leaderboard,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: MdsStatDisplay(
                type: MdsStatType.trend,
                label: 'Efficiency',
                value: '67.8%',
                showTrend: true,
                trendValue: -2.1,
                icon: Icons.speed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputsSection() {
    return Column(
      children: [
        MdsSearchBar(
          controller: _searchController,
          hint: 'Search for players, teams, or stats...',
          onChanged: (value) {},
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(
              child: MdsInput(
                label: 'Player Name',
                hint: 'Enter player name',
                prefixIcon: Icons.person,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: MdsInput(
                label: 'Season',
                hint: '2024',
                type: MdsInputType.numeric,
                prefixIcon: Icons.calendar_today,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const MdsInput(
          label: 'Email',
          hint: 'your.email@example.com',
          type: MdsInputType.email,
          prefixIcon: Icons.email,
        ),
        const SizedBox(height: 16),
        const MdsInput(
          label: 'Password',
          hint: 'Enter your password',
          type: MdsInputType.password,
          prefixIcon: Icons.lock,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: _filters.map((filter) => MdsFilterChip(
            label: filter,
            isSelected: _selectedFilter == filter,
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            icon: filter == 'All' ? Icons.select_all : Icons.sports_football,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildLoadingSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const MdsLoading(type: MdsLoadingType.spinner),
                  const SizedBox(height: 8),
                  Text('Spinner', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const MdsLoading(type: MdsLoadingType.dots),
                  const SizedBox(height: 8),
                  Text('Dots', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const MdsLoading(type: MdsLoadingType.pulse, width: 80, height: 20),
                  const SizedBox(height: 8),
                  Text('Pulse', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const MdsLoading(type: MdsLoadingType.skeleton, width: double.infinity, height: 20),
        const SizedBox(height: 8),
        const MdsLoading(type: MdsLoadingType.skeleton, width: 200, height: 20),
        const SizedBox(height: 8),
        const MdsLoading(type: MdsLoadingType.skeleton, width: 150, height: 20),
        const SizedBox(height: 24),
        const MdsLoading(type: MdsLoadingType.card),
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(child: MdsLoading(type: MdsLoadingType.stat)),
            SizedBox(width: 16),
            Expanded(child: MdsLoading(type: MdsLoadingType.stat)),
            SizedBox(width: 16),
            Expanded(child: MdsLoading(type: MdsLoadingType.stat)),
          ],
        ),
      ],
    );
  }
} 