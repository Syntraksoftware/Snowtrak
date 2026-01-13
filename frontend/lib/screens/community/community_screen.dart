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
      body: SafeArea(
        child: Column(
          children: [
            // Header with title
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SyntrakSpacing.md,
                vertical: SyntrakSpacing.sm,
              ),
              color: SyntrakColors.surface,
              child: Row(
                children: [
                  Text(
                    'Community',
                    style: SyntrakTypography.headlineLarge.copyWith(
                      color: SyntrakColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      // TODO: Implement search
                    },
                  ),
                ],
              ),
            ),
            // Tab bar
            Container(
              color: SyntrakColors.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: SyntrakColors.primary,
                unselectedLabelColor: SyntrakColors.textSecondary,
                indicatorColor: SyntrakColors.primary,
                indicatorWeight: 3,
                labelStyle: SyntrakTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: SyntrakTypography.labelLarge,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.forum_outlined),
                    text: 'Threads',
                  ),
                  Tab(
                    icon: Icon(Icons.downhill_skiing),
                    text: 'Trails',
                  ),
                ],
              ),
            ),
            // Divider
            Container(
              height: 1,
              color: SyntrakColors.divider,
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  ThreadsTab(),
                  TrailsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
