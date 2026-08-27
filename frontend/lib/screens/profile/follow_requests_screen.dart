import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:snowtrak/core/di/service_locator.dart';
import 'package:snowtrak/core/errors/app_error.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/screens/profile/widgets/profile_layout_primitives.dart';
import 'package:snowtrak/services/follow_service.dart';
import 'package:snowtrak/ui/st/st.dart';

/// Opens the incoming follow-requests screen.
///
/// Mirrors [openUserProfile]: pushing this needs nothing but a context, so
/// call sites (the profile badge) use this instead of threading state.
Future<void> openFollowRequests(BuildContext context) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const FollowRequestsScreen()),
  );
}

/// The whole notification surface for private accounts.
///
/// There is no push -- `device_tokens` exists as a table and no backend code
/// has ever read it -- so this list is the only place a pending request ever
/// surfaces. An empty state that said nothing, or a badge nobody notices,
/// would mean the feature silently does not work for its user.
class FollowRequestsScreen extends StatefulWidget {
  const FollowRequestsScreen({super.key});

  @override
  State<FollowRequestsScreen> createState() => _FollowRequestsScreenState();
}

class _FollowRequestsScreenState extends State<FollowRequestsScreen> {
  final FollowService _followService = sl<FollowService>();
  final List<Map<String, dynamic>> _requests = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  bool _errorRetryable = true;
  int _offset = 0;
  static const int _limit = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load({bool refresh = false}) async {
    if (!refresh && (_isLoading || _isLoadingMore)) return;
    if (!mounted) return;

    setState(() {
      if (refresh) {
        _offset = 0;
        _hasMore = true;
        _requests.clear();
        _isLoading = true;
        _isLoadingMore = false;
      } else if (!_isLoading) {
        _isLoading = true;
        _isLoadingMore = false;
      } else {
        _isLoadingMore = true;
      }
      _error = null;
      _errorRetryable = true;
    });

    final result =
        await _followService.getRequests(limit: _limit, offset: _offset);
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _requests.addAll(value);
          _offset += value.length;
          _hasMore = value.length == _limit;
          _isLoading = false;
          _isLoadingMore = false;
        });
      case AppFailure(:final error):
        setState(() {
          _error = error.userMessage;
          _errorRetryable = error.retryable;
          _isLoading = false;
          _isLoadingMore = false;
        });
    }
  }

  Future<void> _handleRefresh() => _load(refresh: true);

  Future<void> _approve(int index) async {
    final removed = _requests[index];
    final userId = removed['user_id'] as String? ?? '';

    // Same reasoning as FollowButton: flip first, let the server's answer
    // correct a wrong guess a moment later.
    setState(() => _requests.removeAt(index));

    final result = await _followService.approveRequest(userId);
    if (!mounted) return;

    switch (result) {
      case AppSuccess():
        return;
      case AppFailure(:final error):
        if (_isNotFound(error)) {
          // 404 here means the requester withdrew between the list loading
          // and this tap -- the request the server knew about is already
          // gone. The row is already correctly absent; putting it back would
          // resurrect a request nobody can act on anymore.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('That request is no longer pending.'),
            ),
          );
          return;
        }
        _restore(index, removed);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.userMessage)),
        );
    }
  }

  Future<void> _deny(int index) async {
    final removed = _requests[index];
    final userId = removed['user_id'] as String? ?? '';

    setState(() => _requests.removeAt(index));

    // The endpoint succeeds even if there was nothing to deny, so a failure
    // here is a real network/server problem, not a stale row.
    final result = await _followService.denyRequest(userId);
    if (!mounted) return;

    switch (result) {
      case AppSuccess():
        return;
      case AppFailure(:final error):
        _restore(index, removed);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.userMessage)),
        );
    }
  }

  /// Re-inserts at the original position, clamped to the current length --
  /// another row may have been approved or denied while this one was in
  /// flight.
  void _restore(int index, Map<String, dynamic> removed) {
    if (!mounted) return;
    setState(() {
      final at = index.clamp(0, _requests.length);
      _requests.insert(at, removed);
    });
  }

  bool _isNotFound(AppError error) {
    final cause = error.cause;
    return cause is DioException && cause.response?.statusCode == 404;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      // StPageHeader is a plain container, not an AppBar -- it does not
      // inset itself for the status bar, so as `appBar:` it drew under the
      // notch. It belongs inside SafeArea, the way UserProfileScreen uses it.
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            StPageHeader(
              title: 'Follow requests',
              leading: BackButton(color: context.colors.textPrimary),
            ),
            Expanded(
              child: RefreshIndicator(
                color: context.colors.primary,
                onRefresh: _handleRefresh,
                child: _body(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_isLoading && _requests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Padding(
            padding: EdgeInsets.all(SnowtrakSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_error != null && _requests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(SnowtrakSpacing.xl),
            child: Column(
              children: [
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: SnowtrakTypography.bodyMedium
                      .copyWith(color: context.colors.error),
                ),
                if (_errorRetryable) ...[
                  const SizedBox(height: SnowtrakSpacing.md),
                  ElevatedButton(
                    onPressed: () => _load(refresh: true),
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    if (_requests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Padding(
            padding: EdgeInsets.all(SnowtrakSpacing.xl),
            child: ProfilePlaceholderBlock(
              icon: Icons.person_add_alt_1_outlined,
              label: 'No follow requests',
              height: 140,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _requests.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _requests.length) {
          if (_hasMore && !_isLoadingMore) {
            // Reached the tail: pull the next page in after this frame.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _hasMore && !_isLoadingMore) _load();
            });
          }
          return const Padding(
            padding: EdgeInsets.all(SnowtrakSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return _RequestRow(
          request: _requests[index],
          onApprove: () => _approve(index),
          onDeny: () => _deny(index),
        );
      },
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.request,
    required this.onApprove,
    required this.onDeny,
  });

  final Map<String, dynamic> request;
  final VoidCallback onApprove;
  final VoidCallback onDeny;

  String get _name {
    final first = (request['first_name'] as String?)?.trim() ?? '';
    final last = (request['last_name'] as String?)?.trim() ?? '';
    final full = [first, last].where((s) => s.isNotEmpty).join(' ');
    return full.isNotEmpty ? full : 'User';
  }

  String get _handle {
    final email = (request['email'] as String?)?.trim() ?? '';
    if (!email.contains('@')) return '';
    return '@${email.split('@').first}';
  }

  @override
  Widget build(BuildContext context) {
    final name = _name;
    final handle = _handle;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SnowtrakSpacing.md,
        vertical: SnowtrakSpacing.sm,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: context.colors.primary.withValues(alpha: 0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: SnowtrakTypography.headlineSmall
                  .copyWith(color: context.colors.primary),
            ),
          ),
          const SizedBox(width: SnowtrakSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: SnowtrakTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
                if (handle.isNotEmpty)
                  Text(
                    handle,
                    style: SnowtrakTypography.bodySmall
                        .copyWith(color: context.colors.textSecondary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: SnowtrakSpacing.sm),
          OutlinedButton(
            onPressed: onDeny,
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.textPrimary,
              side: BorderSide(color: context.colors.borderStrong),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SnowtrakRadius.md),
              ),
            ),
            child: const Text('Deny'),
          ),
          const SizedBox(width: SnowtrakSpacing.sm),
          FilledButton(
            onPressed: onApprove,
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SnowtrakRadius.md),
              ),
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }
}
