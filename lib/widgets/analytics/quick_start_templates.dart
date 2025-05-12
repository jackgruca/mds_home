import 'package:flutter/material.dart';
import 'package:mds_home/screens/historical_data_screen.dart';

class QueryTemplate {
  final String name;
  final String description;
  final String category;
  final List<QueryCondition> conditions;

  const QueryTemplate({
    required this.name,
    required this.description,
    required this.category,
    required this.conditions,
  });
}

class QuickStartTemplates extends StatelessWidget {
  final Function(List<QueryCondition>) onApplyTemplate;

  const QuickStartTemplates({
    super.key,
    required this.onApplyTemplate,
  });

  static final List<QueryTemplate> templates = [
    QueryTemplate(
      name: 'Home Field Advantage',
      description: 'Analyze team performance at home vs. away',
      category: 'Matchups',
      conditions: [
        QueryCondition(
          field: 'VH',
          operator: QueryOperator.equals,
          value: 'H',
        ),
      ],
    ),
    QueryTemplate(
      name: 'High Scoring Games',
      description: 'Find games with high total points',
      category: 'Betting',
      conditions: [
        QueryCondition(
          field: 'Actual_total',
          operator: QueryOperator.greaterThan,
          value: '50',
        ),
      ],
    ),
    QueryTemplate(
      name: 'Underdog Success',
      description: 'Find successful underdog performances',
      category: 'Betting',
      conditions: [
        QueryCondition(
          field: 'ML',
          operator: QueryOperator.greaterThan,
          value: '100',
        ),
        QueryCondition(
          field: 'Outcome',
          operator: QueryOperator.equals,
          value: 'W',
        ),
      ],
    ),
    QueryTemplate(
      name: 'Defensive Dominance',
      description: 'Games with strong defensive performance',
      category: 'Matchups',
      conditions: [
        QueryCondition(
          field: 'Final',
          operator: QueryOperator.lessThan,
          value: '20',
        ),
      ],
    ),
    QueryTemplate(
      name: 'Fantasy QB Performance',
      description: 'Games with high QB performance',
      category: 'Fantasy',
      conditions: [
        QueryCondition(
          field: 'QBR_tier',
          operator: QueryOperator.greaterThan,
          value: '7',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        title: Text(
          'Show Quick Ideas',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: templates.map((template) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ActionChip(
                    label: Text(template.name),
                    tooltip: template.description,
                    onPressed: () => onApplyTemplate(template.conditions),
                  ),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 