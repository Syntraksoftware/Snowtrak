import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snowtrak/core/auth/authenticated_session.dart';
import 'package:snowtrak/core/di/service_locator.dart';
import 'package:snowtrak/core/errors/app_error.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/core/logging/app_logger.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/services/community_service.dart';
import 'package:snowtrak/models/post.dart';
import 'package:snowtrak/providers/activity_provider.dart';
import 'package:snowtrak/providers/auth_provider.dart';
import 'package:snowtrak/screens/community/community_post_mapper.dart';
import 'package:snowtrak/screens/profile/widgets/profile_home_content.dart';
import 'package:snowtrak/screens/profile/widgets/profile_totals.dart';
import 'package:snowtrak/ui/st/st.dart';
import 'package:snowtrak/widgets/profile_header.dart';
import 'package:snowtrak/widgets/message_card.dart';

/// Opens [userId]'s profile.
///
/// Pushing a profile needs nothing but a context, so call sites use this
/// instead of threading a callback back up to whatever owns the state. An
/// empty id is ignored: the feed mapper falls back to `''` when a post has no
/// `user_id`, and a profile screen for nobody is worse than no reaction.
Future<void> openUserProfile(
  BuildContext context,
  String userId, {
  String? displayName,
  String? username,
}) async {
  if (userId.trim().isEmpty) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => UserProfileScreen(
        userId: userId,
        displayName: displayName,
        username: username,
      ),
    ),
  );
}

class UserProfileScreen extends StatefulWidget {
  final String? userId; // If null, shows current user's profile

  /// What the caller already knows about this person, from the post they
  /// tapped. Used for the page title and until the profile request lands, so
  /// the screen never opens on a placeholder name.
  final String? displayName;
  final String? username;

  const UserProfileScreen({
    super.key,
    this.userId,
    this.displayName,
    this.username,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final CommunityService _communityService = sl<CommunityService>();
  List<Post> _posts = [];
  bool _isLoading = false; // Start as false - will be set when loading starts
  bool _isLoadingMore = false;
  String? _error;
  bool _errorRetryable = true;
  int _offset = 0;
  static const int _limit = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure widget is fully built before loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadPosts();
      }
    });
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    // Prevent multiple simultaneous loads (but allow refresh)
    if (!refresh && (_isLoading || _isLoadingMore)) {
      AppLogger.instance.debug('[UserProfileScreen] Skipping load - already loading');
      return;
    }

    if (!mounted) {
      AppLogger.instance.debug('[UserProfileScreen] Not mounted, skipping load');
      return;
    }

    AppLogger.instance.debug('[UserProfileScreen] Loading posts (refresh: $refresh)');
    
    // Set loading state BEFORE making the API call
    setState(() {
      if (refresh) {
        _offset = 0;
        _hasMore = true;
        _posts.clear();
        _isLoading = true;
        _isLoadingMore = false;
      } else if (!_isLoading) {
        // Initial load or load more
        _isLoading = true;
        _isLoadingMore = false;
      } else {
        // Already loading, set load more flag
        _isLoadingMore = true;
      }
      _error = null;
      _errorRetryable = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final sessionOutcome = await ensureAuthenticatedSession(
        authProvider,
        viewUserId: widget.userId,
        requireUserId: true,
      );
      late final String userId;
      switch (sessionOutcome) {
        case AuthenticatedSessionError(:final message):
          setState(() {
            _error = message;
            _errorRetryable = false;
            _isLoading = false;
            _isLoadingMore = false;
          });
          return;
        case AuthenticatedSessionOk(:final resolvedUserId):
          userId = resolvedUserId!;
      }

      AppLogger.instance.debug('[UserProfileScreen] Fetching posts for user: $userId');
      final postsResult = await _communityService.getPostsByUserId(
        userId,
        limit: _limit,
        offset: _offset,
      );

      final List<Map<String, dynamic>> postsData;
      switch (postsResult) {
        case AppFailure(:final error):
          if (mounted) {
            setState(() {
              _error = error.userMessage;
              _errorRetryable = error.retryable;
              _isLoading = false;
              _isLoadingMore = false;
            });
          }
          return;
        case AppSuccess(:final value):
          postsData = value;
      }

      AppLogger.instance.debug('[UserProfileScreen] Received ${postsData.length} posts');

      final newPosts = postsData.map((postJson) {
        final raw = Map<String, dynamic>.from(postJson as Map);
        return CommunityPostMapper.mapBackendPost(raw, const []);
      }).toList();

      if (mounted) {
        setState(() {
          _posts.addAll(newPosts);
          _offset += newPosts.length;
          _hasMore = newPosts.length == _limit;
          _isLoading = false;
          _isLoadingMore = false;
        });
        AppLogger.instance.debug('[UserProfileScreen] Posts loaded: ${_posts.length} total');
      }
    } catch (e, stackTrace) {
      if (mounted) {
        final appError = AppError.from(e, stackTrace);
        setState(() {
          _error = appError.userMessage;
          _errorRetryable = appError.retryable;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadPosts(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().user;
    // Tapping your own avatar in the feed lands here too, and then the
    // provider's data really is this person's.
    final isOwnProfile =
        widget.userId == null || widget.userId == authUser?.id;
    final activities =
        isOwnProfile ? context.watch<ActivityProvider>().activities : null;

    return Scaffold(
      backgroundColor: SnowtrakColors.background,
      // StPageHeader is a plain container, not an AppBar -- it does not inset
      // itself for the status bar, so as `appBar:` it drew under the notch.
      // It belongs inside SafeArea, the way ProfileScreen uses it.
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            StPageHeader(
              // The handle up here, the full name on the card below. Putting
              // the name in both made the top of the page say it twice.
              title: _headerTitle(),
              leading: const BackButton(color: SnowtrakColors.textPrimary),
            ),
            Expanded(
              child: RefreshIndicator(
                color: SnowtrakColors.ink,
                onRefresh: _handleRefresh,
                // Every section renders on every profile. A failed post load
                // used to replace the whole page, so a working profile
                // disappeared behind the error of one list.
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: ProfileHeader(
                        userId: widget.userId,
                        fallbackName: widget.displayName,
                        fallbackUsername: widget.username,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ProfileTotals(activities: activities),
                    ),
                    SliverToBoxAdapter(
                      child: ProfileHomeContent(isOwnProfile: isOwnProfile),
                    ),
                    _postsSliver(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _headerTitle() {
    final username = widget.username?.trim() ?? '';
    if (username.isNotEmpty) return '@$username';
    final name = widget.displayName?.trim() ?? '';
    return name.isNotEmpty ? name : 'Profile';
  }

  Widget _postsSliver() {
    if (_isLoading && _posts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(SnowtrakSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null && _posts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(SnowtrakSpacing.xl),
          child: Column(
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: SnowtrakTypography.bodyMedium.copyWith(
                  color: SnowtrakColors.error,
                ),
              ),
              if (_errorRetryable) ...[
                const SizedBox(height: SnowtrakSpacing.md),
                ElevatedButton(
                  onPressed: () => _loadPosts(refresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(SnowtrakSpacing.xl),
          child: Center(
            child: Text(
              'No posts yet',
              style: SnowtrakTypography.bodyLarge.copyWith(
                color: SnowtrakColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == _posts.length) {
            if (_hasMore && !_isLoadingMore) {
              // Reached the tail: pull the next page in after this frame.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _hasMore && !_isLoadingMore) _loadPosts();
              });
            }
            return const Padding(
              padding: EdgeInsets.all(SnowtrakSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final post = _posts[index];
          return MessageCard(
            post: post,
            onAvatarTap: (tapped) => openUserProfile(
              context,
              tapped.author.id,
              displayName: tapped.author.displayName,
              username: tapped.author.username,
            ),
          );
        },
        childCount: _posts.length + (_hasMore ? 1 : 0),
      ),
    );
  }
}
