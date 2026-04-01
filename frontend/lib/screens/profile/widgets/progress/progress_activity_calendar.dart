import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syntrak/core/theme.dart';
import 'package:table_calendar/table_calendar.dart';

class ProgressActivityCalendar extends StatelessWidget {
  const ProgressActivityCalendar({
    super.key,
    required this.activityDays,
  });

  final Set<DateTime> activityDays;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final focusedDay = DateTime(now.year, now.month, now.day);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
      padding: const EdgeInsets.all(SyntrakSpacing.lg),
      decoration: BoxDecoration(
        color: SyntrakColors.surface,
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        border: Border.all(color: SyntrakColors.divider),
        boxShadow: SyntrakElevation.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(now),
            style: SyntrakTypography.headlineSmall.copyWith(
              color: SyntrakColors.textPrimary,
            ),
          ),
          const SizedBox(height: SyntrakSpacing.md),
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: focusedDay,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerVisible: false,
            daysOfWeekVisible: true,
            eventLoader: (date) {
              final normalizedDate = DateTime(date.year, date.month, date.day);
              return activityDays.contains(normalizedDate) ? [1] : [];
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: SyntrakTypography.labelSmall.copyWith(
                color: SyntrakColors.textSecondary,
              ),
              weekendTextStyle: SyntrakTypography.labelSmall.copyWith(
                color: SyntrakColors.textSecondary,
              ),
              selectedTextStyle: SyntrakTypography.labelSmall.copyWith(
                color: SyntrakColors.primary,
                fontWeight: FontWeight.w600,
              ),
              todayTextStyle: SyntrakTypography.labelSmall.copyWith(
                color: SyntrakColors.primary,
                fontWeight: FontWeight.w600,
              ),
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: SyntrakColors.primary,
                  width: 2,
                ),
              ),
              selectedDecoration: BoxDecoration(
                color: SyntrakColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: SyntrakColors.primary,
                shape: BoxShape.circle,
              ),
              markerSize: 4,
              markerMargin: const EdgeInsets.only(bottom: 4),
              cellMargin: const EdgeInsets.all(4),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: SyntrakTypography.labelSmall.copyWith(
                color: SyntrakColors.textTertiary,
              ),
              weekendStyle: SyntrakTypography.labelSmall.copyWith(
                color: SyntrakColors.textTertiary,
              ),
            ),
            selectedDayPredicate: (date) => false,
            onDaySelected: (selectedDay, focusedDay) {},
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, date, _) {
                final normalizedDate =
                    DateTime(date.year, date.month, date.day);
                final hasActivity = activityDays.contains(normalizedDate);
                final isToday = date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;

                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: hasActivity
                        ? SyntrakColors.primary.withOpacity(0.2)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday
                        ? Border.all(color: SyntrakColors.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      date.day.toString(),
                      style: SyntrakTypography.labelSmall.copyWith(
                        color: hasActivity
                            ? SyntrakColors.primary
                            : SyntrakColors.textSecondary,
                        fontWeight:
                            isToday ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
