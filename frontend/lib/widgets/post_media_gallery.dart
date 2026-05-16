import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Renders URLs from community `media_urls` (images / GIFs as image; mp4/mov/webm as inline video).
class PostMediaGallery extends StatelessWidget {
  const PostMediaGallery({super.key, required this.urls});

  final List<String> urls;

  static bool _looksVideo(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.mp4') ||
        lower.contains('.mov') ||
        lower.contains('.webm');
  }

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final url in urls)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _looksVideo(url)
                  ? PostInlineVideo(url: url)
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) {
                          return child;
                        }
                        return AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}

class PostInlineVideo extends StatefulWidget {
  const PostInlineVideo({super.key, required this.url});

  final String url;

  @override
  State<PostInlineVideo> createState() => _PostInlineVideoState();
}

class _PostInlineVideoState extends State<PostInlineVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => _controller = c);
      await c.setLooping(true);
      await c.play();
    } catch (_) {
      await c.dispose();
      if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.grey.shade900,
          child: Icon(
            Icons.videocam_off_outlined,
            color: Colors.grey.shade400,
            size: 40,
          ),
        ),
      );
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black87,
          child: const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            ),
          ),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
      child: VideoPlayer(c),
    );
  }
}
