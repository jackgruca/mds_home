import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ff_draft_pick.dart';
import '../models/ff_position_constants.dart';
import '../providers/ff_draft_provider.dart';

class FFRollingPicks extends StatefulWidget {
  final Function(FFDraftPick) onPickSelected;
  final int timerKey;
  final int timePerPick;
  final VoidCallback onTimeExpired;
  final bool isPaused;
  final VoidCallback onPlayPause;
  final VoidCallback onUndo;

  const FFRollingPicks({
    super.key,
    required this.onPickSelected,
    required this.timerKey,
    required this.timePerPick,
    required this.onTimeExpired,
    required this.isPaused,
    required this.onPlayPause,
    required this.onUndo,
  });

  @override
  State<FFRollingPicks> createState() => _FFRollingPicksState();
}

class _FFRollingPicksState extends State<FFRollingPicks>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _timerController;
  int _remainingTime = 0;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      duration: Duration(seconds: widget.timePerPick),
      vsync: this,
    );
    _remainingTime = widget.timePerPick;
    _timerController.addListener(_updateTimer);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  void _updateTimer() {
    final newTime = (widget.timePerPick * (1 - _timerController.value)).ceil();
    if (newTime != _remainingTime) {
      setState(() {
        _remainingTime = newTime;
      });
    }
    
    if (_timerController.isCompleted) {
      widget.onTimeExpired();
    }
  }

  @override
  void didUpdateWidget(covariant FFRollingPicks oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reset timer if key changed
    if (oldWidget.timerKey != widget.timerKey) {
      _timerController.reset();
      _remainingTime = widget.timePerPick;
      
      // Start timer if it's user's turn and not paused
      final provider = Provider.of<FFDraftProvider>(context, listen: false);
      if (provider.isUserTurn() && !widget.isPaused) {
        _timerController.forward();
      }
    }
    
    // Handle play/pause state
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _timerController.stop();
      } else {
        final provider = Provider.of<FFDraftProvider>(context, listen: false);
        if (provider.isUserTurn()) {
          _timerController.forward();
        }
      }
    }
    
    // Scroll to current pick when timer key changes (new pick)
    if (oldWidget.timerKey != widget.timerKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<FFDraftProvider>(context, listen: false);
        final picks = provider.draftPicks;
        final currentPick = provider.getCurrentPick();
        final currentIndex = currentPick != null ? picks.indexOf(currentPick) : 0;
        
        _scrollToCurrentPick(currentIndex, 0, 0); // Simplified call
      });
    }
  }

  void _scrollToCurrentPick(int currentIndex, int start, int visibleLength) {
    if (!_scrollController.hasClients) return;
    
    // Calculate the position to center the current pick in the viewport
    const cardWidth = 140.0 + 6.0; // Card width + margin
    final viewportWidth = _scrollController.position.viewportDimension;
    final centerPosition = viewportWidth / 2;
    
    // Calculate target scroll position to center the current pick
    final targetPosition = (currentIndex * cardWidth) - centerPosition + (cardWidth / 2);
    
    // Clamp to valid scroll range
    final clampedPosition = targetPosition.clamp(
      0.0, 
      _scrollController.position.maxScrollExtent,
    );
    
    _scrollController.animateTo(
      clampedPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FFDraftProvider>(
      builder: (context, provider, child) {
        final picks = provider.draftPicks;
        final currentPick = provider.getCurrentPick();
        final isUserTurn = provider.isUserTurn();
        final currentIndex = currentPick != null ? picks.indexOf(currentPick) : 0;
        
        // Auto-scroll to center the current pick
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCurrentPick(currentIndex, 0, 0);
        });

        return Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              // Control panel - using new layout
              _buildControlPanel(context, provider),
              
              const SizedBox(width: 12),
              
              // Rolling picks - show all picks, scroll to center current
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: picks.length, // Show all picks, not just visible window
                  itemBuilder: (context, index) {
                    final pick = picks[index];
                    final isCurrent = pick == currentPick;
                    return _buildPickCard(context, pick, isCurrent);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPickCard(BuildContext context, FFDraftPick pick, bool isCurrent) {
    final isUserPick = pick.isUserPick;
    final provider = Provider.of<FFDraftProvider>(context, listen: false);
    final picksPerRound = provider.teams.length;
    final pickInRound = pick.pickNumber - (pick.round - 1) * picksPerRound;
    final pickLabel = '${pick.round}.$pickInRound ${pick.team.name}';
    final position = pick.selectedPlayer?.position;
    final Color posColor = _getPositionColor(position);
    
    return Container(
      width: 140,
      height: 88,
      margin: const EdgeInsets.only(right: 6),
      child: Container(
        decoration: BoxDecoration(
          color: pick.isSelected ? Colors.grey[50] : Colors.white,
          border: Border.all(
            color: isCurrent ? Colors.blue : Colors.grey[300]!,
            width: isCurrent ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            if (isCurrent)
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.2),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pick header
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: isCurrent ? Colors.blue : Colors.grey[600],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      pickLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (isUserPick) ...[
                  const SizedBox(width: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      'YOU',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Player info
            Expanded(
              child: pick.isSelected && pick.selectedPlayer != null 
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: posColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            position ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              pick.selectedPlayer!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${pick.selectedPlayer!.team} • ${pick.selectedPlayer!.position}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (pick.selectedPlayer!.adp < 999) ...[
                              const SizedBox(height: 1),
                              Text(
                                'ADP ${pick.selectedPlayer!.adp.toStringAsFixed(1)}',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 7,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Center(
                      child: Text(
                        isCurrent ? 'Picking...' : 'Upcoming',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPositionColor(String? position) {
    if (position == null) return Colors.grey;
    // Handle DST variations
    if (position == 'DEF' || position == 'D/ST') {
      return FFPositionConstants.getPositionColor('DST');
    }
    return FFPositionConstants.getPositionColor(position);
  }

  Widget _buildControlPanel(BuildContext context, FFDraftProvider provider) {
    final isUserTurn = provider.isUserTurn();
    final currentPick = provider.getCurrentPick();
    
    return Container(
      width: 160,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isUserTurn ? Colors.green[50] : Colors.grey[50],
        border: Border.all(
          color: isUserTurn ? Colors.green : Colors.grey[300]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Left side - Status info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status indicator
                Row(
                  children: [
                    Icon(
                      isUserTurn ? Icons.person : Icons.smart_toy,
                      size: 10,
                      color: isUserTurn ? Colors.green : Colors.grey[600],
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        isUserTurn ? 'YOUR TURN' : 'AI PICKING',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isUserTurn ? Colors.green : Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 2),
                
                // Round and pick info
                if (currentPick != null) ...[
                  Text(
                    'R${currentPick.round}, P${currentPick.pickNumber}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // Timer - only show during user turns
                  if (isUserTurn)
                    Text(
                      '${_remainingTime}s',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _remainingTime <= 10 ? Colors.red : Colors.green,
                      ),
                    ),
                ],
              ],
            ),
          ),
          
          const SizedBox(width: 4),
          
          // Right side - Control buttons (larger and more prominent)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Play/Pause button with conditional colors
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.isPaused 
                    ? Colors.green
                    : Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  onPressed: widget.onPlayPause,
                  icon: Icon(
                    widget.isPaused ? Icons.play_arrow : Icons.pause,
                    size: 18,
                    color: Colors.white,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
              
              const SizedBox(height: 2),
              
              // Undo button (blue)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  onPressed: widget.onUndo,
                  icon: const Icon(
                    Icons.undo,
                    size: 18,
                    color: Colors.white,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 