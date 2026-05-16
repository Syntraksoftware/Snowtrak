import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const int kThreadMediaMaxAttachments = 4;

/// Thumbnail strip with remove controls (no add buttons). Use above a compact toolbar.
class ThreadMediaPreviewStrip extends StatelessWidget {
  const ThreadMediaPreviewStrip({
    super.key,
    required this.files,
    required this.onRemove,
  });

  final List<XFile> files;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = files[i];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Image.file(
                    File(f.path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: Colors.grey.shade300,
                      child: Icon(Icons.insert_drive_file,
                          color: Colors.grey.shade600),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Material(
                  color: Colors.black87,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () => onRemove(i),
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Pick + preview row for thread post / reply media (images, GIF, short video).
class ThreadMediaAttachmentsBar extends StatelessWidget {
  const ThreadMediaAttachmentsBar({
    super.key,
    required this.files,
    required this.onRemove,
    required this.onAddImages,
    required this.onAddVideo,
  });

  final List<XFile> files;
  final void Function(int index) onRemove;
  final VoidCallback onAddImages;
  final VoidCallback onAddVideo;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return Row(
        children: [
          IconButton(
            tooltip: 'Photo',
            onPressed: onAddImages,
            icon: Icon(Icons.image_outlined, color: Colors.grey.shade700),
          ),
          IconButton(
            tooltip: 'Video',
            onPressed: onAddVideo,
            icon: Icon(Icons.videocam_outlined, color: Colors.grey.shade700),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ThreadMediaPreviewStrip(files: files, onRemove: onRemove),
        if (files.length < kThreadMediaMaxAttachments)
          Row(
            children: [
              IconButton(
                tooltip: 'Add photo',
                onPressed: onAddImages,
                icon: Icon(Icons.add_photo_alternate_outlined,
                    color: Colors.grey.shade700, size: 22),
              ),
              IconButton(
                tooltip: 'Add video',
                onPressed: onAddVideo,
                icon: Icon(Icons.video_call_outlined,
                    color: Colors.grey.shade700, size: 22),
              ),
            ],
          ),
      ],
    );
  }
}

/// Opens gallery for multiple images (respects [kThreadMediaMaxAttachments]).
Future<void> pickThreadImages(
  List<XFile> current,
  void Function(List<XFile>) setFiles,
) async {
  final picker = ImagePicker();
  final picked = await picker.pickMultiImage(imageQuality: 85);
  if (picked.isEmpty) {
    return;
  }
  final next = List<XFile>.from(current);
  for (final f in picked) {
    if (next.length >= kThreadMediaMaxAttachments) {
      break;
    }
    next.add(f);
  }
  setFiles(next);
}

Future<void> pickThreadVideo(
  List<XFile> current,
  void Function(List<XFile>) setFiles,
) async {
  if (current.length >= kThreadMediaMaxAttachments) {
    return;
  }
  final picker = ImagePicker();
  final f = await picker.pickVideo(source: ImageSource.gallery);
  if (f == null) {
    return;
  }
  setFiles([...current, f]);
}
