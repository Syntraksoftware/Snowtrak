import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/models/post.dart';
import 'package:syntrak/widgets/community_header.dart';
import 'package:syntrak/widgets/composer_widget.dart';
import 'package:syntrak/widgets/message_card.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Post> _posts = [];
  bool _isRefreshing = false;
  bool _isLoading = false;
  String? _expandedPostId;

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Detect if at top for refresh behavior
  }

  bool get _isAtTop {
    if (!_scrollController.hasClients) return true;
    return _scrollController.offset <= 0;
  }

  Future<void> _loadFeed() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Fetch from community backend API
      // For now, use mock data
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _posts.clear();
          _posts.addAll(_generateMockPosts());
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    await _loadFeed();

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _handleScrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handlePost(String text) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    // Create new post optimistically
    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: PostAuthor(
        id: user.id,
        displayName: user.firstName != null && user.lastName != null
            ? '${user.firstName} ${user.lastName}'
            : user.email.split('@')[0],
        username: user.email.split('@')[0],
        avatarUrl: null,
      ),
      text: text,
      createdAt: DateTime.now(),
      timestampLabel: 'now',
    );

    // Optimistic update: add to top of feed
    setState(() {
      _posts.insert(0, newPost);
    });

    // TODO: Actually post to backend API
    // After successful post, update the post with server response
  }

  void _handleLike(Post post) {
    setState(() {
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        final currentPost = _posts[index];
        _posts[index] = currentPost.copyWith(
          likedByCurrentUser: !currentPost.likedByCurrentUser,
          likeCount: currentPost.likedByCurrentUser
              ? currentPost.likeCount - 1
              : currentPost.likeCount + 1,
        );
      }
    });

    // TODO: Actually like/unlike via API
  }

  void _handleRepost(Post post) {
    setState(() {
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        final currentPost = _posts[index];
        _posts[index] = currentPost.copyWith(
          repostedByCurrentUser: !currentPost.repostedByCurrentUser,
          repostCount: currentPost.repostedByCurrentUser
              ? currentPost.repostCount - 1
              : currentPost.repostCount + 1,
        );
      }
    });

    // TODO: Actually repost via API
  }

  void _handleReply(Post post) {
    // TODO: Open reply composer
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reply functionality coming soon'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _handleShare(Post post) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _handlePostTap(Post post) {
    setState(() {
      _expandedPostId = _expandedPostId == post.id ? null : post.id;
    });
  }

  List<Post> _generateMockPosts() {
    final random = Random();
    final authors = [
      PostAuthor(
        id: '1',
        displayName: 'Alex Johnson',
        username: 'alexj',
      ),
      PostAuthor(
        id: '2',
        displayName: 'Sarah Chen',
        username: 'sarahc',
      ),
      PostAuthor(
        id: '3',
        displayName: 'Mike Davis',
        username: 'miked',
      ),
    ];

    final messages = [
      'Just finished an amazing 10K run! 🏃‍♂️',
      'Beautiful morning for a bike ride through the city.',
      'New personal best on today\'s workout! Feeling strong 💪',
      'Anyone up for a group run this weekend?',
      'The trails were perfect today. Nature is the best gym.',
    ];

    return List.generate(5, (index) {
      final author = authors[random.nextInt(authors.length)];
      final hasReplies = random.nextBool();
      final replies = hasReplies
          ? List.generate(
              random.nextInt(2) + 1,
              (i) => Post(
                id: '${index}_reply_$i',
                author: authors[random.nextInt(authors.length)],
                text: 'Great post! Keep it up 👍',
                createdAt: DateTime.now().subtract(Duration(hours: i)),
                timestampLabel: '${i + 1}h',
              ),
            )
          : null;

      return Post(
        id: index.toString(),
        author: author,
        text: messages[index],
        createdAt: DateTime.now().subtract(Duration(hours: index)),
        timestampLabel: index == 0 ? 'now' : '${index}h',
        likeCount: random.nextInt(50),
        replyCount: replies?.length ?? 0,
        repostCount: random.nextInt(20),
        likedByCurrentUser: random.nextBool(),
        repostedByCurrentUser: false,
        replies: replies,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Off-white background
      body: Column(
        children: [
          // Fixed header
          CommunityHeader(
            onHomeTap: _handleScrollToTop,
            onRefresh: _handleRefresh,
            isAtTop: _isAtTop,
            isRefreshing: _isRefreshing,
          ),
          // Composer
          ComposerWidget(
            onPost: _handlePost,
            maxCharacters: 280,
          ),
          // Feed list
          Expanded(
            child: _isLoading && _posts.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFFF4500)),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: const Color(0xFFFF4500),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        return MessageCard(
                          post: post,
                          isExpanded: _expandedPostId == post.id,
                          onTap: () => _handlePostTap(post),
                          onLike: _handleLike,
                          onRepost: _handleRepost,
                          onReply: _handleReply,
                          onShare: _handleShare,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
