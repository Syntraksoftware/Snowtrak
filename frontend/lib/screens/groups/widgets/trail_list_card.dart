import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/ski_trail.dart';

class TrailListCard extends StatelessWidget {
  const TrailListCard({super.key, required this.trail});

  final SkiTrail trail;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: SnowtrakSpacing.md),
      decoration: BoxDecoration(
        color: SnowtrakColors.surface,
        borderRadius: BorderRadius.circular(SnowtrakRadius.lg),
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
          borderRadius: BorderRadius.circular(SnowtrakRadius.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(SnowtrakSpacing.md),
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
                    topLeft: Radius.circular(SnowtrakRadius.lg),
                    topRight: Radius.circular(SnowtrakRadius.lg),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(trail.difficulty.color),
                        borderRadius: BorderRadius.circular(SnowtrakRadius.md),
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
                    const SizedBox(width: SnowtrakSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trail.name,
                            style: SnowtrakTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.place,
                                size: 14,
                                color: SnowtrakColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${trail.resort}, ${trail.country}',
                                  style: SnowtrakTypography.bodySmall.copyWith(
                                    color: SnowtrakColors.textSecondary,
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
                          horizontal: SnowtrakSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: SnowtrakColors.warning.withAlpha(30),
                          borderRadius: BorderRadius.circular(SnowtrakRadius.sm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                color: SnowtrakColors.warning, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              trail.rating!.toStringAsFixed(1),
                              style: SnowtrakTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: SnowtrakColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(SnowtrakSpacing.md),
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
                        const SizedBox(width: SnowtrakSpacing.lg),
                        TrailStatItem(
                          icon: Icons.trending_down,
                          value: '${trail.elevationDropM} m',
                          label: 'Drop',
                        ),
                        const Spacer(),
                        if (trail.isGroomed)
                          const TrailBadge(
                            icon: Icons.ac_unit,
                            label: 'Groomed',
                            color: SnowtrakColors.info,
                          ),
                      ],
                    ),
                    if (trail.description != null) ...[
                      const SizedBox(height: SnowtrakSpacing.md),
                      Text(
                        trail.description!,
                        style: SnowtrakTypography.bodySmall.copyWith(
                          color: SnowtrakColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (trail.features != null &&
                        trail.features!.isNotEmpty) ...[
                      const SizedBox(height: SnowtrakSpacing.md),
                      Wrap(
                        spacing: SnowtrakSpacing.xs,
                        runSpacing: SnowtrakSpacing.xs,
                        children: trail.features!
                            .take(4)
                            .map((f) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: SnowtrakColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(
                                        SnowtrakRadius.round),
                                  ),
                                  child: Text(
                                    f,
                                    style:
                                        SnowtrakTypography.labelSmall.copyWith(
                                      color: SnowtrakColors.textSecondary,
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
        Icon(icon, size: 18, color: SnowtrakColors.textTertiary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: SnowtrakTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: SnowtrakColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: SnowtrakTypography.labelSmall.copyWith(
                color: SnowtrakColors.textTertiary,
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
        borderRadius: BorderRadius.circular(SnowtrakRadius.sm),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: SnowtrakTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
