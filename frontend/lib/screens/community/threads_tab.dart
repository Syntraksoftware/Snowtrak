import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/di/service_locator.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/features/community/data/community_outbox_service.dart';
import 'package:syntrak/services/api_service.dart';
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
  static const int _defaultPageSize = 20;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final CommunityOutboxService _outbox = CommunityOutboxService();
  final ApiService _apiService = sl<ApiService>();

  final List<Post> _posts = [];
  List<Post> _filteredPosts = [];

  bool _isRefreshing = false;
  bool _isLoading = false;
  bool _isSearchFocused = false;
  String? _expandedPostId;
  String? _activeSubthreadId;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
    _bootstrapFeed();
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
    if (query.isEmpty) {
      _filteredPosts = List.from(_posts);
    } else {
      _filteredPosts = _posts.where((post) {
        return post.text.toLowerCase().contains(query) ||
            post.author.displayName.toLowerCase().contains(query) ||
            post.author.username.toLowerCase().contains(query);
      }).toList();
    }
  }

  Future<void> _bootstrapFeed() async {
    await _loadFeed();
    await _retryOutbox();
  }

  Future<void> _loadFeed() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final subthreads = await _apiService.getCommunitySubthreads(limit: 50);
      if (subthreads.isEmpty) {
        if (mounted) {
          setState(() {
            _posts.clear();
            _filteredPosts = [];
            _isLoading = false;
          });
        }
        return;
      }

      _activeSubthreadId = (subthreads.first['id'] ?? '').toString();
      if (_activeSubthreadId == null || _activeSubthreadId!.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final postsData = await _apiService.getCommunityPostsBySubthread(
        _activeSubthreadId!,
        limit: _defaultPageSize,
      );

      final mapped = <Post>[];
      for (final rawPost in postsData) {
        final comments = await _apiService.getCommunityCommentsByPost(
          (rawPost['post_id'] ?? '').toString(),
        );
        mapped.add(_mapBackendPost(rawPost, comments));
      }

      if (mounted) {
        setState(() {
          _posts.clear();
          _posts.addAll(mapped);
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

  Future<void> _handlePost(String text) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null || _activeSubthreadId == null) return;

    final tempId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';

    final newPost = Post(
      id: tempId,
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
      _filterPosts();
    });

    try {
      final response = await _apiService.createCommunityPost(
        subthreadId: _activeSubthreadId!,
        title: text.length > 48 ? '${text.substring(0, 48)}...' : text,
        content: text,
      );

      final confirmed = _mapBackendPost(response, const []);
      if (!mounted) return;

      setState(() {
        final index = _posts.indexWhere((p) => p.id == tempId);
        if (index != -1) {
          _posts[index] = confirmed;
          _filterPosts();
        }
      });
    } catch (_) {
      await _outbox.enqueue(
        CommunityOutboxOperation(
          id: tempId,
          type: 'create_post',
          payload: {
            'subthread_id': _activeSubthreadId,
            'title': text.length > 48 ? '${text.substring(0, 48)}...' : text,
            'content': text,
            'temp_id': tempId,
          },
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post queued offline. Will retry automatically.'),
        ),
      );
    }
  }

  void _handleLike(Post post) {
    final nextLiked = !post.likedByCurrentUser;
    final nextVoteType = nextLiked ? 1 : 0;

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
        _filterPosts();
      }
    });

    _syncPostVote(postId: post.id, voteType: nextVoteType);
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
        _filterPosts();
      }
    });
  }

  Future<void> _handleReply(Post post) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reply'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Write your reply...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Reply'),
            ),
          ],
        );
      },
    );

    final text = (result ?? '').trim();
    if (text.isEmpty) return;

    await _sendReply(post: post, text: text);
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

  Future<void> _sendReply({required Post post, required String text}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    final tempReplyId = 'tmp_reply_${DateTime.now().millisecondsSinceEpoch}';
    final localReply = Post(
      id: tempReplyId,
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
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        final current = _posts[index];
        final replies = <Post>[...(current.replies ?? []), localReply];
        _posts[index] = current.copyWith(
          replies: replies,
          replyCount: replies.length,
        );
        _filterPosts();
      }
    });

    try {
      final response = await _apiService.createCommunityComment(
        postId: post.id,
        content: text,
      );
      final confirmedReply = _mapCommentToPost(response);
      if (!mounted) return;

      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          final current = _posts[index];
          final nextReplies = (current.replies ?? [])
              .map((reply) => reply.id == tempReplyId ? confirmedReply : reply)
              .toList()
              .cast<Post>();
          _posts[index] = current.copyWith(
            replies: nextReplies,
            replyCount: nextReplies.length,
          );
          _filterPosts();
        }
      });
    } catch (_) {
      await _outbox.enqueue(
        CommunityOutboxOperation(
          id: tempReplyId,
          type: 'create_comment',
          payload: {
            'post_id': post.id,
            'content': text,
            'temp_id': tempReplyId,
          },
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reply queued offline. Will retry automatically.'),
        ),
      );
    }
  }

  Future<void> _retryOutbox() async {
    final operations = await _outbox.load();
    if (operations.isEmpty) return;

    final pending = <CommunityOutboxOperation>[];
    for (final operation in operations) {
      try {
        if (operation.type == 'create_post') {
          await _apiService.createCommunityPost(
            subthreadId: (operation.payload['subthread_id'] ?? '').toString(),
            title: (operation.payload['title'] ?? '').toString(),
            content: (operation.payload['content'] ?? '').toString(),
          );
        } else if (operation.type == 'create_comment') {
          await _apiService.createCommunityComment(
            postId: (operation.payload['post_id'] ?? '').toString(),
            content: (operation.payload['content'] ?? '').toString(),
          );
        } else if (operation.type == 'vote_post') {
          await _apiService.voteCommunityPost(
            postId: (operation.payload['post_id'] ?? '').toString(),
            voteType: (operation.payload['vote_type'] as num?)?.toInt() ?? 0,
          );
        }
      } catch (_) {
        pending.add(operation.copyWith(retryCount: operation.retryCount + 1));
      }
    }

    await _outbox.replaceAll(pending);
    if (mounted) {
      await _loadFeed();
    }
  }

  Post _mapBackendPost(
    Map<String, dynamic> rawPost,
    List<Map<String, dynamic>> rawComments,
  ) {
    final createdAt = DateTime.tryParse((rawPost['created_at'] ?? '').toString()) ??
        DateTime.now();
    final authorName = _authorDisplayName(
      firstName: rawPost['author_first_name']?.toString(),
      lastName: rawPost['author_last_name']?.toString(),
      fallback: rawPost['author_email']?.toString() ?? rawPost['user_id']?.toString() ?? 'unknown',
    );

    final replies = _mapReplies(rawComments);

    return Post(
      id: (rawPost['post_id'] ?? rawPost['id'] ?? '').toString(),
      author: PostAuthor(
        id: (rawPost['user_id'] ?? '').toString(),
        displayName: authorName,
        username: _usernameFromEmailOrId(
          rawPost['author_email']?.toString(),
          rawPost['user_id']?.toString(),
        ),
      ),
      text: (rawPost['content'] ?? rawPost['title'] ?? '').toString(),
      createdAt: createdAt,
      timestampLabel: _timestampLabel(createdAt),
      likeCount: 0,
      replyCount: replies.length,
      repostCount: 0,
      replies: replies,
    );
  }

  List<Post> _mapReplies(List<Map<String, dynamic>> comments) {
    if (comments.isEmpty) {
      return const [];
    }

    final root = comments
        .where((c) => (c['parent_id'] == null || c['parent_id'].toString().isEmpty))
        .toList();

    return root.map((comment) {
      final rootId = (comment['id'] ?? '').toString();
      final nested = comments
          .where((c) => (c['parent_id'] ?? '').toString() == rootId)
          .map(_mapCommentToPost)
          .toList();

      final mappedRoot = _mapCommentToPost(comment);
      return mappedRoot.copyWith(
        replies: nested,
        replyCount: nested.length,
      );
    }).toList();
  }

  Post _mapCommentToPost(Map<String, dynamic> comment) {
    final createdAt = DateTime.tryParse((comment['created_at'] ?? '').toString()) ??
        DateTime.now();
    final authorName = _authorDisplayName(
      firstName: comment['author_first_name']?.toString(),
      lastName: comment['author_last_name']?.toString(),
      fallback: comment['author_email']?.toString() ?? comment['user_id']?.toString() ?? 'unknown',
    );

    return Post(
      id: (comment['id'] ?? '').toString(),
      author: PostAuthor(
        id: (comment['user_id'] ?? '').toString(),
        displayName: authorName,
        username: _usernameFromEmailOrId(
          comment['author_email']?.toString(),
          comment['user_id']?.toString(),
        ),
      ),
      text: (comment['content'] ?? '').toString(),
      createdAt: createdAt,
      timestampLabel: _timestampLabel(createdAt),
    );
  }

  String _authorDisplayName({
    String? firstName,
    String? lastName,
    required String fallback,
  }) {
    final first = (firstName ?? '').trim();
    final last = (lastName ?? '').trim();
    if (first.isNotEmpty || last.isNotEmpty) {
      return '$first $last'.trim();
    }
    return _usernameFromEmailOrId(fallback, fallback);
  }

  String _usernameFromEmailOrId(String? email, String? fallbackId) {
    final e = (email ?? '').trim();
    if (e.contains('@')) {
      return e.split('@').first;
    }

    final id = (fallbackId ?? '').trim();
    if (id.isEmpty) {
      return 'user';
    }
    return id.length > 12 ? id.substring(0, 12) : id;
  }

  String _timestampLabel(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  Future<void> _syncPostVote({
    required String postId,
    required int voteType,
  }) async {
    try {
      await _apiService.voteCommunityPost(postId: postId, voteType: voteType);
    } catch (_) {
      await _outbox.enqueue(
        CommunityOutboxOperation(
          id: 'vote_${DateTime.now().millisecondsSinceEpoch}_$postId',
          type: 'vote_post',
          payload: {
            'post_id': postId,
            'vote_type': voteType,
          },
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vote queued offline. Will retry automatically.'),
        ),
      );
    }
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

    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          // Pinned search bar - stays fixed at top
          SliverAppBar(
            pinned: true,
            floating: false,
            automaticallyImplyLeading: false,
            backgroundColor: SyntrakColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: innerBoxIsScrolled ? 2 : 0,
            shadowColor: Colors.black26,
            toolbarHeight: 72,
            flexibleSpace: _buildSearchBar(),
          ),
        ];
      },
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: SyntrakColors.primary,
        child: ListView.builder(
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
    );
  }

  // Fixed search bar at top
  Widget _buildSearchBar() {
    return Container(
      color: SyntrakColors.surface,
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
          onChanged: (_) {
            setState(() {
              _filterPosts();
            });
          },
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
                      setState(() {
                        _searchController.clear();
                        _filterPosts();
                      });
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
