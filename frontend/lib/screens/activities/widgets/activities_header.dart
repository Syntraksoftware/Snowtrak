import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/ui/liquid/snowtrak_auth_theme.dart';

class ActivitiesHeader extends StatelessWidget {
  const ActivitiesHeader({
    super.key,
    required this.onAvatarTap,
    required this.username,
  });

  final VoidCallback onAvatarTap;
  final String username;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SyntrakSpacing.md,
        SyntrakSpacing.sm,
        SyntrakSpacing.md,
        SyntrakSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                style: SnowtrakAuthTheme.pageTitle.copyWith(fontSize: 28),
                children: [
                  TextSpan(
                    text: 'Welcome back, ',
                    style: SyntrakTypography.bodyLarge.copyWith(
                      color: SyntrakColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 22,
                      height: 1.2,
                    ),
                  ),
                  TextSpan(
                    text: username,
                    style: SnowtrakAuthTheme.pageTitle.copyWith(
                      fontSize: 28,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: SyntrakSpacing.sm),
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final user = authProvider.user;
              return Material(
                color: SnowtrakAuthTheme.brand,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onAvatarTap,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: user?.firstName != null
                          ? Text(
                              user!.firstName![0].toUpperCase(),
                              style: SyntrakTypography.headlineSmall.copyWith(
                                color: SyntrakColors.textOnPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: SyntrakColors.textOnPrimary,
                              size: 22,
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
