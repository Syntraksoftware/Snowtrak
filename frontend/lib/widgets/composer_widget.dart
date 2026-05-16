import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/providers/auth_provider.dart';

class ComposerWidget extends StatefulWidget {
  final Function(String text) onPost;
  final int maxCharacters;

  const ComposerWidget({
    super.key,
    required this.onPost,
    this.maxCharacters = 280,
  });

  @override
  State<ComposerWidget> createState() => _ComposerWidgetState();
}

class _ComposerWidgetState extends State<ComposerWidget> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _characterCount = 0;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        _characterCount = _textController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handlePost() {
    final text = _textController.text.trim();
    if (text.isNotEmpty && _characterCount <= widget.maxCharacters) {
      widget.onPost(text);
      _textController.clear();
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account details row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to profile
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: user?.firstName != null
                      ? null
                      : null, // TODO: Add avatar URL support
                  child: user?.firstName != null
                      ? Text(
                          user!.firstName![0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : const Icon(Icons.person, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              // Name and handle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.firstName != null && user?.lastName != null
                          ? '${user!.firstName} ${user.lastName}'
                          : (user?.email ?? 'User').split('@')[0],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (user != null && user.email.isNotEmpty)
                      Text(
                        '@${user.email.split('@')[0]}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Text input
          TextField(
            controller: _textController,
            focusNode: _focusNode,
            maxLines: null,
            maxLength: widget.maxCharacters,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: "What's new?",
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          // Actions row
          Row(
            children: [
              // Media icon
              IconButton(
                icon: Icon(
                  Icons.image_outlined,
                  size: 20,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  // TODO: Implement media picker
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
              const Spacer(),
              // Character count
              if (_characterCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Text(
                    '${_characterCount}/${widget.maxCharacters}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _characterCount > widget.maxCharacters
                          ? Colors.red
                          : Colors.grey[600],
                    ),
                  ),
                ),
              // Post button
              ElevatedButton(
                onPressed: _characterCount > 0 &&
                        _characterCount <= widget.maxCharacters
                    ? _handlePost
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4500),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Post',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}




