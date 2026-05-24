import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/providers/auth_provider.dart';

/// Twitter / Threads-style inline composer at the top of the feed.
class CompactComposer extends StatefulWidget {
  const CompactComposer({
    super.key,
    required this.onPost,
    this.maxCharacters = 280,
    this.onComposeTap,
  });

  final Function(String text) onPost;
  final int maxCharacters;
  final VoidCallback? onComposeTap;

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
    final canPost = widget.onComposeTap == null &&
        _characterCount > 0 &&
        _characterCount <= widget.maxCharacters;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            SyntrakSpacing.md,
            SyntrakSpacing.md,
            SyntrakSpacing.md,
            SyntrakSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: SyntrakColors.primary.withValues(alpha: 0.12),
                child: user?.firstName != null
                    ? Text(
                        user!.firstName![0].toUpperCase(),
                        style: SyntrakTypography.labelMedium.copyWith(
                          color: SyntrakColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : const Icon(
                        Icons.person_outline,
                        color: SyntrakColors.textSecondary,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      readOnly: widget.onComposeTap != null,
                      maxLines: _isExpanded ? 4 : 1,
                      maxLength: widget.maxCharacters,
                      style: SyntrakTypography.bodyLarge.copyWith(
                        color: SyntrakColors.textPrimary,
                      ),
                      onTap: () {
                        if (widget.onComposeTap != null) {
                          widget.onComposeTap!.call();
                          return;
                        }
                        if (!_isExpanded) {
                          setState(() => _isExpanded = true);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Start a thread…',
                        hintStyle: SyntrakTypography.bodyLarge.copyWith(
                          color: SyntrakColors.textTertiary,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        counterText: '',
                        isDense: true,
                      ),
                    ),
                    if (_isExpanded && widget.onComposeTap == null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: canPost ? _handlePost : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: SyntrakColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                SyntrakColors.primary.withValues(alpha: 0.35),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(SyntrakRadius.round),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Post',
                            style: SyntrakTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: SyntrakColors.divider),
      ],
    );
  }
}
