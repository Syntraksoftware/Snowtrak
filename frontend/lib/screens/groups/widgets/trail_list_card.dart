import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/ski_trail.dart';

class TrailListCard extends StatelessWidget {
  const TrailListCard({super.key, required this.trail});

  final SkiTrail trail;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: SyntrakSpacing.md),
      decoration: BoxDecoration(
        color: SyntrakColors.surface,
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Trail details for ${trail.name} coming soon!'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          borderRadius: BorderRadius.circular(SyntrakRadius.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(SyntrakSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(trail.difficulty.color).withAlpha(40),
                      Color(trail.difficulty.color).withAlpha(10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(SyntrakRadius.lg),
                    topRight: Radius.circular(SyntrakRadius.lg),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(trail.difficulty.color),
                        borderRadius: BorderRadius.circular(SyntrakRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: Color(trail.difficulty.color).withAlpha(80),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          trail.difficulty.icon,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: SyntrakSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trail.name,
                            style: SyntrakTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.place,
                                size: 14,
                                color: SyntrakColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${trail.resort}, ${trail.country}',
                                  style: SyntrakTypography.bodySmall.copyWith(
                                    color: SyntrakColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (trail.rating != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SyntrakSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(30),
                          borderRadius: BorderRadius.circular(SyntrakRadius.sm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              trail.rating!.toStringAsFixed(1),
                              style: SyntrakTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(SyntrakSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TrailStatItem(
                          icon: Icons.straighten,
                          value: '${trail.lengthKm.toStringAsFixed(1)} km',
                          label: 'Length',
                        ),
                        const SizedBox(width: SyntrakSpacing.lg),
                        TrailStatItem(
                          icon: Icons.trending_down,
                          value: '${trail.elevationDropM} m',
                          label: 'Drop',
                        ),
                        const Spacer(),
                        if (trail.isGroomed)
                          TrailBadge(
                            icon: Icons.ac_unit,
                            label: 'Groomed',
                            color: SyntrakColors.info,
                          ),
                      ],
                    ),
                    if (trail.description != null) ...[
                      const SizedBox(height: SyntrakSpacing.md),
                      Text(
                        trail.description!,
                        style: SyntrakTypography.bodySmall.copyWith(
                          color: SyntrakColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (trail.features != null &&
                        trail.features!.isNotEmpty) ...[
                      const SizedBox(height: SyntrakSpacing.md),
                      Wrap(
                        spacing: SyntrakSpacing.xs,
                        runSpacing: SyntrakSpacing.xs,
                        children: trail.features!
                            .take(4)
                            .map((f) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: SyntrakColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(
                                        SyntrakRadius.round),
                                  ),
                                  child: Text(
                                    f,
                                    style:
                                        SyntrakTypography.labelSmall.copyWith(
                                      color: SyntrakColors.textSecondary,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TrailStatItem extends StatelessWidget {
  const TrailStatItem({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: SyntrakColors.textTertiary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: SyntrakTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: SyntrakColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: SyntrakTypography.labelSmall.copyWith(
                color: SyntrakColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class TrailBadge extends StatelessWidget {
  const TrailBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(SyntrakRadius.sm),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: SyntrakTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
