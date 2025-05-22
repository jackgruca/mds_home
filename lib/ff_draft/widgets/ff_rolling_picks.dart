import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ff_draft_pick.dart';
import '../providers/ff_draft_provider.dart';

class FFRollingPicks extends StatefulWidget {
  final Function(FFDraftPick) onPickSelected;

  const FFRollingPicks({
    super.key,
    required this.onPickSelected,
  });

  @override
  State<FFRollingPicks> createState() => _FFRollingPicksState();
}

class _FFRollingPicksState extends State<FFRollingPicks> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant FFRollingPicks oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentPick());
  }

  void _scrollToCurrentPick() {
    final provider = Provider.of<FFDraftProvider>(context, listen: false);
    final picks = provider.draftPicks;
    final currentPick = provider.getCurrentPick();
    final currentIndex = currentPick != null ? picks.indexOf(currentPick) : 0;
    const cardWidth = 180.0;
    const padding = 8.0;
    const windowSize = 7;
    const halfWindow = windowSize ~/ 2;
    final offset = (currentIndex - halfWindow).clamp(0, picks.length - windowSize) * (cardWidth + padding);
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FFDraftProvider>(
      builder: (context, provider, child) {
        final picks = provider.draftPicks;
        final currentPick = provider.getCurrentPick();
        final currentIndex = currentPick != null ? picks.indexOf(currentPick) : 0;
        const windowSize = 7;
        const halfWindow = windowSize ~/ 2;
        int start = (currentIndex - halfWindow).clamp(0, picks.length - windowSize);
        int end = (start + windowSize).clamp(0, picks.length);
        if (end - start < windowSize) {
          start = (end - windowSize).clamp(0, picks.length - windowSize);
        }
        final visiblePicks = picks.sublist(start, end);

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentPick());

        return Container(
          height: 120,
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: picks.length,
            itemBuilder: (context, index) {
              final pick = picks[index];
              final isCurrent = pick == currentPick;
              return _buildPickCard(context, pick, isCurrent);
            },
          ),
        );
      },
    );
  }

  Widget _buildPickCard(BuildContext context, FFDraftPick pick, bool isCurrent) {
    final isUserPick = pick.isUserPick;
    final picksPerRound = Provider.of<FFDraftProvider>(context, listen: false).teams.length;
    final pickInRound = pick.pickNumber - (pick.round - 1) * picksPerRound;
    final pickLabel = '${pick.round}.$pickInRound ${pick.team.name}';
    final position = pick.selectedPlayer?.position;
    final Color posColor = _getPositionColor(position);
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: isCurrent
            ? Colors.blue.withOpacity(0.2)
            : (pick.selectedPlayer != null
                ? posColor.withOpacity(0.18)
                : Colors.grey[100]),
        border: Border.all(
          color: isCurrent
              ? Colors.blue
              : isUserPick
                  ? Colors.blue
                  : (pick.selectedPlayer != null ? posColor : Colors.grey),
          width: isCurrent ? 3 : (isUserPick ? 2 : 1),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: isUserPick ? () => widget.onPickSelected(pick) : null,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pickLabel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCurrent ? Colors.blue : (isUserPick ? Colors.blue : null),
                ),
              ),
              if (pick.selectedPlayer != null) ...[
                const SizedBox(height: 4),
                Text(
                  pick.selectedPlayer!.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  pick.selectedPlayer!.position,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getPositionColor(String? position) {
    switch (position) {
      case 'QB':
        return Colors.blue;
      case 'RB':
        return Colors.green;
      case 'WR':
        return Colors.orange;
      case 'TE':
        return Colors.purple;
      case 'K':
        return Colors.red;
      case 'DEF':
      case 'D/ST':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
} 