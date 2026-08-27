import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Renders URLs from community `media_urls` (images / GIFs as image; mp4/mov/webm as inline video).
class PostMediaGallery extends StatelessWidget {
  const PostMediaGallery({
    super.key,
    required this.urls,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.height,
  });

  final List<String> urls;
  final BorderRadius borderRadius;
  final double? height;

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
              borderRadius: borderRadius,
              child: height != null
                  ? SizedBox(
                      height: height,
                      width: double.infinity,
                      child: _mediaForUrl(url, height: height),
                    )
                  : _mediaForUrl(url),
            ),
          ),
      ],
    );
  }

  Widget _mediaForUrl(String url, {double? height}) {
    if (_looksVideo(url)) {
      return PostInlineVideo(url: url);
    }

    final image = CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: height,
      placeholder: (_, __) => AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(color: Colors.grey.shade200),
      ),
      errorWidget: (_, __, ___) => AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          color: Colors.grey.shade200,
          child: Icon(Icons.broken_image_outlined,
              size: 40, color: Colors.grey.shade500),
        ),
      ),
    );

    if (height != null) {
      return image;
    }
    return AspectRatio(aspectRatio: 4 / 3, child: image);
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
  bool _tapped = false; // ponytail: lazy init — don't load video until tap

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
    if (!_tapped || (c == null || !c.value.isInitialized)) {
      return GestureDetector(
        onTap: () {
          if (!_tapped) {
            setState(() => _tapped = true);
            _init();
          }
        },
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black87,
            child: Center(
              child: _tapped
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white70),
                    )
                  : const Icon(Icons.play_circle_outline,
                      color: Colors.white70, size: 48),
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
