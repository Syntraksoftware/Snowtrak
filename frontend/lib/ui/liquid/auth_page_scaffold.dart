import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/ui/liquid/auth_legal_footer.dart';
import 'package:syntrak/ui/liquid/snowtrak_auth_theme.dart';

/// Strava-style auth shell: white background, headline, optional close.
class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onClose,
    this.footer,
  });

  final String title;
  final Widget body;
  final VoidCallback? onClose;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyntrakColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SyntrakSpacing.lg,
                SyntrakSpacing.md,
                SyntrakSpacing.md,
                0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(title, style: SnowtrakAuthTheme.pageTitle),
                  ),
                  if (onClose != null)
                    IconButton(
                      onPressed: onClose,
                      style: IconButton.styleFrom(
                        backgroundColor: SyntrakColors.surfaceVariant,
                        shape: const CircleBorder(),
                      ),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  SyntrakSpacing.lg,
                  SyntrakSpacing.xl,
                  SyntrakSpacing.lg,
                  SyntrakSpacing.lg,
                ),
                child: body,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SyntrakSpacing.lg,
                0,
                SyntrakSpacing.lg,
                SyntrakSpacing.lg,
              ),
              child: footer ?? const AuthLegalFooter(),
            ),
          ],
        ),
      ),
    );
  }
}
