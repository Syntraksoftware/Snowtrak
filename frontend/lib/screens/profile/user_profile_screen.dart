import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/auth/authenticated_session.dart';
import 'package:syntrak/core/di/service_locator.dart';
import 'package:syntrak/core/errors/app_error.dart';
import 'package:syntrak/core/errors/app_result.dart';
import 'package:syntrak/core/logging/app_logger.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/services/community_service.dart';
import 'package:syntrak/models/post.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/screens/community/community_post_mapper.dart';
import 'package:syntrak/widgets/profile_header.dart';
import 'package:syntrak/widgets/message_card.dart';

class UserProfileScreen extends StatefulWidget {
  final String? userId; // If null, shows current user's profile

  const UserProfileScreen({
    super.key,
    this.userId,
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
    AppLogger.instance.debug('[UserProfileScreen] Building screen. isLoading: $_isLoading, error: $_error, posts: ${_posts.length}');
    
    return Scaffold(
      backgroundColor: SyntrakColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _isLoading && _posts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _posts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: SyntrakTypography.bodyMedium.copyWith(
                            color: SyntrakColors.error,
                          ),
                        ),
                        if (_errorRetryable) ...[
                          const SizedBox(height: SyntrakSpacing.md),
                          ElevatedButton(
                            onPressed: () => _loadPosts(refresh: true),
                            child: const Text('Retry'),
                          ),
                        ],
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      // Profile header as list header component
                      SliverToBoxAdapter(
                        child: ProfileHeader(userId: widget.userId),
                      ),
                      // Posts list
                      if (_posts.isEmpty && !_isLoading)
                        SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.all(SyntrakSpacing.xl),
                            child: Center(
                              child: Text(
                                'No posts yet',
                                style: SyntrakTypography.bodyLarge.copyWith(
                                  color: SyntrakColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              // Load more when reaching the end
                              if (index == _posts.length - 1 && _hasMore && !_isLoadingMore) {
                                // Trigger load more after a small delay to avoid rapid calls
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  if (mounted && _hasMore && !_isLoadingMore) {
                                    _loadPosts();
                                  }
                                });
                              }
                              
                              if (index == _posts.length && _hasMore) {
                                // Load more indicator
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(SyntrakSpacing.md),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              
                              if (index >= _posts.length) {
                                return const SizedBox.shrink();
                              }
                              
                              final post = _posts[index];
                              
                              return MessageCard(
                                post: post,
                                onAvatarTap: () {
                                  // Navigate to user profile
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserProfileScreen(
                                        userId: post.author.id,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            childCount: _posts.length + (_hasMore ? 1 : 0),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
