import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:simple_pip_mode/pip_widget.dart';
import 'package:simple_pip_mode/simple_pip.dart';
import 'package:window_manager/window_manager.dart';
import 'channel_card.dart';

class PlayerScreen extends StatefulWidget {
  final String channelName;
  final String streamUrl;
  final List<dynamic> allChannels;

  const PlayerScreen({
    super.key,
    required this.channelName,
    required this.streamUrl,
    required this.allChannels,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with WindowListener {
  late final Player player;
  late final VideoController controller;
  bool _isWindowsPip = false;
  Size? _previousSize;
  Offset? _previousPosition;
  String? _errorMessage;

  late String _currentChannelName;
  late String _currentStreamUrl;

  @override
  void initState() {
    super.initState();
    _currentChannelName = widget.channelName;
    _currentStreamUrl = widget.streamUrl;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.addListener(this);
    }
    player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 64 * 1024 * 1024,
      ),
    );
    controller = VideoController(player);
    player.open(Media(_currentStreamUrl));
    
    player.stream.error.listen((error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
        });
      }
    });
    
    _initPip();
  }

  void _initPip() async {
    if (Platform.isAndroid) {
      bool isAvailable = await SimplePip.isPipAvailable;
      if (isAvailable) {
        SimplePip().setAutoPipMode();
      }
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    player.dispose();
    super.dispose();
  }

  void _switchChannel(dynamic ch) {
    setState(() {
      _currentChannelName = ch['name'] ?? 'Unknown Channel';
      _currentStreamUrl = ch['stream_url'];
      _errorMessage = null;
    });
    player.open(Media(_currentStreamUrl));
  }

  Future<void> _toggleWindowsPip() async {
    if (!Platform.isWindows) return;
    
    if (_isWindowsPip) {
      // Exit PIP
      setState(() => _isWindowsPip = false);
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setTitleBarStyle(TitleBarStyle.normal);
      if (_previousSize != null) {
        await windowManager.setSize(_previousSize!);
      }
      if (_previousPosition != null) {
        await windowManager.setPosition(_previousPosition!);
      }
    } else {
      // Enter PIP
      _previousSize = await windowManager.getSize();
      _previousPosition = await windowManager.getPosition();
      setState(() => _isWindowsPip = true);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.setSize(const Size(400, 225)); // 16:9 ratio
      await windowManager.setAlignment(Alignment.bottomRight);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget videoWidget = _errorMessage != null
        ? Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Unable to play stream',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        : Video(
            controller: controller,
            controls: _isWindowsPip ? NoVideoControls : AdaptiveVideoControls,
          );

    // If on Windows and in PIP, render without scaffold/appbar
    if (_isWindowsPip) {
      return GestureDetector(
        onDoubleTap: _toggleWindowsPip,
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              Center(child: videoWidget),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                  onPressed: _toggleWindowsPip,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget scaffold = Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        title: Text(_currentChannelName),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        actions: [
          if (Platform.isAndroid)
            IconButton(
              icon: const Icon(Icons.picture_in_picture),
              onPressed: () => SimplePip().enterPipMode(),
            ),
          if (Platform.isWindows)
            IconButton(
              icon: const Icon(Icons.picture_in_picture),
              onPressed: _toggleWindowsPip,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: videoWidget,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: widget.allChannels.length,
                itemBuilder: (context, index) {
                  final ch = widget.allChannels[index];
                  if ((ch['name'] ?? '') == _currentChannelName) {
                    return const SizedBox.shrink();
                  }

                  return ChannelCard(
                    channel: ch,
                    allChannels: widget.allChannels,
                    isGrid: false,
                    cardColor: const Color(0xFF16213E),
                    surfaceColor: const Color(0xFF1A1A2E),
                    accentColor: const Color(0xFF9C27B0),
                    accentLight: const Color(0xFFCE93D8),
                    textPrimary: const Color(0xFFE8EAF6),
                    textSecondary: const Color(0xFF7986CB),
                    onTap: () => _switchChannel(ch),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (Platform.isAndroid) {
      return PipWidget(
        pipBuilder: (context) {
          return Container(
            color: Colors.black,
            child: videoWidget,
          );
        },
        child: scaffold,
      );
    }
    
    return scaffold;
  }
}
