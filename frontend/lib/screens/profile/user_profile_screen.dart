import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _offset = 0;
  static const int _limit = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    // Prevent multiple simultaneous loads
    if ((_isLoading && !refresh) || (_isLoadingMore && !refresh)) return;

    if (!mounted) return;

    setState(() {
      if (refresh) {
        _offset = 0;
        _hasMore = true;
        _posts.clear();
        _isLoading = true;
        _isLoadingMore = false;
      } else {
        _isLoadingMore = true;
      }
      _error = null;
    });

    try {
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
          _isLoadingMore = false;
        });
        return;
      }

      final postsData = await apiService.getPostsByUserId(
        userId,
        limit: _limit,
        offset: _offset,
      );

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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isLoadingMore = false;
        });
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
