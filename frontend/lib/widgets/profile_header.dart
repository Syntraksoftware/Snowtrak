import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/auth/authenticated_session.dart';
import 'package:syntrak/core/di/service_locator.dart';
import 'package:syntrak/core/errors/app_result.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/profile.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/services/profile_service.dart';
import 'package:syntrak/ui/liquid/snowtrak_auth_theme.dart';

/// Profile identity block at the top of the profile screen.
class ProfileHeader extends StatefulWidget {
  const ProfileHeader({super.key, this.userId});

  final String? userId;

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  final ProfileService _profileService = sl<ProfileService>();
  Profile? _profile;
  bool _isLoading = true;
  String? _error;
  bool _hasLoaded = false;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    _lastUserId = widget.userId;
    _loadProfile();
  }

  @override
  void didUpdateWidget(ProfileHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _lastUserId = widget.userId;
      _hasLoaded = false;
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    if (_isLoading && _hasLoaded) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sessionOutcome = await ensureAuthenticatedSession(
      authProvider,
      viewUserId: widget.userId,
      requireUserId: true,
    );
    late final String userId;
    switch (sessionOutcome) {
      case AuthenticatedSessionError(:final message):
        if (mounted) {
          setState(() {
            _error = message;
            _isLoading = false;
          });
        }
        return;
      case AuthenticatedSessionOk(:final resolvedUserId):
        userId = resolvedUserId!;
    }

    final profileResult = await _profileService.getProfileById(userId);
    switch (profileResult) {
      case AppSuccess(:final value):
        if (mounted && _lastUserId == userId) {
          setState(() {
            _profile = value;
            _isLoading = false;
            _hasLoaded = true;
          });
        }
      case AppFailure(:final error):
        if (mounted && _lastUserId == userId) {
          setState(() {
            _error = error.userMessage;
            _isLoading = false;
            _hasLoaded = true;
          });
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = Provider.of<AuthProvider>(context).user;

    if (_isLoading && _profile == null) {
      if (widget.userId == null && authUser != null) {
        return _buildHeader(
          displayName: authUser.fullName,
          username: authUser.email.split('@').first,
          avatarUrl: null,
          bio: null,
          skiLevel: null,
          home: null,
        );
      }
      return const SizedBox.shrink();
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(SyntrakSpacing.md),
        child: Text(
          _error!,
          style: SyntrakTypography.bodyMedium.copyWith(color: SyntrakColors.error),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_profile == null) return const SizedBox.shrink();

    final profile = _profile!;
    return _buildHeader(
      displayName: profile.fullName ?? 'User',
      username: profile.username ?? '',
      avatarUrl: profile.avatarUrl,
      bio: profile.bio,
      skiLevel: profile.skiLevel,
      home: profile.home,
    );
  }

  Widget _buildHeader({
    required String displayName,
    required String username,
    required String? avatarUrl,
    required String? bio,
    required String? skiLevel,
    required String? home,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SyntrakSpacing.md,
        SyntrakSpacing.md,
        SyntrakSpacing.md,
        0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: SyntrakColors.surface,
          borderRadius: BorderRadius.circular(SyntrakRadius.lg),
          border: Border.all(color: SyntrakColors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(SyntrakSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor:
                        SnowtrakAuthTheme.brand.withValues(alpha: 0.12),
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : 'U',
                            style: SyntrakTypography.headlineMedium.copyWith(
                              color: SnowtrakAuthTheme.brand,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: SyntrakSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: SyntrakTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: SyntrakColors.textPrimary,
                          ),
                        ),
                        if (username.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '@$username',
                            style: SyntrakTypography.bodyMedium.copyWith(
                              color: SyntrakColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (bio != null && bio.isNotEmpty) ...[
                const SizedBox(height: SyntrakSpacing.md),
                Text(
                  bio,
                  style: SyntrakTypography.bodyMedium.copyWith(
                    color: SyntrakColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
              if (skiLevel != null || home != null) ...[
                const SizedBox(height: SyntrakSpacing.md),
                Wrap(
                  spacing: SyntrakSpacing.sm,
                  runSpacing: SyntrakSpacing.sm,
                  children: [
                    if (skiLevel != null)
                      _InfoChip(
                        icon: Icons.downhill_skiing,
                        label: skiLevel,
                        color: SnowtrakAuthTheme.brand,
                      ),
                    if (home != null)
                      _InfoChip(
                        icon: Icons.location_on_outlined,
                        label: home,
                        color: SyntrakColors.secondary,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SyntrakSpacing.sm,
        vertical: SyntrakSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(SyntrakRadius.round),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: SyntrakTypography.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
