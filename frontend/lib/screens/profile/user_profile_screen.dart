import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/di/service_locator.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/post.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/services/api_service.dart';
import 'package:syntrak/widgets/profile_header.dart';
import 'package:syntrak/widgets/message_card.dart';
import 'package:intl/intl.dart';

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
  List<Post> _posts = [];
  bool _isLoading = false; // Start as false - will be set when loading starts
  bool _isLoadingMore = false;
  String? _error;
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
      print('🔍 [UserProfileScreen] Skipping load - already loading');
      return;
    }

    if (!mounted) {
      print('🔍 [UserProfileScreen] Not mounted, skipping load');
      return;
    }

    print('🔍 [UserProfileScreen] Loading posts (refresh: $refresh)');
    
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
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = sl<ApiService>();
      
      // Check session and refresh token if needed
      if (authProvider.session == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
          _isLoadingMore = false;
        });
        return;
      }

      // Refresh token if expired
      final tokenRefreshed = await authProvider.refreshTokenIfNeeded();
      if (!tokenRefreshed) {
        setState(() {
          _error = 'Session expired. Please login again.';
          _isLoading = false;
          _isLoadingMore = false;
        });
        return;
      }

      // Set token
      if (authProvider.session != null) {
        apiService.setToken(authProvider.session!.accessToken);
      }

      final userId = widget.userId ?? authProvider.user?.id;
      print('🔍 [UserProfileScreen] UserId: $userId');
      if (userId == null) {
        print('🔍 [UserProfileScreen] User ID is null');
        setState(() {
          _error = 'User not found';
          _isLoading = false;
          _isLoadingMore = false;
        });
        return;
      }

      print('🔍 [UserProfileScreen] Fetching posts for user: $userId');
      final postsData = await apiService.getPostsByUserId(
        userId,
        limit: _limit,
        offset: _offset,
      );
      print('🔍 [UserProfileScreen] Received ${postsData.length} posts');

      final newPosts = postsData.map((postJson) {
        // Convert backend post format to frontend Post model
        final authorFirstName = postJson['author_first_name'] ?? '';
        final authorLastName = postJson['author_last_name'] ?? '';
        final displayName = authorFirstName.isNotEmpty || authorLastName.isNotEmpty
            ? '$authorFirstName $authorLastName'.trim()
            : postJson['author_email']?.split('@')[0] ?? 'User';
        
        final createdAt = postJson['created_at'] != null
            ? DateTime.parse(postJson['created_at'])
            : DateTime.now();
        
        return Post(
          id: postJson['post_id'] ?? postJson['id'] ?? '',
          author: PostAuthor(
            id: postJson['user_id'] ?? userId,
            displayName: displayName,
            username: postJson['author_email']?.split('@')[0] ?? 'user',
            avatarUrl: null, // TODO: Get from profile
          ),
          text: postJson['content'] ?? postJson['text'] ?? '',
          createdAt: createdAt,
          timestampLabel: _formatTimestamp(createdAt),
          likeCount: 0, // TODO: Get from backend
          replyCount: 0, // TODO: Get from backend
        );
      }).toList();

      if (mounted) {
        setState(() {
          _posts.addAll(newPosts);
          _offset += newPosts.length;
          _hasMore = newPosts.length == _limit;
          _isLoading = false;
          _isLoadingMore = false;
        });
        print('🔍 [UserProfileScreen] Posts loaded: ${_posts.length} total');
      }
    } catch (e, stackTrace) {
      print('🔍 [UserProfileScreen] Error loading posts: $e');
      print('🔍 [UserProfileScreen] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isLoadingMore = false;
        });
        print('🔍 [UserProfileScreen] Error state set: $_error');
      }
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, y').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  Future<void> _handleRefresh() async {
    await _loadPosts(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 [UserProfileScreen] Building screen. isLoading: $_isLoading, error: $_error, posts: ${_posts.length}');
    
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
                          'Error: $_error',
                          style: SyntrakTypography.bodyMedium.copyWith(
                            color: SyntrakColors.error,
                          ),
                        ),
                        const SizedBox(height: SyntrakSpacing.md),
                        ElevatedButton(
                          onPressed: () => _loadPosts(refresh: true),
                          child: const Text('Retry'),
                        ),
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
