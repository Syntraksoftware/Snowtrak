import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/ui/liquid/auth_legal_footer.dart';
import 'package:snowtrak/ui/liquid/snowtrak_auth_theme.dart';

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
      backgroundColor: SnowtrakColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SnowtrakSpacing.lg,
                SnowtrakSpacing.md,
                SnowtrakSpacing.md,
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
                        backgroundColor: SnowtrakColors.surfaceVariant,
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
                  SnowtrakSpacing.lg,
                  SnowtrakSpacing.xl,
                  SnowtrakSpacing.lg,
                  SnowtrakSpacing.lg,
                ),
                child: body,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SnowtrakSpacing.lg,
                0,
                SnowtrakSpacing.lg,
                SnowtrakSpacing.lg,
              ),
              child: footer ?? const AuthLegalFooter(),
            ),
          ],
        ),
      ),
    );
  }
}
