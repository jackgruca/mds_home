import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ff_draft_provider.dart';

class FFDraftTimer extends StatefulWidget {
  final int timePerPick;
  final VoidCallback onTimeExpired;

  const FFDraftTimer({
    super.key,
    required this.timePerPick,
    required this.onTimeExpired,
  });

  @override
  State<FFDraftTimer> createState() => _FFDraftTimerState();
}

class _FFDraftTimerState extends State<FFDraftTimer> {
  Timer? _timer;
  int _timeRemaining = 0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _timeRemaining = widget.timePerPick;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          if (_timeRemaining > 0) {
            _timeRemaining--;
          } else {
            _timer?.cancel();
            widget.onTimeExpired();
          }
        });
      }
    });
  }

  void _pauseTimer() {
    setState(() {
      _isPaused = true;
    });
  }

  void _resumeTimer() {
    setState(() {
      _isPaused = false;
    });
  }

  void _resetTimer() {
    setState(() {
      _timeRemaining = widget.timePerPick;
      _isPaused = false;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FFDraftProvider>(
      builder: (context, provider, child) {
        final currentPick = provider.getCurrentPick();
        if (currentPick == null) {
          _timer?.cancel();
          return const SizedBox.shrink();
        }

        // Start timer when it's the user's pick
        if (currentPick.isUserPick && _timer == null) {
          _startTimer();
        }

        return Container(
          padding: const EdgeInsets.all(8.0),
          color: currentPick.isUserPick
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey[100],
          child: Row(
            children: [
              // Current pick info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Pick: #${currentPick.pickNumber} (Round ${currentPick.round})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Team: ${currentPick.team.name}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Timer
              if (currentPick.isUserPick) ...[
                const SizedBox(width: 16),
                _buildTimerDisplay(),
                const SizedBox(width: 16),
                _buildTimerControls(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimerDisplay() {
    final minutes = (_timeRemaining / 60).floor();
    final seconds = _timeRemaining % 60;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        color: _timeRemaining <= 10
            ? Colors.red.withOpacity(0.1)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: _timeRemaining <= 10 ? Colors.red : null,
        ),
      ),
    );
  }

  Widget _buildTimerControls() {
    return Row(
      children: [
        IconButton(
          icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
          onPressed: _isPaused ? _resumeTimer : _pauseTimer,
          tooltip: _isPaused ? 'Resume' : 'Pause',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _resetTimer,
          tooltip: 'Reset',
        ),
      ],
    );
  }
} 