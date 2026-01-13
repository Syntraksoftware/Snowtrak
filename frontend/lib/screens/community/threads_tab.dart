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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final List<Post> _posts = [];
  List<Post> _filteredPosts = [];
  bool _isRefreshing = false;
  bool _isLoading = false;
  bool _isSearchFocused = false;
  String? _expandedPostId;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
    _loadFeed();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterPosts() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredPosts = List.from(_posts);
      } else {
        _filteredPosts = _posts.where((post) {
          return post.text.toLowerCase().contains(query) ||
              post.author.displayName.toLowerCase().contains(query) ||
              post.author.username.toLowerCase().contains(query);
        }).toList();
      }
    });
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
          _filteredPosts = List.from(_posts);
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

    return Scaffold(
      backgroundColor: SyntrakColors.background,
      body: Column(
        children: [
          // Search bar 
          Material(
            color: SyntrakColors.surface,
            elevation: 1,
            child: _buildSearchBar(),
          ),
          // Posts list 
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: SyntrakColors.primary,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: SyntrakSpacing.sm),
                itemCount: _filteredPosts.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return CompactComposer(
                      onPost: _handlePost,
                      maxCharacters: 280,
                    );
                  }
                  final post = _filteredPosts[index - 1];
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

  // Fixed search bar at top
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SyntrakSpacing.md,
        SyntrakSpacing.md,
        SyntrakSpacing.md,
        SyntrakSpacing.sm,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isSearchFocused
              ? SyntrakColors.surface
              : SyntrakColors.surfaceVariant,
          borderRadius: BorderRadius.circular(SyntrakRadius.round),
          border: Border.all(
            color:
                _isSearchFocused ? SyntrakColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: _isSearchFocused
              ? [
                  BoxShadow(
                    color: SyntrakColors.primary.withAlpha(30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (_) => _filterPosts(),
          style: SyntrakTypography.bodyMedium.copyWith(
            color: SyntrakColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search posts, users...',
            hintStyle: SyntrakTypography.bodyMedium.copyWith(
              color: SyntrakColors.textTertiary,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: _isSearchFocused
                  ? SyntrakColors.primary
                  : SyntrakColors.textTertiary,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close,
                      color: SyntrakColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _filterPosts();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: SyntrakSpacing.md,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}
