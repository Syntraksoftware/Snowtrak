import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/screens/community/threads_tab.dart';
import 'package:syntrak/screens/community/trails_tab.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyntrakColors.background,
      appBar: AppBar(
        title: const Text('Community'),
        elevation: 0,
        backgroundColor: SyntrakColors.surface,
        foregroundColor: SyntrakColors.textPrimary,
        actions: const [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            decoration: BoxDecoration(
              color: SyntrakColors.background,
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(SyntrakRadius.md),
                  topRight: Radius.circular(SyntrakRadius.md),
                ),
                color: SyntrakColors.primary.withAlpha(25),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.symmetric(
                horizontal: SyntrakSpacing.sm,
                vertical: SyntrakSpacing.xs,
              ),
              labelColor: SyntrakColors.primary,
              unselectedLabelColor: SyntrakColors.textTertiary,
              labelStyle: SyntrakTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              unselectedLabelStyle: SyntrakTypography.labelLarge.copyWith(
                fontSize: 15,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Threads'),
                Tab(text: 'Trails'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ThreadsTab(),
          TrailsTab(),
        ],
      ),
    );
  }
}
