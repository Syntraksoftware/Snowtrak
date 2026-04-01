import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/providers/auth_provider.dart';

class CompactComposer extends StatefulWidget {
  final Function(String text) onPost;
  final int maxCharacters;
  final VoidCallback? onComposeTap;

  const CompactComposer({
    super.key,
    required this.onPost,
    this.maxCharacters = 280,
    this.onComposeTap,
  });

  @override
  State<CompactComposer> createState() => _CompactComposerState();
}

class _CompactComposerState extends State<CompactComposer> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _characterCount = 0;
  bool _isExpanded = false;

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
      setState(() {
        _isExpanded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar - same size as message cards (radius 20)
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
            child: user?.firstName != null
                ? Text(
                    user!.firstName![0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  )
                : const Icon(Icons.person, color: Colors.grey, size: 20),
          ),
          const SizedBox(width: 12),
          // Text input
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              readOnly: widget.onComposeTap != null,
              maxLines: _isExpanded ? null : 1,
              maxLength: widget.maxCharacters,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
              onTap: () {
                if (widget.onComposeTap != null) {
                  widget.onComposeTap!.call();
                  return;
                }
                if (!_isExpanded) {
                  setState(() {
                    _isExpanded = true;
                  });
                }
              },
              decoration: InputDecoration(
                hintText: "What's new?",
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                counterText: '',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Post button
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: widget.onComposeTap ??
                  (_characterCount > 0 &&
                          _characterCount <= widget.maxCharacters
                      ? _handlePost
                      : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4500),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Post',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



