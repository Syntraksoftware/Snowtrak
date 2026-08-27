import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snowtrak/core/auth/authenticated_session.dart';
import 'package:snowtrak/core/di/service_locator.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/profile.dart';
import 'package:snowtrak/providers/auth_provider.dart';
import 'package:snowtrak/screens/profile/follow_requests_screen.dart';
import 'package:snowtrak/widgets/follow_button.dart';
import 'package:snowtrak/services/follow_service.dart';
import 'package:snowtrak/services/profile_service.dart';

/// Profile identity block at the top of the profile screen.
class ProfileHeader extends StatefulWidget {
  const ProfileHeader({
    super.key,
    this.userId,
    this.fallbackName,
    this.fallbackUsername,
  });

  final String? userId;

  /// Shown until the profile arrives, and kept if it never does. Callers that
  /// already know who they are opening (a feed post's author) should pass it
  /// so the card never flashes a placeholder name.
  final String? fallbackName;
  final String? fallbackUsername;

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  final ProfileService _profileService = sl<ProfileService>();
  final FollowService _followService = sl<FollowService>();
  Profile? _profile;
  bool _isLoading = true;
  String? _error;
  bool _hasLoaded = false;
  String? _lastUserId;

  /// Pending requests to follow this profile's owner. Only ever loaded on
  /// your own profile -- see [_loadRequestCount].
  int _requestCount = 0;

  @override
  void initState() {
    super.initState();
    _lastUserId = widget.userId;
    _loadProfile();
    if (widget.userId == null) _loadRequestCount();
  }

  // ponytail: the badge counts the first page, so it stops at 20. Add a
  // count endpoint if anybody ever has more pending requests than that.
  Future<void> _loadRequestCount() async {
    final result = await _followService.getRequests(limit: 20);
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() => _requestCount = value.length);
      case AppFailure():
        // No count rather than a wrong one -- the pill just doesn't show.
    }
  }

  Future<void> _openRequests() async {
    await openFollowRequests(context);
    // The screen the badge points at is the only place these are resolved,
    // so a return trip is exactly when the count is stale.
    if (mounted) unawaited(_loadRequestCount());
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
    final profile = _profile;
    final isOwnProfile = widget.userId == null;

    // The card always renders. Loading, a failed request and a user with no
    // `profiles` row used to each collapse the header to zero height, which
    // reads as a broken screen rather than as missing data.
    if (profile != null) {
      return _withError(
        _buildHeader(
          displayName: profile.fullName ?? widget.fallbackName ?? 'User',
          username: profile.username ?? widget.fallbackUsername ?? '',
          avatarUrl: profile.avatarUrl,
          bio: profile.bio,
          skiLevel: profile.skiLevel,
          home: profile.home,
        ),
      );
    }

    final fallbackName = isOwnProfile && authUser != null
        ? authUser.fullName
        : widget.fallbackName ?? 'User';
    final fallbackUsername = isOwnProfile && authUser != null
        ? authUser.email.split('@').first
        : widget.fallbackUsername ?? '';

    return _withError(
      _buildHeader(
        displayName: fallbackName,
        username: fallbackUsername,
        avatarUrl: null,
        bio: null,
        skiLevel: null,
        home: null,
      ),
    );
  }

  /// Keeps a load failure visible without letting it replace the card.
  Widget _withError(Widget header) {
    if (_error == null) return header;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Padding(
          padding: const EdgeInsets.fromLTRB(
            SnowtrakSpacing.md,
            SnowtrakSpacing.sm,
            SnowtrakSpacing.md,
            0,
          ),
          child: Text(
            _error!,
            style: SnowtrakTypography.bodySmall
                .copyWith(color: context.colors.error),
            textAlign: TextAlign.center,
          ),
        ),
      ],
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
        SnowtrakSpacing.md,
        SnowtrakSpacing.md,
        SnowtrakSpacing.md,
        0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(SnowtrakRadius.lg),
          border: Border.all(color: context.colors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(SnowtrakSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor:
                        context.colors.primary.withValues(alpha: 0.12),
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : 'U',
                            style: SnowtrakTypography.headlineMedium.copyWith(
                              color: context.colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: SnowtrakSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: SnowtrakTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        if (username.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '@$username',
                            style: SnowtrakTypography.bodyMedium.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (bio != null && bio.isNotEmpty) ...[
                const SizedBox(height: SnowtrakSpacing.md),
                Text(
                  bio,
                  style: SnowtrakTypography.bodyMedium.copyWith(
                    color: context.colors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
              if (skiLevel != null || home != null) ...[
                const SizedBox(height: SnowtrakSpacing.md),
                Wrap(
                  spacing: SnowtrakSpacing.sm,
                  runSpacing: SnowtrakSpacing.sm,
                  children: [
                    if (skiLevel != null)
                      _InfoChip(
                        icon: Icons.downhill_skiing,
                        label: skiLevel,
                        color: context.colors.primary,
                      ),
                    if (home != null)
                      _InfoChip(
                        icon: Icons.location_on_outlined,
                        label: home,
                        color: context.colors.textSecondary,
                      ),
                  ],
                ),
              ],
              if (_followTargetId != null) ...[
                const SizedBox(height: SnowtrakSpacing.md),
                FollowButton(userId: _followTargetId!),
              ],
              if (widget.userId == null && _requestCount > 0) ...[
                const SizedBox(height: SnowtrakSpacing.md),
                _RequestsPill(count: _requestCount, onTap: _openRequests),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// The user this header can be followed as, or null when there is nobody to
  /// follow: your own profile, or a header with no id behind it.
  String? get _followTargetId {
    final userId = widget.userId;
    if (userId == null || userId.trim().isEmpty) return null;
    final signedInId = Provider.of<AuthProvider>(context, listen: false).user?.id;
    return userId == signedInId ? null : userId;
  }
}

/// Tappable pill pointing at [FollowRequestsScreen] -- the only place a
/// pending request is visible at all, since there is no push notification.
class _RequestsPill extends StatelessWidget {
  const _RequestsPill({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SnowtrakRadius.round),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SnowtrakSpacing.sm,
          vertical: SnowtrakSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: context.colors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(SnowtrakRadius.round),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_add_alt_1,
              size: 16,
              color: context.colors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              count == 1 ? '1 follow request' : '$count follow requests',
              style: SnowtrakTypography.labelMedium.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
        horizontal: SnowtrakSpacing.sm,
        vertical: SnowtrakSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(SnowtrakRadius.round),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: SnowtrakTypography.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
