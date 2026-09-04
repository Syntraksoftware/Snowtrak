import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:provider/provider.dart';
import 'package:snowtrak/providers/auth_provider.dart';
import 'package:snowtrak/screens/community/mappers/community_author_mapper.dart';

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
        color: context.colors.surface,
        border: Border(
          bottom: BorderSide(
            color: context.colors.divider,
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
                  backgroundColor: context.colors.surfaceVariant,
                  backgroundImage: user?.firstName != null
                      ? null
                      : null, // TODO: Add avatar URL support
                  child: user?.firstName != null
                      ? Text(
                          user!.firstName![0].toUpperCase(),
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : Icon(Icons.person, color: context.colors.textTertiary),
                ),
              ),
              const SizedBox(width: 12),
              // Name and handle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The `@handle` line under this one is gone: the only
                    // handle available here was the email local part, which
                    // is a handle nobody chose.
                    // TODO(#43): show the real one once `User` carries a
                    // username -- that needs the auth payload to send it.
                    Text(
                      CommunityAuthorMapper.authorDisplayName(
                        firstName: user?.firstName,
                        lastName: user?.lastName,
                        fallback: user?.email ?? '',
                      ),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
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
            style: TextStyle(
              fontSize: 16,
              color: context.colors.textPrimary,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: "What's new?",
              hintStyle: TextStyle(
                color: context.colors.textTertiary,
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
                  color: context.colors.textSecondary,
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
                    '$_characterCount/${widget.maxCharacters}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _characterCount > widget.maxCharacters
                          ? context.colors.error
                          : context.colors.textSecondary,
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
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.textOnPrimary,
                  disabledBackgroundColor: context.colors.surfaceVariant,
                  disabledForegroundColor: context.colors.textQuaternary,
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




