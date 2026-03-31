import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/providers/auth_provider.dart';

class NewThreadDraftResult {
  const NewThreadDraftResult({
    required this.content,
    this.topic,
  });

  final String content;
  final String? topic;
}

class NewThreadDraftScreen extends StatefulWidget {
  const NewThreadDraftScreen({super.key});

  @override
  State<NewThreadDraftScreen> createState() => _NewThreadDraftScreenState();
}

class _NewThreadDraftScreenState extends State<NewThreadDraftScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  bool _allowReplies = true;

  @override
  void dispose() {
    _contentController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  void _submit() {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;
    final topic = _topicController.text.trim();
    Navigator.of(context).pop(
      NewThreadDraftResult(
        content: content,
        topic: topic.isEmpty ? null : topic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final canPost = _contentController.text.trim().isNotEmpty;
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
              onPressed: canPost ? _submit : null,
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                minimumSize: const Size(64, 36),
                backgroundColor: canPost ? Colors.black87 : Colors.black26,
                foregroundColor: Colors.white,
              ),
              child: const Text('Post'),
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
                          decoration: const InputDecoration(
                            hintText: "What's new?",
                            hintStyle: TextStyle(color: Colors.black38),
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(Icons.image_outlined, color: Colors.black54),
                  SizedBox(width: 16),
                  Icon(Icons.gif_box_outlined, color: Colors.black54),
                  SizedBox(width: 16),
                  Icon(Icons.format_list_bulleted, color: Colors.black54),
                  SizedBox(width: 16),
                  Icon(Icons.format_quote, color: Colors.black54),
                  SizedBox(width: 16),
                  Icon(Icons.more_horiz, color: Colors.black54),
                ],
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
                    onPressed: canPost ? _submit : null,
                    style: FilledButton.styleFrom(
                      shape: const StadiumBorder(),
                      backgroundColor: canPost ? Colors.black87 : Colors.black26,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Post'),
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
