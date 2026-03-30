import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/providers/auth_provider.dart';

class ActivitiesHeader extends StatelessWidget {
  const ActivitiesHeader({
    super.key,
    required this.onAvatarTap,
  });

  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SyntrakSpacing.md,
        SyntrakSpacing.md,
        SyntrakSpacing.md,
        SyntrakSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40),
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final user = authProvider.user;
              return GestureDetector(
                onTap: onAvatarTap,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: SyntrakColors.primary,
                  child: user?.firstName != null
                      ? Text(
                          user!.firstName![0].toUpperCase(),
                          style: SyntrakTypography.headlineSmall.copyWith(
                            color: SyntrakColors.textOnPrimary,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: SyntrakColors.textOnPrimary,
                          size: 20,
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
