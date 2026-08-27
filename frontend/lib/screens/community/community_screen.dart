import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/screens/community/threads_tab.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnowtrakColors.background,
      appBar: AppBar(
        title: const Text('Community'),
        elevation: 0,
        backgroundColor: SnowtrakColors.surface,
        foregroundColor: SnowtrakColors.textPrimary,
      ),
      body: const ThreadsTab(),
    );
  }
}
