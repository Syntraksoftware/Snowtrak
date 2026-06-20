import 'package:flutter/material.dart';
import 'package:syntrak/core/activity_helpers.dart';
import 'package:syntrak/models/activity.dart';

/// Shows a compact half-screen modal picker. Returns the chosen [ActivityType]
/// or null if dismissed.
Future<ActivityType?> showActivityTypePicker(BuildContext context) {
  return showModalBottomSheet<ActivityType>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _ActivityTypePicker(),
  );
}

class _ActivityTypePicker extends StatelessWidget {
  const _ActivityTypePicker();

  static const _types = [
    ActivityType.alpine,
    ActivityType.crossCountry,
    ActivityType.freestyle,
    ActivityType.backcountry,
    ActivityType.snowboard,
    ActivityType.other,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Activity',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
            children: _types
                .map((t) => _TypeTile(
                      type: t,
                      onTap: () => Navigator.pop(context, t),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.type, required this.onTap});
  final ActivityType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = ActivityHelpers.getActivityColor(type);
    final icon = ActivityHelpers.getActivityIcon(type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              type.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
