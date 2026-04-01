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
import 'package:syntrak/screens/community/community_repost_sheet.dart';
import 'package:syntrak/screens/community/new_thread_draft_screen.dart';
import 'package:syntrak/screens/community/threads_tab_action_builders.dart';
import 'package:syntrak/screens/community/threads_tab_action_coordinator.dart';
import 'package:syntrak/screens/community/thread_draft_builders.dart';
import 'package:syntrak/screens/community/thread_detail_screen.dart';
import 'package:syntrak/screens/community/threads_feed_loader.dart';
import 'package:syntrak/screens/community/threads_tab_feedback.dart';
import 'package:syntrak/screens/community/threads_tab_post_state.dart';
import 'package:syntrak/screens/community/threads_tab_sync_coordinator.dart';
import 'package:syntrak/screens/community/widgets/threads_search_bar.dart';
import 'package:syntrak/screens/community/widgets/threads_tab_sections.dart';

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
  final CommunityOutboxService _outboxService = CommunityOutboxService();
  final CommunityService _communityService = sl<CommunityService>();
  late final ThreadsTabActionCoordinator _actionCoordinator =
      ThreadsTabActionCoordinator(
        communityService: _communityService,
        outboxService: _outboxService,
      );
  late final ThreadsTabSyncCoordinator _syncCoordinator =
      ThreadsTabSyncCoordinator(communityService: _communityService);

  final List<Post> _posts = [];
  List<Post> _filteredPosts = [];

  bool _isRefreshing = false;
  bool _isLoading = false;
  int _activeUploadOps = 0;
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

  void _filterPosts() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      _filteredPosts = List.from(_posts);
    } else {
      _filteredPosts = _posts.where((post) {
        final topic = (post.topic ?? '').toLowerCase();
        return post.text.toLowerCase().contains(query) ||
            post.author.displayName.toLowerCase().contains(query) ||
            post.author.username.toLowerCase().contains(query) ||
            (topic.isNotEmpty && topic.contains(query));
      }).toList();
    }
  }

  void _recomputeVisiblePosts() {
    _filterPosts();
  }

  void _updatePosts(void Function() mutate) {
    setState(() {
      mutate();
      _recomputeVisiblePosts();
    });
  }

  Post _mapConfirmedPost(Map<String, dynamic> response, dynamic user) {
    return ThreadsTabActionBuilders.normalizeConfirmedAuthor(
      CommunityPostMapper.mapBackendPost(response, const []),
      user,
    );
  }

  void _prependOptimisticPost(Post post) {
    _updatePosts(() {
      ThreadsTabPostState.prepend(_posts, post);
    });
  }

  void _replaceTempPost(String tempId, Post confirmed) {
    _updatePosts(() {
      ThreadsTabPostState.replaceById(_posts, tempId, confirmed);
    });
  }

  void _removeTempPost(String tempId) {
    _updatePosts(() {
      ThreadsTabPostState.removeById(_posts, tempId);
    });
  }

  void _appendLocalReply({
    required String postId,
    required Post localReply,
  }) {
    _updatePosts(() {
      ThreadsTabPostState.appendLocalReply(
        posts: _posts,
        postId: postId,
        localReply: localReply,
      );
    });
  }

  void _replaceTempReply({
    required String postId,
    required String tempReplyId,
    required Post confirmedReply,
  }) {
    _updatePosts(() {
      ThreadsTabPostState.replaceReply(
        posts: _posts,
        postId: postId,
        tempReplyId: tempReplyId,
        confirmedReply: confirmedReply,
      );
    });
  }

  Future<T> _runWithUploadIndicator<T>(Future<T> Function() action) async {
    if (mounted) {
      setState(() => _activeUploadOps += 1);
    }
    try {
      return await action();
    } finally {
      if (mounted) {
        setState(() => _activeUploadOps = (_activeUploadOps - 1).clamp(0, 9999));
      }
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
      ThreadsTabFeedback.showMessage(context, error.userMessage);
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
        final subthreads = value;
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
        final feedResult = await ThreadsFeedLoader.load(
          service: _communityService,
          pageSize: _defaultPageSize,
          fetchBatchComments: _communityService.getCommentsForPosts,
        );
        switch (feedResult) {
          case AppFailure(:final error):
            _applyLoadFailure(error);
            return;
          case AppSuccess(:final value):
            _activeSubthreadId = value.activeSubthreadId;
            if (mounted) {
              setState(() {
                _posts
                  ..clear()
                  ..addAll(value.posts);
                _filteredPosts = List.from(_posts);
                _isLoading = false;
                _feedError = null;
              });
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

  Future<void> _handlePost(
    String text, {
    String? topic,
    String? quotedPostId,
    String? quotedCommentId,
    Post? quotePreview,
    List<String> mediaUrls = const [],
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null || _activeSubthreadId == null) return;

    final tempId = ThreadsTabActionBuilders.tempId('tmp');

    final trimmedTopic = (topic ?? '').trim();
    final body = text.trim();
    final titleLine =
        CommunityDraftBuilders.buildServerTitle(text: body, topic: trimmedTopic);

    final qid = (quotedPostId ?? '').trim();
    final qcid = (quotedCommentId ?? '').trim();
    final previewPost = (qid.isNotEmpty && quotePreview != null && !quotePreview.isComment)
        ? quotePreview
        : null;
    final previewComment = (qcid.isNotEmpty && quotePreview != null && quotePreview.isComment)
        ? quotePreview
        : null;

    final newPost = ThreadsTabActionBuilders.optimisticPost(
      tempId: tempId,
      user: user,
      text: text,
      titleLine: titleLine,
      subthreadId: _activeSubthreadId!,
      topic: trimmedTopic,
      quotedPostId: qid.isEmpty ? null : qid,
      quotedCommentId: qcid.isEmpty ? null : qcid,
      previewPost: previewPost,
      previewComment: previewComment,
      mediaUrls: mediaUrls,
    );

    _prependOptimisticPost(newPost);

    final createResult = await _runWithUploadIndicator(
      () => _actionCoordinator.createPost(
        subthreadId: _activeSubthreadId!,
        title: titleLine,
        content: text,
        quotedPostId: qid.isEmpty ? null : qid,
        quotedCommentId: qcid.isEmpty ? null : qcid,
        mediaUrls: mediaUrls.isEmpty ? null : mediaUrls,
      ),
    );

    switch (createResult) {
      case AppSuccess(:final value):
        final response = value;
        final confirmed = _mapConfirmedPost(response, user);
        if (!mounted) return;
        _replaceTempPost(tempId, confirmed);

      case AppFailure(:final error):
        await _actionCoordinator.enqueueCreatePost(
          tempId: tempId,
          subthreadId: _activeSubthreadId,
          title: titleLine,
          content: text,
          quotedPostId: qid.isEmpty ? null : qid,
          quotedCommentId: qcid.isEmpty ? null : qcid,
          mediaUrls: mediaUrls.isEmpty ? null : mediaUrls,
        );

        if (!mounted) return;
        ThreadsTabFeedback.showCouldNotSend(
          context,
          operation: 'post',
          error: error,
        );
    }
  }

  bool _isPersistedPostId(String postId) {
    return _uuidRegExp.hasMatch(postId);
  }

  void _handleLike(Post post) {
    if (!_isPersistedPostId(post.id)) {
      ThreadsTabFeedback.showWaitForSync(context, 'liking');
      return;
    }
    final nextLiked = !post.likedByCurrentUser;
    final nextVoteType = nextLiked ? 1 : 0;

    setState(() {
      ThreadsTabPostState.toggleLike(_posts, post.id);
      _recomputeVisiblePosts();
    });

    _syncPostVote(postId: post.id, voteType: nextVoteType);
  }

  void _showRepostOptions(Post post) {
    if (!_isPersistedPostId(post.id)) {
      ThreadsTabFeedback.showWaitForSync(context, 'reposting');
      return;
    }
    showCommunityRepostSheet(
      context,
      onDuplicateRepost: () => _duplicateRepostPost(post),
      onQuote: () => _openQuoteComposer(post),
    );
  }

  Future<void> _duplicateRepostPost(Post source) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null || _activeSubthreadId == null) return;

    final subthreadId = source.subthreadId.isNotEmpty
        ? source.subthreadId
        : _activeSubthreadId!;

    final tempId = ThreadsTabActionBuilders.tempId('tmp');

    if (source.isComment) {
      final trimmed = source.text.trim();
      final titleLine = trimmed.isEmpty
          ? 'Comment'
          : (trimmed.length > 80 ? '${trimmed.substring(0, 80)}...' : trimmed);
      final dupCommentMedia = source.media == null || source.media!.isEmpty
          ? null
          : List<String>.from(source.media!);
      final duplicate = ThreadsTabActionBuilders.optimisticCommentRepost(
        tempId: tempId,
        user: user,
        source: source,
        titleLine: titleLine,
        subthreadId: subthreadId,
        mediaUrls: dupCommentMedia,
      );

      _prependOptimisticPost(duplicate);

      final createResult = await _runWithUploadIndicator(
        () => _actionCoordinator.createCommentRepost(
          subthreadId: subthreadId,
          title: titleLine,
          content: source.text.trim(),
          repostOfCommentId: source.id,
          mediaUrls: dupCommentMedia,
        ),
      );

      switch (createResult) {
        case AppSuccess(:final value):
          final confirmed = _mapConfirmedPost(value, user);
          if (!mounted) return;
          _replaceTempPost(tempId, confirmed);
          await _loadFeed();
        case AppFailure(:final error):
          _removeTempPost(tempId);
          if (!mounted) return;
          ThreadsTabFeedback.showCouldNotComplete(
            context,
            operation: 'repost',
            error: error,
          );
      }
      return;
    }

    final duplicate = ThreadsTabActionBuilders.optimisticPostRepost(
      tempId: tempId,
      user: user,
      source: source,
      subthreadId: subthreadId,
    );

    _prependOptimisticPost(duplicate);

    final dupQid = (source.quotedPostId ?? '').trim();
    final dupMedia = source.media == null || source.media!.isEmpty
        ? null
        : List<String>.from(source.media!);
    final createResult = await _runWithUploadIndicator(
      () => _actionCoordinator.createPostRepost(
        subthreadId: subthreadId,
        title: source.composeServerTitle(),
        content: source.text.trim(),
        quotedPostId: dupQid.isEmpty ? null : dupQid,
        repostOfPostId: source.id,
        mediaUrls: dupMedia,
      ),
    );

    switch (createResult) {
      case AppSuccess(:final value):
        final confirmed = _mapConfirmedPost(value, user);
        if (!mounted) return;
        _replaceTempPost(tempId, confirmed);
        await _loadFeed();
      case AppFailure(:final error):
        _removeTempPost(tempId);
        if (!mounted) return;
        ThreadsTabFeedback.showCouldNotComplete(
          context,
          operation: 'repost',
          error: error,
        );
    }
  }

  Future<void> _openQuoteComposer(Post source) async {
    final draft = await Navigator.of(context).push<NewThreadDraftResult>(
      MaterialPageRoute(
        builder: (_) => NewThreadDraftScreen(quotedPost: source),
      ),
    );
    if (draft == null) return;
    final body = draft.content.trim();
    if (body.isEmpty && draft.mediaUrls.isEmpty) return;
    final topic = draft.topic?.trim();
    final qid = (draft.quotedPostId ?? '').trim();
    final qcid = (draft.quotedCommentId ?? '').trim();
    await _handlePost(
      body,
      topic: topic,
      quotedPostId: qid.isEmpty ? null : qid,
      quotedCommentId: qcid.isEmpty ? null : qcid,
      quotePreview: source,
      mediaUrls: draft.mediaUrls,
    );
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
        ThreadsTabFeedback.showMessage(context, error.userMessage);
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
          onSubmitReply: (targetPost, text, mediaUrls) => _sendReply(
                post: targetPost,
                text: text,
                mediaUrls: mediaUrls,
              ),
          onLike: _handleLike,
          onRepost: _showRepostOptions,
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

  Future<void> _sendReply({
    required Post post,
    required String text,
    List<String> mediaUrls = const [],
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    if (!_isPersistedPostId(post.id)) {
      ThreadsTabFeedback.showMessage(
        context,
        'Please wait for the post to finish syncing before replying.',
      );
      return;
    }
    if (text.trim().isEmpty && mediaUrls.isEmpty) {
      return;
    }
    final tempReplyId = ThreadsTabActionBuilders.tempId('tmp_reply');
    final localReply = ThreadsTabActionBuilders.optimisticReply(
      tempId: tempReplyId,
      user: user,
      text: text,
    );

    _appendLocalReply(postId: post.id, localReply: localReply);

    final commentResult = await _runWithUploadIndicator(
      () => _actionCoordinator.createReply(
        postId: post.id,
        content: text,
        mediaUrls: mediaUrls.isEmpty ? null : mediaUrls,
      ),
    );

    switch (commentResult) {
      case AppSuccess(:final value):
        final response = value;
        final confirmedReply = CommunityPostMapper.mapCommentToPost(
          response,
          threadSubthreadId: post.subthreadId,
          parentPostId: post.id,
        );
        if (!mounted) return;

        _replaceTempReply(
          postId: post.id,
          tempReplyId: tempReplyId,
          confirmedReply: confirmedReply,
        );

      case AppFailure(:final error):
        await _actionCoordinator.enqueueCreateComment(
          tempReplyId: tempReplyId,
          postId: post.id,
          content: text,
          mediaUrls: mediaUrls.isEmpty ? null : mediaUrls,
        );

        if (!mounted) return;
        ThreadsTabFeedback.showCouldNotSend(
          context,
          operation: 'reply',
          error: error,
        );
    }
  }

  Future<void> _retryOutbox() async {
    final operations = await _actionCoordinator.loadOutbox();
    if (operations.isEmpty) return;

    final pending = await _syncCoordinator.retryOutbox(
      operations,
      onUnknownOperationType: (operationType) {
        AppLogger.instance.warning(
          '[ThreadsTab] Unknown outbox operation type: $operationType',
          notifyUser: false,
        );
      },
    );

    await _actionCoordinator.replaceOutbox(pending);
    if (mounted) {
      await _loadFeed();
    }
  }

  Future<void> _syncPostVote({
    required String postId,
    required int voteType,
  }) async {
    final voteResult = await _syncCoordinator.syncPostVote(
      postId: postId,
      voteType: voteType,
    );
    switch (voteResult) {
      case AppSuccess():
        break;
      case AppFailure(:final error):
        await _actionCoordinator.enqueueVotePost(
          postId: postId,
          voteType: voteType,
        );
        if (!mounted) return;
        ThreadsTabFeedback.showCouldNotSave(
          context,
          operation: 'vote',
          error: error,
        );
    }
  }

  Future<void> _openDraftComposer() async {
    final draft = await Navigator.of(context).push<NewThreadDraftResult>(
      MaterialPageRoute(builder: (_) => const NewThreadDraftScreen()),
    );
    if (draft == null) return;
    final body = draft.content.trim();
    if (body.isEmpty && draft.mediaUrls.isEmpty) return;
    final topic = draft.topic?.trim();
    await _handlePost(body, topic: topic, mediaUrls: draft.mediaUrls);
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
      return ThreadsEmptyState(
        message: err.userMessage,
        retryable: err.retryable,
        onRetry: _loadFeed,
      );
    }

    return Stack(
      children: [
        NestedScrollView(
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
          body: ThreadsFeedBody(
            posts: _filteredPosts,
            onRefresh: _handleRefresh,
            onComposerSubmit: (text) => _handlePost(text),
            onComposeTap: _openDraftComposer,
            onPostTap: _handlePostTap,
            onLike: _handleLike,
            onRepost: _showRepostOptions,
            onReply: _handleReply,
            onShare: _handleShare,
          ),
        ),
        if (_activeUploadOps > 0)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LinearProgressIndicator(
              minHeight: 2.5,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(SyntrakColors.primary),
            ),
          ),
      ],
    );
  }
}
