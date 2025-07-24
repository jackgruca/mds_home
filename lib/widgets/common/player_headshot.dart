import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/player_headshot_service.dart';
import '../../utils/team_logo_utils.dart';

class PlayerHeadshot extends StatefulWidget {
  final String playerName;
  final String? position;
  final String? team;
  final double size;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final bool showLoadingIndicator;
  final bool showTeamFallback;
  final Widget? customFallback;
  final EdgeInsets? padding;
  final int? loadDelay; // Stagger loading for better performance

  const PlayerHeadshot({
    super.key,
    required this.playerName,
    this.position,
    this.team,
    this.size = 40,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 1.0,
    this.showLoadingIndicator = true,
    this.showTeamFallback = true,
    this.customFallback,
    this.padding,
    this.loadDelay,
  });

  @override
  State<PlayerHeadshot> createState() => _PlayerHeadshotState();
}

class _PlayerHeadshotState extends State<PlayerHeadshot> {
  String? _headshotUrl;
  bool _isLoading = false;
  bool _hasAttemptedLoad = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  
  @override
  void initState() {
    super.initState();
    _loadHeadshot();
  }
  
  @override
  void didUpdateWidget(PlayerHeadshot oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if player changed
    if (oldWidget.playerName != widget.playerName ||
        oldWidget.team != widget.team ||
        oldWidget.position != widget.position) {
      _retryCount = 0;
      _loadHeadshot();
    }
  }
  
  Future<void> _loadHeadshot() async {
    if (widget.playerName.trim().isEmpty) return;
    if (_isLoading) return;
    
    // Add staggered delay if specified
    if (widget.loadDelay != null && _retryCount == 0) {
      await Future.delayed(Duration(milliseconds: widget.loadDelay!));
    }
    
    setState(() {
      _isLoading = true;
      _hasAttemptedLoad = true;
    });
    
    try {
      final url = await PlayerHeadshotService.getPlayerHeadshot(
        widget.playerName,
        position: widget.position,
        team: widget.team,
      );
      
      if (mounted) {
        setState(() {
          _headshotUrl = url;
          _isLoading = false;
        });
        
        // If failed but we have retries left, try again
        if (url == null && _retryCount < _maxRetries) {
          _retryCount++;
          // Exponential backoff: 500ms, 1s, 2s
          final delay = 500 * (1 << (_retryCount - 1));
          await Future.delayed(Duration(milliseconds: delay));
          if (mounted) {
            _loadHeadshot();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Retry on error
        if (_retryCount < _maxRetries) {
          _retryCount++;
          final delay = 500 * (1 << (_retryCount - 1));
          await Future.delayed(Duration(milliseconds: delay));
          if (mounted) {
            _loadHeadshot();
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.playerName.trim().isEmpty) {
      return _buildFallbackAvatar(context);
    }

    return Container(
      padding: widget.padding,
      child: _buildContent(context),
    );
  }
  
  Widget _buildContent(BuildContext context) {
    // Show loading only on first attempt
    if (_isLoading && !_hasAttemptedLoad && widget.showLoadingIndicator) {
      return _buildLoadingIndicator(context);
    }
    
    // Show headshot if we have URL
    if (_headshotUrl != null && _headshotUrl!.isNotEmpty) {
      return _buildHeadshotImage(context, _headshotUrl!);
    }
    
    // Show fallback
    return _buildFallbackAvatar(context);
  }

  Widget _buildHeadshotImage(BuildContext context, String imageUrl) {
    // Ensure HTTPS and proper URL formatting
    String processedUrl = imageUrl;
    if (imageUrl.startsWith('http://')) {
      processedUrl = imageUrl.replaceFirst('http://', 'https://');
    }
    
    // Handle NFL image URLs that might need different parameters
    if (processedUrl.contains('static.www.nfl.com')) {
      // Ensure the URL has proper format parameters
      if (!processedUrl.contains('f_auto')) {
        processedUrl = processedUrl.replaceAll('/upload/', '/upload/f_auto,q_auto/');
      }
    }
    
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: widget.showBorder
          ? Border.all(
              color: widget.borderColor ?? Colors.grey.shade300,
              width: widget.borderWidth,
            )
          : null,
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: processedUrl,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildLoadingIndicator(context),
          errorWidget: (context, url, error) {
            // Log the error for debugging
            debugPrint('🖼️ Failed to load headshot for ${widget.playerName}: $error');
            debugPrint('   URL: $processedUrl');
            return _buildFallbackAvatar(context);
          },
          memCacheWidth: (widget.size * 2).round(), // 2x for retina displays
          memCacheHeight: (widget.size * 2).round(),
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 100),
          // Add HTTP headers to help with CORS
          httpHeaders: const {
            'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
            'User-Agent': 'Mozilla/5.0 (compatible; Flutter)',
          },
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade100,
        border: widget.showBorder
          ? Border.all(
              color: widget.borderColor ?? Colors.grey.shade300,
              width: widget.borderWidth,
            )
          : null,
      ),
      child: Center(
        child: SizedBox(
          width: widget.size * 0.4,
          height: widget.size * 0.4,
          child: CircularProgressIndicator(
            strokeWidth: widget.size < 32 ? 1.5 : 2.0,
            valueColor: AlwaysStoppedAnimation(
              Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(BuildContext context) {
    // Use custom fallback if provided
    if (widget.customFallback != null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: widget.customFallback,
      );
    }

    // Try to show team logo as fallback if team is provided and showTeamFallback is true
    if (widget.showTeamFallback && widget.team != null && widget.team!.isNotEmpty) {
      return _buildTeamLogoFallback(context);
    }

    // Default fallback - generic person icon
    return _buildGenericFallback(context);
  }

  Widget _buildTeamLogoFallback(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade100,
        border: widget.showBorder
          ? Border.all(
              color: widget.borderColor ?? Colors.grey.shade300,
              width: widget.borderWidth,
            )
          : null,
      ),
      child: Center(
        child: TeamLogoUtils.buildNFLTeamLogo(
          widget.team!,
          size: widget.size * 0.6, // Team logo slightly smaller than container
        ),
      ),
    );
  }

  Widget _buildGenericFallback(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade200,
        border: widget.showBorder
          ? Border.all(
              color: widget.borderColor ?? Colors.grey.shade300,
              width: widget.borderWidth,
            )
          : null,
      ),
      child: Icon(
        Icons.person,
        size: widget.size * 0.5,
        color: Colors.grey.shade500,
      ),
    );
  }
}

/// Specialized widget for player headshots in list/table contexts
class PlayerHeadshotListTile extends StatelessWidget {
  final String playerName;
  final String? position;
  final String? team;
  final double size;
  final Widget? trailing;
  final VoidCallback? onTap;

  const PlayerHeadshotListTile({
    super.key,
    required this.playerName,
    this.position,
    this.team,
    this.size = 40,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: PlayerHeadshot(
        playerName: playerName,
        position: position,
        team: team,
        size: size,
      ),
      title: Text(
        playerName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: position != null || team != null
        ? Text([position, team].where((e) => e?.isNotEmpty == true).join(' • '))
        : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// Specialized widget for player headshots in card contexts
class PlayerHeadshotCard extends StatelessWidget {
  final String playerName;
  final String? position;
  final String? team;
  final double size;
  final Widget? child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const PlayerHeadshotCard({
    super.key,
    required this.playerName,
    this.position,
    this.team,
    this.size = 48,
    this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(12),
          child: Row(
            children: [
              PlayerHeadshot(
                playerName: playerName,
                position: position,
                team: team,
                size: size,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (position != null || team != null)
                      Text(
                        [position, team].where((e) => e?.isNotEmpty == true).join(' • '),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              if (child != null) child!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Utility widget for preloading headshots in bulk
class PlayerHeadshotPreloader extends StatefulWidget {
  final List<String> playerNames;
  final String? position;
  final Widget child;

  const PlayerHeadshotPreloader({
    super.key,
    required this.playerNames,
    this.position,
    required this.child,
  });

  @override
  State<PlayerHeadshotPreloader> createState() => _PlayerHeadshotPreloaderState();
}

class _PlayerHeadshotPreloaderState extends State<PlayerHeadshotPreloader> {
  bool _preloadingComplete = false;

  @override
  void initState() {
    super.initState();
    _preloadHeadshots();
  }

  Future<void> _preloadHeadshots() async {
    if (widget.playerNames.isNotEmpty) {
      await PlayerHeadshotService.preloadHeadshots(
        widget.playerNames,
        position: widget.position,
      );
    }
    if (mounted) {
      setState(() {
        _preloadingComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}