import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ff_draft_pick.dart';
import '../providers/ff_draft_provider.dart';

class FFDraftBoard extends StatelessWidget {
  final Function(FFDraftPick) onPickSelected;

  const FFDraftBoard({
    super.key,
    required this.onPickSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FFDraftProvider>(
      builder: (context, provider, child) {
        final settings = provider.settings;
        final picks = provider.draftPicks;
        final currentPick = provider.getCurrentPick();

        return Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  for (int i = 1; i <= settings.numTeams; i++)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: Colors.grey[200],
                        ),
                        child: Text(
                          'Team $i',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              
              // Draft picks grid
              Expanded(
                child: ListView.builder(
                  itemCount: (settings.rosterSize / settings.numTeams).ceil(),
                  itemBuilder: (context, roundIndex) {
                    final round = roundIndex + 1;
                    final startIndex = roundIndex * settings.numTeams;
                    final endIndex = (startIndex + settings.numTeams)
                        .clamp(0, picks.length);
                    
                    return Row(
                      children: [
                        // Round number
                        Container(
                          width: 40,
                          padding: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            color: Colors.grey[100],
                          ),
                          child: Text(
                            'R$round',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        
                        // Picks for this round
                        Expanded(
                          child: Row(
                            children: [
                              for (int i = startIndex; i < endIndex; i++)
                                Expanded(
                                  child: _buildPickCell(
                                    context,
                                    picks[i],
                                    picks[i] == currentPick,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPickCell(BuildContext context, FFDraftPick pick, bool isCurrentPick) {
    final theme = Theme.of(context);
    final isUserPick = pick.isUserPick;
    final isSelected = pick.isSelected;

    return GestureDetector(
      onTap: isUserPick && !isSelected ? () => onPickSelected(pick) : null,
      child: Container(
        margin: const EdgeInsets.all(2.0),
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: isCurrentPick ? theme.primaryColor : Colors.grey,
            width: isCurrentPick ? 2.0 : 1.0,
          ),
          color: isUserPick
              ? theme.primaryColor.withOpacity(0.1)
              : Colors.grey[100],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${pick.pickNumber}',
              style: TextStyle(
                fontSize: 12,
                color: isUserPick ? theme.primaryColor : Colors.grey[600],
              ),
            ),
            if (isSelected && pick.selectedPlayer != null) ...[
              const SizedBox(height: 4),
              Text(
                pick.selectedPlayer!.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                pick.selectedPlayer!.position,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 