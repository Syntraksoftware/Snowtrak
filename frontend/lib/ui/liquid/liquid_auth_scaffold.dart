import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/widgets/logo_icon.dart';

/// Shared auth layout: soft gradient backdrop and centered content.
class LiquidAuthScaffold extends StatelessWidget {
  const LiquidAuthScaffold({
    super.key,
    this.leading,
    required this.title,
    required this.body,
    this.footer,
  });

  final Widget? leading;
  final String title;
  final Widget body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    SyntrakColors.darkBackground,
                    const Color(0xFF1A237E).withValues(alpha: 0.35),
                    SyntrakColors.darkBackground,
                  ]
                : [
                    const Color(0xFFE3F2FD),
                    SyntrakColors.background,
                    const Color(0xFFE0F7FA),
                  ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: SyntrakSpacing.lg,
                  vertical: SyntrakSpacing.xl,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (leading != null) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: leading!,
                        ),
                        const SizedBox(height: SyntrakSpacing.md),
                      ],
                      const SizedBox(height: SyntrakSpacing.lg),
                      const Center(
                        child: LogoIcon(
                          size: 56,
                          logoType: 'light',
                        ),
                      ),
                      const SizedBox(height: SyntrakSpacing.md),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: SyntrakTypography.displaySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: SyntrakSpacing.xl),
                      Center(child: body),
                      if (footer != null) ...[
                        const SizedBox(height: SyntrakSpacing.lg),
                        footer!,
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
