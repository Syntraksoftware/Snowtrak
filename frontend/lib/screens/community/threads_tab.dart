import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/di/service_locator.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/features/community/data/community_outbox_service.dart';
import 'package:syntrak/services/community_service.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/models/post.dart';
import 'package:syntrak/screens/community/community_post_mapper.dart';
import 'package:syntrak/screens/community/widgets/thread_reply_dialog.dart';
import 'package:syntrak/screens/community/widgets/threads_search_bar.dart';
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
  final CommunityService _communityService = sl<CommunityService>();

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
      final subthreads = await _communityService.getSubthreads(limit: 50);
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

      final postsData = await _communityService.getPostsBySubthread(
        _activeSubthreadId!,
        limit: _defaultPageSize,
      );

      final mapped = <Post>[];
      for (final rawPost in postsData) {
        final comments = await _communityService.getCommentsByPost(
          (rawPost['post_id'] ?? '').toString(),
        );
        mapped.add(CommunityPostMapper.mapBackendPost(rawPost, comments));
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
      final response = await _communityService.createPost(
        subthreadId: _activeSubthreadId!,
        title: text.length > 48 ? '${text.substring(0, 48)}...' : text,
        content: text,
      );

      final confirmed = CommunityPostMapper.mapBackendPost(response, const []);
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
    final text = await showThreadReplyDialog(context);
    if (text == null) return;
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
      final response = await _communityService.createComment(
        postId: post.id,
        content: text,
      );
      final confirmedReply = CommunityPostMapper.mapCommentToPost(response);
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
          await _communityService.createPost(
            subthreadId: (operation.payload['subthread_id'] ?? '').toString(),
            title: (operation.payload['title'] ?? '').toString(),
            content: (operation.payload['content'] ?? '').toString(),
          );
        } else if (operation.type == 'create_comment') {
          await _communityService.createComment(
            postId: (operation.payload['post_id'] ?? '').toString(),
            content: (operation.payload['content'] ?? '').toString(),
          );
        } else if (operation.type == 'vote_post') {
          await _communityService.votePost(
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

  Future<void> _syncPostVote({
    required String postId,
    required int voteType,
  }) async {
    try {
      await _communityService.votePost(postId: postId, voteType: voteType);
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
            flexibleSpace: ThreadsSearchBar(
              controller: _searchController,
              focusNode: _searchFocusNode,
              isSearchFocused: _isSearchFocused,
              onQueryChanged: (_) {
                setState(() {
                  _filterPosts();
                });
              },
              onClear: () {
                setState(() {
                  _searchController.clear();
                  _filterPosts();
                });
              },
            ),
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
}
