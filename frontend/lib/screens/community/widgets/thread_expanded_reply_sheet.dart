import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syntrak/screens/community/widgets/thread_media_attachments_bar.dart';

Future<void> showThreadExpandedReplySheet({
  required BuildContext context,
  required TextEditingController controller,
  required List<XFile> media,
  required bool isSubmitting,
  required VoidCallback onAddImages,
  required VoidCallback onSubmit,
  required void Function(int index) onRemove,
  required void Function(List<XFile> next) onSetMedia,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final viewInsets = MediaQuery.viewInsetsOf(ctx);
      final padBottom = MediaQuery.paddingOf(ctx).bottom;
      final sheetHeight = MediaQuery.sizeOf(ctx).height * 0.52;
      return Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: SizedBox(
          height: sheetHeight,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + padBottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Reply',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: Icon(Icons.close, color: Colors.grey.shade800),
                    ),
                  ],
                ),
                ThreadMediaAttachmentsBar(
                  files: media,
                  onRemove: onRemove,
                  onAddImages: onAddImages,
                  onAddVideo: () => pickThreadVideo(media, onSetMedia),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 4,
                    maxLines: 12,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      height: 1.35,
                    ),
                    cursorColor: Colors.black87,
                    decoration: InputDecoration(
                      hintText: 'Add your reply...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: isSubmitting
                        ? null
                        : () {
                            Navigator.of(ctx).pop();
                            onSubmit();
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Reply'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
