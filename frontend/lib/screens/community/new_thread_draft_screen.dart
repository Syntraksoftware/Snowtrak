import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/di/service_locator.dart';
import 'package:syntrak/core/errors/app_result.dart';
import 'package:syntrak/models/post.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/screens/community/thread_media_upload.dart';
import 'package:syntrak/screens/community/widgets/quoted_post_embed.dart';
import 'package:syntrak/screens/community/widgets/thread_media_attachments_bar.dart';
import 'package:syntrak/services/community_service.dart';

class NewThreadDraftResult {
  const NewThreadDraftResult({
    required this.content,
    this.topic,
    this.quotedPostId,
    this.quotedCommentId,
    this.mediaUrls = const [],
  });

  final String content;
  final String? topic;
  /// Set when composing a quote of a post; sent as [quoted_post_id] on create.
  final String? quotedPostId;
  /// Set when composing a quote of a thread comment; sent as [quoted_comment_id] on create.
  final String? quotedCommentId;
  final List<String> mediaUrls;
}

class NewThreadDraftScreen extends StatefulWidget {
  const NewThreadDraftScreen({super.key, this.quotedPost});

  /// When non-null, user is quoting this post (adds embed + sends id on post).
  final Post? quotedPost;

  @override
  State<NewThreadDraftScreen> createState() => _NewThreadDraftScreenState();
}

class _NewThreadDraftScreenState extends State<NewThreadDraftScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  bool _allowReplies = true;
  final List<XFile> _attachments = [];
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _contentController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  bool get _canPost =>
      _contentController.text.trim().isNotEmpty || _attachments.isNotEmpty;

  Future<void> _submit() async {
    if (!_canPost || _isPosting) {
      return;
    }
    final content = _contentController.text.trim();
    final topic = _topicController.text.trim();
    final q = widget.quotedPost;

    setState(() => _isPosting = true);
    var mediaUrls = <String>[];
    if (_attachments.isNotEmpty) {
      final service = sl<CommunityService>();
      final uploaded = await uploadThreadMediaFiles(service, _attachments);
      switch (uploaded) {
        case AppSuccess(:final value):
          mediaUrls = value;
        case AppFailure(:final error):
          if (mounted) {
            setState(() => _isPosting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.userMessage)),
            );
          }
          return;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() => _isPosting = false);
    Navigator.of(context).pop(
      NewThreadDraftResult(
        content: content,
        topic: topic.isEmpty ? null : topic,
        quotedPostId: q != null && !q.isComment ? q.id : null,
        quotedCommentId: q != null && q.isComment ? q.id : null,
        mediaUrls: mediaUrls,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final canPost = _canPost && !_isPosting;
    final isQuote = widget.quotedPost != null;
    final displayName = user?.firstName ?? user?.email.split('@').first ?? 'Member';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
        ),
        leadingWidth: 72,
        title: const Text('New thread'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.sticky_note_2_outlined),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: canPost ? () => _submit() : null,
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                minimumSize: const Size(64, 36),
                backgroundColor: canPost ? Colors.black87 : Colors.black26,
                foregroundColor: Colors.white,
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Post'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey.shade300,
                    child: Text(initial),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '>',
                              style: TextStyle(color: Colors.black45),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: TextField(
                                controller: _topicController,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 15,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Community or topic',
                                  hintStyle: TextStyle(color: Colors.black38),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextField(
                          controller: _contentController,
                          maxLines: null,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 20,
                            height: 1.35,
                          ),
                          decoration: InputDecoration(
                            hintText: isQuote
                                ? 'Share your thoughts...'
                                : "What's new?",
                            hintStyle: const TextStyle(color: Colors.black38),
                            border: InputBorder.none,
                          ),
                        ),
                        if (isQuote) ...[
                          const SizedBox(height: 14),
                          QuotedPostEmbed(post: widget.quotedPost!),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ThreadMediaAttachmentsBar(
                files: _attachments,
                onRemove: (i) => setState(() => _attachments.removeAt(i)),
                onAddImages: () => pickThreadImages(
                  _attachments,
                  (next) => setState(() {
                    _attachments
                      ..clear()
                      ..addAll(next);
                  }),
                ),
                onAddVideo: () => pickThreadVideo(
                  _attachments,
                  (next) => setState(() {
                    _attachments
                      ..clear()
                      ..addAll(next);
                  }),
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.black38, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Add to thread',
                    style: TextStyle(color: Colors.black38),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  const Text(
                    'Reply options',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const Spacer(),
                  Switch(
                    value: _allowReplies,
                    onChanged: (v) => setState(() => _allowReplies = v),
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed: canPost ? () => _submit() : null,
                    style: FilledButton.styleFrom(
                      shape: const StadiumBorder(),
                      backgroundColor: canPost ? Colors.black87 : Colors.black26,
                      foregroundColor: Colors.white,
                    ),
                    child: _isPosting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Post'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 34,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xFFF4F5F7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
