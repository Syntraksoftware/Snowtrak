import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/models/post.dart';
import 'package:syntrak/widgets/compact_composer.dart';
import 'package:syntrak/widgets/message_card.dart';

class ThreadsTab extends StatefulWidget {
  const ThreadsTab({super.key});

  @override
  State<ThreadsTab> createState() => _ThreadsTabState();
}

class _ThreadsTabState extends State<ThreadsTab> {
  final ScrollController _scrollController = ScrollController();
  final List<Post> _posts = [];
  bool _isRefreshing = false;
  bool _isLoading = false;
  String? _expandedPostId;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Fetch from community backend API
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

  void _handlePost(String text) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

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

    setState(() {
      _posts.insert(0, newPost);
    });

    // TODO: Post to backend API
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
  }

  void _handleReply(Post post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reply functionality coming soon'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _handleShare(Post post) {
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
      PostAuthor(id: '1', displayName: 'Alex Johnson', username: 'alexj'),
      PostAuthor(id: '2', displayName: 'Sarah Chen', username: 'sarahc'),
      PostAuthor(id: '3', displayName: 'Mike Davis', username: 'miked'),
      PostAuthor(id: '4', displayName: 'Emma Wilson', username: 'emmaw'),
    ];

    final messages = [
      'Just hit the slopes at Whistler! Fresh powder day ❄️🎿',
      'Anyone know if Park City has good snow conditions this week?',
      'New personal best on the black diamond run! 💪',
      'Looking for ski buddies in the Tahoe area this weekend.',
      'The views from the summit were incredible today 🏔️',
      'Finally landed my first 360! Months of practice paid off 🎉',
    ];

    return List.generate(6, (index) {
      final author = authors[random.nextInt(authors.length)];
      final hasReplies = random.nextBool();
      final replies = hasReplies
          ? List.generate(
              random.nextInt(2) + 1,
              (i) => Post(
                id: '${index}_reply_$i',
                author: authors[random.nextInt(authors.length)],
                text: 'Awesome! Keep shredding! 🤙',
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
    if (_isLoading && _posts.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(SyntrakColors.primary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: SyntrakColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: SyntrakSpacing.sm),
        itemCount: _posts.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return CompactComposer(
              onPost: _handlePost,
              maxCharacters: 280,
            );
          }
          final post = _posts[index - 1];
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
    );
  }
}
