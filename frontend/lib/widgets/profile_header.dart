import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/profile.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/services/api_service.dart';

class ProfileHeader extends StatefulWidget {
  final String? userId; // If null, shows current user's profile

  const ProfileHeader({
    super.key,
    this.userId,
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
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
    // Only reload if userId changed
    if (oldWidget.userId != widget.userId) {
      _lastUserId = widget.userId;
      _hasLoaded = false;
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    // Prevent multiple simultaneous loads
    if (_isLoading && _hasLoaded) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final apiService = ApiService();
    
    // Set token if available
    if (authProvider.session != null) {
      apiService.setToken(authProvider.session!.accessToken);
    }

    final userId = widget.userId ?? authProvider.user?.id;
    if (userId == null) {
      setState(() {
        _error = 'User not found';
        _isLoading = false;
      });
      return;
    }

    try {
      final profile = await apiService.getProfileById(userId);
      if (mounted && _lastUserId == userId) {
        setState(() {
          _profile = profile;
          _isLoading = false;
          _hasLoaded = true;
        });
      }
    } catch (e) {
      if (mounted && _lastUserId == userId) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _hasLoaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(SyntrakSpacing.lg),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(SyntrakSpacing.lg),
        child: Center(
          child: Text(
            'Error: $_error',
            style: SyntrakTypography.bodyMedium.copyWith(
              color: SyntrakColors.error,
            ),
          ),
        ),
      );
    }

    if (_profile == null) {
      return const SizedBox.shrink();
    }

    final profile = _profile!;
    final displayName = profile.fullName ?? 'User';
    final username = profile.username ?? '';

    return Container(
      padding: const EdgeInsets.all(SyntrakSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar and action buttons row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar (circular, 80x80 pixels)
              CircleAvatar(
                radius: 40,
                backgroundColor: SyntrakColors.primary.withOpacity(0.2),
                backgroundImage: profile.avatarUrl != null
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'U',
                        style: SyntrakTypography.headlineMedium.copyWith(
                          color: SyntrakColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const Spacer(),
              // Action buttons
              Row(
                children: [
                  // Edit Profile button (only for current user)
                  if (widget.userId == null)
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Navigate to profile edit screen
                        Navigator.pushNamed(context, '/profile/edit');
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Profile'),
                      style: TextButton.styleFrom(
                        foregroundColor: SyntrakColors.primary,
                      ),
                    ),
                  const SizedBox(width: SyntrakSpacing.sm),
                  // Share Profile button (placeholder)
                  IconButton(
                    onPressed: () {
                      // TODO: Implement share functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share profile (coming soon)')),
                      );
                    },
                    icon: const Icon(Icons.share),
                    color: SyntrakColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: SyntrakSpacing.md),
          // Full name (large bold text)
          Text(
            displayName,
            style: SyntrakTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: SyntrakColors.textPrimary,
            ),
          ),
          // Username (secondary text)
          if (username.isNotEmpty) ...[
            const SizedBox(height: SyntrakSpacing.xs),
            Text(
              '@$username',
              style: SyntrakTypography.bodyMedium.copyWith(
                color: SyntrakColors.textSecondary,
              ),
            ),
          ],
          // Bio (leading text below name)
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: SyntrakSpacing.md),
            Text(
              profile.bio!,
              style: SyntrakTypography.bodyMedium.copyWith(
                color: SyntrakColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
          // Additional info (ski level, home)
          if (profile.skiLevel != null || profile.home != null) ...[
            const SizedBox(height: SyntrakSpacing.md),
            Wrap(
              spacing: SyntrakSpacing.md,
              runSpacing: SyntrakSpacing.sm,
              children: [
                if (profile.skiLevel != null)
                  Chip(
                    label: Text(profile.skiLevel!),
                    backgroundColor: SyntrakColors.primary.withOpacity(0.1),
                    labelStyle: SyntrakTypography.labelSmall.copyWith(
                      color: SyntrakColors.primary,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: SyntrakSpacing.sm,
                      vertical: SyntrakSpacing.xs,
                    ),
                  ),
                if (profile.home != null)
                  Chip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 14),
                        const SizedBox(width: 4),
                        Text(profile.home!),
                      ],
                    ),
                    backgroundColor: SyntrakColors.secondary.withOpacity(0.1),
                    labelStyle: SyntrakTypography.labelSmall.copyWith(
                      color: SyntrakColors.secondary,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: SyntrakSpacing.sm,
                      vertical: SyntrakSpacing.xs,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
