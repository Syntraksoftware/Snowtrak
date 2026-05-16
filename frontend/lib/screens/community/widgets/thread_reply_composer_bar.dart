import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syntrak/screens/community/widgets/thread_media_attachments_bar.dart';
import 'package:syntrak/screens/community/widgets/thread_reply_toolbar_glyphs.dart';

class ThreadReplyComposerBar extends StatelessWidget {
  const ThreadReplyComposerBar({
    super.key,
    required this.replyMedia,
    required this.controller,
    required this.focusNode,
    required this.onRemoveMedia,
    required this.onSubmit,
    required this.onPickImages,
    required this.onExpand,
  });

  final List<XFile> replyMedia;
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(int index) onRemoveMedia;
  final VoidCallback onSubmit;
  final VoidCallback onPickImages;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (replyMedia.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ThreadMediaPreviewStrip(
                files: replyMedia,
                onRemove: onRemoveMedia,
              ),
            ),
          Material(
            elevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(28),
            color: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey.shade400,
                      child: const Icon(
                        Icons.person_outline,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => onSubmit(),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          height: 1.3,
                        ),
                        cursorColor: Colors.black87,
                        decoration: InputDecoration(
                          hintText: 'Add your reply...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      tooltip: 'Photo',
                      onPressed: onPickImages,
                      icon: ReplyToolbarPhotoGlyph(color: Colors.grey.shade900),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      tooltip: 'GIF or image',
                      onPressed: onPickImages,
                      icon: ReplyToolbarGifGlyph(color: Colors.grey.shade900),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      tooltip: 'Expand',
                      onPressed: onExpand,
                      icon: Icon(
                        Icons.open_in_full,
                        size: 21,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
