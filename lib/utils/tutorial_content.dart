// lib/utils/tutorial_content.dart
import 'package:flutter/material.dart';

class TutorialContent {
  static const List<Map<String, dynamic>> sections = [
    {
      'title': 'Welcome to StickToTheModel',
      'description': 'Your Ultimate NFL Draft Simulation Tool',
      'icon': Icons.sports_football,
      'content': [
        {
          'subtitle': 'What is StickToTheModel?',
          'details': 'A comprehensive NFL Draft simulation platform that provides deep insights and strategic draft planning.',
          'features': [
            'Realistic draft simulation',
            'Multi-team draft control',
            'Advanced trade negotiation',
            'Real-time draft analytics',
            'Customizable draft settings'
          ]
        }
      ]
    },
    {
      'title': 'Team Selection',
      'description': 'Choose Your Draft Strategy',
      'icon': Icons.group,
      'content': [
        {
          'subtitle': 'Selecting Your Teams',
          'details': 'Control one or multiple teams during the draft simulation.',
          'features': [
            'Click team logos to select/deselect',
            'Use "Select All" toggle for quick selection',
            'Mix teams from AFC and NFC',
            'Select teams across different conferences'
          ]
        }
      ]
    },
    {
      'title': 'Draft Settings',
      'description': 'Customize Your Draft Experience',
      'icon': Icons.settings,
      'content': [
        {
          'subtitle': 'Configuring Draft Parameters',
          'details': 'Adjust simulation settings to match your draft strategy.',
          'features': [
            'Select number of draft rounds (1-7)',
            'Control draft speed',
            'Adjust randomness factor',
            'Enable/disable trading',
            'Set trade frequency',
            'Balance need vs. best player available'
          ]
        }
      ]
    },
    {
      'title': 'Draft Simulation',
      'description': 'Real-Time Draft Simulation',
      'icon': Icons.play_arrow,
      'content': [
        {
          'subtitle': 'How the Simulation Works',
          'details': 'Navigate through the draft with comprehensive controls.',
          'features': [
            'Start/Pause draft progression',
            'Manually select players',
            'Propose and negotiate trades',
            'View real-time draft order',
            'Track available players',
            'Monitor team needs'
          ]
        }
      ]
    },
    {
      'title': 'Trading Mechanics',
      'description': 'Dynamic Trade Negotiations',
      'icon': Icons.swap_horiz,
      'content': [
        {
          'subtitle': 'Trade Proposal and Evaluation',
          'details': 'Engage in realistic trade scenarios with AI-driven negotiations.',
          'features': [
            'Propose trades between teams',
            'Receive and counter trade offers',
            'Evaluate trade value using draft pick calculator',
            'Consider team needs in trade decisions',
            'View trade analytics'
          ]
        }
      ]
    },
    {
      'title': 'Analytics Dashboard',
      'description': 'Comprehensive Draft Insights',
      'icon': Icons.analytics,
      'content': [
        {
          'subtitle': 'Draft Performance Tracking',
          'details': 'Gain deep insights into draft strategies and outcomes.',
          'features': [
            'Team draft grade analysis',
            'Position distribution tracking',
            'Value over replacement player metrics',
            'Trade impact visualization',
            'Comparative draft performance'
          ]
        }
      ]
    }
  ];

  // Advanced tutorial with more detailed instructions
  static const List<Map<String, dynamic>> advancedTips = [
    {
      'title': 'Advanced Simulation Strategies',
      'tips': [
        'Balance immediate team needs with long-term potential',
        'Use trade offers to move up or acquire additional picks',
        'Consider player rankings and positional scarcity',
        'Analyze draft value charts before making trades'
      ]
    },
    {
      'title': 'Maximizing Draft Value',
      'tips': [
        'Look for players who offer high value relative to draft position',
        'Consider trading down to accumulate more picks',
        'Pay attention to positional depth in each draft class',
        'Use the RAS (Relative Athletic Score) to compare prospects'
      ]
    }
  ];
}