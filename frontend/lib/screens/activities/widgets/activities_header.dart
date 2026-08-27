import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/providers/auth_provider.dart';
import 'package:snowtrak/ui/liquid/snowtrak_auth_theme.dart';

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
        SnowtrakSpacing.md,
        SnowtrakSpacing.sm,
        SnowtrakSpacing.md,
        SnowtrakSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                style: SnowtrakAuthTheme.pageTitle(context).copyWith(fontSize: 28),
                children: [
                  TextSpan(
                    text: 'Welcome back, ',
                    style: SnowtrakTypography.bodyLarge.copyWith(
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 22,
                      height: 1.2,
                    ),
                  ),
                  TextSpan(
                    text: username,
                    style: SnowtrakAuthTheme.pageTitle(context).copyWith(
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
          const SizedBox(width: SnowtrakSpacing.sm),
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final user = authProvider.user;
              return Material(
                color: context.colors.primary,
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
                              style: SnowtrakTypography.headlineSmall.copyWith(
                                color: context.colors.textOnPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              color: context.colors.textOnPrimary,
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
