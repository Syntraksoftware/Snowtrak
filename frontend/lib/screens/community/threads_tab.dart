import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/di/service_locator.dart';
import 'package:syntrak/core/errors/app_error.dart';
import 'package:syntrak/core/errors/app_result.dart';
import 'package:syntrak/core/logging/app_logger.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/features/community/data/community_outbox_service.dart';
import 'package:syntrak/services/community_service.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/models/post.dart';
import 'package:syntrak/screens/community/community_post_mapper.dart';
import 'package:syntrak/screens/community/new_thread_draft_screen.dart';
import 'package:syntrak/screens/community/thread_detail_screen.dart';
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
  static final RegExp _uuidRegExp = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

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
  String? _activeSubthreadId;
  AppError? _feedError;

  /// One attempt to create a default subthread when API returns none (posts require a subthread_id).
  bool _triedDefaultSubthreadCreation = false;

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

  /// Prefer "Chat" subthread for new posts; else first in list.
  String _pickDefaultSubthreadId(List<Map<String, dynamic>> subthreads) {
    for (final s in subthreads) {
      if ((s['name'] ?? '').toString().toLowerCase().trim() == 'chat') {
        return (s['id'] ?? '').toString();
      }
    }
    return (subthreads.first['id'] ?? '').toString();
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

  void _applyLoadFailure(AppError error) {
    if (!mounted) return;
    final hadPosts = _posts.isNotEmpty;
    setState(() {
      _isLoading = false;
      if (!hadPosts) {
        _feedError = error;
      }
    });
    if (hadPosts) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.userMessage)),
      );
    }
  }

  Future<void> _loadFeed({bool afterDefaultSubthread = false}) async {
    if (!afterDefaultSubthread && _isLoading) return;

    setState(() {
      _isLoading = true;
      _feedError = null;
    });

    final subResult = await _communityService.getSubthreads(limit: 50);
    switch (subResult) {
      case AppFailure(:final error):
        _applyLoadFailure(error);
        return;
      case AppSuccess(:final value):
        var subthreads = value;
        if (subthreads.isEmpty) {
          if (!_triedDefaultSubthreadCreation) {
            _triedDefaultSubthreadCreation = true;
            final created = await _communityService.createSubthread(
              name: 'Main',
              description: 'Default community feed',
            );
            switch (created) {
              case AppFailure(:final error):
                _triedDefaultSubthreadCreation = false;
                _applyLoadFailure(error);
                return;
              case AppSuccess():
                await _loadFeed(afterDefaultSubthread: true);
                return;
            }
          }
          if (mounted) {
            setState(() {
              _posts.clear();
              _filteredPosts = [];
              _isLoading = false;
              _feedError = null;
            });
          }
          return;
        }

        _triedDefaultSubthreadCreation = false;
        _activeSubthreadId = _pickDefaultSubthreadId(subthreads);
        if (_activeSubthreadId == null || _activeSubthreadId!.isEmpty) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }

        final postsResult = await _communityService.getFeedPosts(
          limit: _defaultPageSize,
        );
        switch (postsResult) {
          case AppFailure(:final error):
            _applyLoadFailure(error);
            return;
          case AppSuccess(:final value):
            final postsData = value;

            final postIds = postsData
                .map((p) => (p['post_id'] ?? '').toString())
                .where((id) => id.isNotEmpty)
                .toList();

            final batchResult =
                await _communityService.getCommentsForPosts(postIds);
            switch (batchResult) {
              case AppFailure(:final error):
                _applyLoadFailure(error);
                return;
              case AppSuccess(:final value):
                final byPost = value;
                final mapped = <Post>[];
                for (final rawPost in postsData) {
                  final pid = (rawPost['post_id'] ?? '').toString();
                  final comments = byPost[pid] ?? <Map<String, dynamic>>[];
                  mapped.add(
                    CommunityPostMapper.mapBackendPost(rawPost, comments),
                  );
                }

                if (mounted) {
                  setState(() {
                    _posts.clear();
                    _posts.addAll(mapped);
                    _filteredPosts = List.from(_posts);
                    _isLoading = false;
                    _feedError = null;
                  });
                }
            }
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

  Future<void> _handlePost(String text, {String? topic}) async {
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

    final createResult = await _communityService.createPost(
      subthreadId: _activeSubthreadId!,
      title: (() {
        final trimmedTopic = (topic ?? '').trim();
        final base = text.length > 48 ? '${text.substring(0, 48)}...' : text;
        if (trimmedTopic.isEmpty) return base;
        return '$trimmedTopic > $base';
      })(),
      content: text,
    );

    switch (createResult) {
      case AppSuccess(:final value):
        final response = value;
        var confirmed = CommunityPostMapper.mapBackendPost(response, const []);
        if (confirmed.author.id == user.id) {
          confirmed = confirmed.copyWith(
            author: PostAuthor(
              id: user.id,
              displayName: user.firstName != null && user.lastName != null
                  ? '${user.firstName} ${user.lastName}'
                  : user.email.split('@')[0],
              username: user.email.split('@')[0],
              avatarUrl: null,
            ),
          );
        }
        if (!mounted) return;

        setState(() {
          final index = _posts.indexWhere((p) => p.id == tempId);
          if (index != -1) {
            _posts[index] = confirmed;
            _filterPosts();
          }
        });

      case AppFailure(:final error):
        await _outbox.enqueue(
          CommunityOutboxOperation(
            id: tempId,
            type: 'create_post',
            payload: {
              'subthread_id': _activeSubthreadId,
              'title': (() {
                final trimmedTopic = (topic ?? '').trim();
                final base =
                    text.length > 48 ? '${text.substring(0, 48)}...' : text;
                if (trimmedTopic.isEmpty) return base;
                return '$trimmedTopic > $base';
              })(),
              'content': text,
              'temp_id': tempId,
            },
          ),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not send post: ${error.userMessage}. '
              'Saved to retry automatically.',
            ),
          ),
        );
    }
  }

  bool _isPersistedPostId(String postId) {
    return _uuidRegExp.hasMatch(postId);
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
    final nextReposted = !post.repostedByCurrentUser;
    setState(() {
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        final currentPost = _posts[index];
        _posts[index] = currentPost.copyWith(
          repostedByCurrentUser: nextReposted,
          repostCount: currentPost.repostedByCurrentUser
              ? currentPost.repostCount - 1
              : currentPost.repostCount + 1,
        );
        _filterPosts();
      }
    });
    _syncPostRepost(postId: post.id, reposted: nextReposted);
  }

  Future<void> _handleReply(Post post) async {
    await _openThreadDetail(post);
  }

  Future<void> _handleShare(Post post) async {
    final result = await _communityService.sharePost(postId: post.id);
    if (!mounted) return;
    switch (result) {
      case AppSuccess():
        break;
      case AppFailure(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.userMessage)),
        );
    }
  }

  Future<void> _handlePostTap(Post post) async {
    await _openThreadDetail(post);
  }

  Future<void> _openThreadDetail(Post post) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ThreadDetailScreen(
          post: post,
          communityService: _communityService,
          onSubmitReply: (targetPost, text) =>
              _sendReply(post: targetPost, text: text),
          onLike: _handleLike,
          onRepost: _handleRepost,
          onShare: (p) {
            _handleShare(p);
          },
        ),
      ),
    );
    if (mounted) {
      await _loadFeed();
    }
  }

  Future<void> _sendReply({required Post post, required String text}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    if (!_isPersistedPostId(post.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for the post to finish syncing before replying.'),
        ),
      );
      return;
    }
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

    final commentResult = await _communityService.createComment(
      postId: post.id,
      content: text,
    );

    switch (commentResult) {
      case AppSuccess(:final value):
        final response = value;
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

      case AppFailure(:final error):
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
          SnackBar(
            content: Text(
              'Could not send reply: ${error.userMessage}. '
              'Saved to retry automatically.',
            ),
          ),
        );
    }
  }

  Future<void> _retryOutbox() async {
    final operations = await _outbox.load();
    if (operations.isEmpty) return;

    final pending = <CommunityOutboxOperation>[];
    for (final operation in operations) {
      var succeeded = false;
      if (operation.type == 'create_post') {
        final r = await _communityService.createPost(
          subthreadId: (operation.payload['subthread_id'] ?? '').toString(),
          title: (operation.payload['title'] ?? '').toString(),
          content: (operation.payload['content'] ?? '').toString(),
        );
        succeeded = r.isSuccess;
      } else if (operation.type == 'create_comment') {
        final r = await _communityService.createComment(
          postId: (operation.payload['post_id'] ?? '').toString(),
          content: (operation.payload['content'] ?? '').toString(),
        );
        succeeded = r.isSuccess;
      } else if (operation.type == 'vote_post') {
        final r = await _communityService.votePost(
          postId: (operation.payload['post_id'] ?? '').toString(),
          voteType: (operation.payload['vote_type'] as num?)?.toInt() ?? 0,
        );
        succeeded = r.isSuccess;
      } else if (operation.type == 'repost_post') {
        final reposted = operation.payload['reposted'] == true;
        final r = reposted
            ? await _communityService.repostPost(
                postId: (operation.payload['post_id'] ?? '').toString(),
              )
            : await _communityService.undoRepost(
                postId: (operation.payload['post_id'] ?? '').toString(),
              );
        succeeded = r.isSuccess;
      } else {
        // Unknown operation type: log warning and mark for retry
        AppLogger.instance.warning(
          '[ThreadsTab] Unknown outbox operation type: ${operation.type}',
          notifyUser: false,
        );
        succeeded = false;
      }
      if (!succeeded) {
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
    final voteResult = await _communityService.votePost(
      postId: postId,
      voteType: voteType,
    );
    switch (voteResult) {
      case AppSuccess():
        break;
      case AppFailure(:final error):
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
          SnackBar(
            content: Text(
              'Could not save vote: ${error.userMessage}. '
              'Saved to retry automatically.',
            ),
          ),
        );
    }
  }

  Future<void> _syncPostRepost({
    required String postId,
    required bool reposted,
  }) async {
    final result = reposted
        ? await _communityService.repostPost(postId: postId)
        : await _communityService.undoRepost(postId: postId);
    switch (result) {
      case AppSuccess():
        await _loadFeed();
      case AppFailure(:final error):
        await _outbox.enqueue(
          CommunityOutboxOperation(
            id: 'repost_${DateTime.now().millisecondsSinceEpoch}_$postId',
            type: 'repost_post',
            payload: {
              'post_id': postId,
              'reposted': reposted,
            },
          ),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not save repost: ${error.userMessage}. '
              'Saved to retry automatically.',
            ),
          ),
        );
    }
  }

  Future<void> _openDraftComposer() async {
    final draft = await Navigator.of(context).push<NewThreadDraftResult>(
      MaterialPageRoute(builder: (_) => const NewThreadDraftScreen()),
    );
    if (draft == null) return;
    final body = draft.content.trim();
    if (body.isEmpty) return;
    final topic = draft.topic?.trim();
    await _handlePost(body, topic: topic);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _posts.isEmpty && _feedError == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(SyntrakColors.primary),
        ),
      );
    }

    if (!_isLoading && _posts.isEmpty && _feedError != null) {
      final err = _feedError!;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(SyntrakSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                err.userMessage,
                textAlign: TextAlign.center,
                style: SyntrakTypography.bodyMedium.copyWith(
                  color: SyntrakColors.error,
                ),
              ),
              if (err.retryable) ...[
                const SizedBox(height: SyntrakSpacing.md),
                ElevatedButton(
                  onPressed: _loadFeed,
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
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
                onComposeTap: _openDraftComposer,
              );
            }
            final post = _filteredPosts[index - 1];
            return MessageCard(
              post: post,
              onTap: () => _handlePostTap(post),
              onLike: _handleLike,
              onRepost: _handleRepost,
              onReply: _handleReply,
              onShare: (p) {
                _handleShare(p);
              },
            );
          },
        ),
      ),
    );
  }
}
