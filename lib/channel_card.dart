import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'player_screen.dart';

class ChannelCard extends StatefulWidget {
  final dynamic channel;
  final bool isGrid;
  final Color cardColor;
  final Color surfaceColor;
  final Color accentColor;
  final Color accentLight;
  final Color textPrimary;
  final Color textSecondary;

  const ChannelCard({
    super.key,
    required this.channel,
    required this.isGrid,
    required this.cardColor,
    required this.surfaceColor,
    required this.accentColor,
    required this.accentLight,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  State<ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<ChannelCard> {
  bool _isHovered = false;
  Player? _player;
  VideoController? _controller;
  bool _isPlaying = false;
  Timer? _hoverTimer;

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _disposePlayer();
    super.dispose();
  }

  void _disposePlayer() {
    if (_player != null) {
      _player!.dispose();
      _player = null;
      _controller = null;
    }
    _isPlaying = false;
  }

  void _initPlayer() {
    if (_player != null || !mounted) return;
    
    _player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 8 * 1024 * 1024, // 8MB buffer for faster preview start
      ),
    );
    _player!.setVolume(0.0); // Mute preview
    _controller = VideoController(_player!);
    
    _player!.open(Media(widget.channel['stream_url']), play: true);
    
    if (mounted) {
      setState(() {
        _isPlaying = true;
      });
    }
  }

  void _onHover(bool isHovered) {
    if (isHovered == _isHovered) return;
    
    setState(() {
      _isHovered = isHovered;
    });

    _hoverTimer?.cancel();

    if (isHovered) {
      // Small delay so we don't start the player if the user is just passing by
      _hoverTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted && _isHovered) {
          _initPlayer();
        }
      });
    } else {
      if (_isPlaying) {
        setState(() {
          _disposePlayer();
        });
      }
    }
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    if (text == 'UNKNOWN') return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildFallbackThumbnail(String name, double size) {
    // Generate a fallback thumbnail based on the initials
    String initials = "TV";
    if (name.isNotEmpty) {
      final words = name.split(RegExp(r'\s+'));
      if (words.length > 1) {
        initials = '${words[0][0]}${words[1][0]}'.toUpperCase();
      } else {
        initials = name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
      }
    }
    
    // Hash name to get a colorful gradient
    int hash = name.hashCode;
    Color c1 = Colors.primaries[hash % Colors.primaries.length];
    Color c2 = Colors.primaries[(hash + 1) % Colors.primaries.length];

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c1.withOpacity(0.4), c2.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailArea(String name, String logo, double fallbackSize) {
    // If hovering and player is ready, show video preview
    if (_isHovered && _isPlaying && _controller != null) {
      return Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Video(
              controller: _controller!,
              controls: NoVideoControls, // hide UI for preview
              fit: BoxFit.cover,
            ),
            // LIVE badge overlay
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }
    
    // Otherwise show static thumbnail/logo
    if (logo.isNotEmpty) {
      return Image.network(
        logo,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallbackThumbnail(name, fallbackSize),
      );
    }
    
    return _buildFallbackThumbnail(name, fallbackSize);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.channel['name'] ?? 'Unknown Channel';
    final category = widget.channel['parsed_category'] ?? 'general';
    final language = widget.channel['parsed_language'] ?? 'unknown';
    final country = widget.channel['parsed_country'] ?? 'unknown';
    final logo = widget.channel['logo']?.toString() ?? '';

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: widget.isGrid 
        ? _buildGridCard(name, category, language, country, logo)
        : _buildListCard(name, category, language, country, logo),
    );
  }

  Widget _buildGridCard(String name, String category, String language, String country, String logo) {
    return Container(
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isHovered ? widget.accentLight : Colors.white.withOpacity(0.05),
          width: _isHovered ? 2 : 1,
        ),
        boxShadow: _isHovered ? [
          BoxShadow(
            color: widget.accentColor.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          )
        ] : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14), // slightly less than 16 to fit inside border
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashColor: widget.accentColor.withOpacity(0.15),
            highlightColor: widget.accentColor.withOpacity(0.05),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(
                    channelName: name,
                    streamUrl: widget.channel['stream_url'],
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.surfaceColor,
                    ),
                    padding: _isPlaying ? EdgeInsets.zero : const EdgeInsets.all(20),
                    child: _buildThumbnailArea(name, logo, 48),
                  ),
                ),
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.accentColor, const Color(0xFF3F51B5)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: widget.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildBadge(category.toUpperCase(), widget.accentColor.withOpacity(0.15), widget.accentLight),
                            _buildBadge(language.toUpperCase(), Colors.blue.withOpacity(0.15), Colors.blue[300]!),
                            _buildBadge(country.toUpperCase(), Colors.green.withOpacity(0.15), Colors.green[300]!),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(String name, String category, String language, String country, String logo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isHovered ? widget.accentLight : Colors.white.withOpacity(0.05),
          width: _isHovered ? 2 : 1,
        ),
        boxShadow: _isHovered ? [
          BoxShadow(
            color: widget.accentColor.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ] : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashColor: widget.accentColor.withOpacity(0.15),
            highlightColor: widget.accentColor.withOpacity(0.05),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(
                    channelName: name,
                    streamUrl: widget.channel['stream_url'],
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Logo / avatar
                  Container(
                    width: 72,
                    height: 56,
                    decoration: BoxDecoration(
                      color: widget.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildThumbnailArea(name, logo, 28),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: widget.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildBadge(category.toUpperCase(), widget.accentColor.withOpacity(0.15), widget.accentLight),
                              _buildBadge(language.toUpperCase(), Colors.blue.withOpacity(0.15), Colors.blue[300]!),
                              _buildBadge(country.toUpperCase(), Colors.green.withOpacity(0.15), Colors.green[300]!),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Play button
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [widget.accentColor, const Color(0xFF3F51B5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
