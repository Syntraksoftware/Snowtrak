import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:table_calendar/table_calendar.dart';

class ProgressActivityCalendar extends StatefulWidget {
  const ProgressActivityCalendar({
    super.key,
    required this.activityDays,
  });

  final Set<DateTime> activityDays;

  @override
  State<ProgressActivityCalendar> createState() =>
      _ProgressActivityCalendarState();
}

class _ProgressActivityCalendarState extends State<ProgressActivityCalendar> {
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final firstDay = today.subtract(const Duration(days: 90));
    final lastDay = today.add(const Duration(days: 60));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SnowtrakSpacing.md),
      padding: const EdgeInsets.all(SnowtrakSpacing.lg),
      decoration: BoxDecoration(
        color: SnowtrakColors.surface,
        borderRadius: BorderRadius.circular(SnowtrakRadius.lg),
        border: Border.all(color: SnowtrakColors.divider),
        boxShadow: SnowtrakElevation.sm,
      ),
      child: TableCalendar(
        firstDay: firstDay,
        lastDay: lastDay,
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerVisible: true,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: SnowtrakTypography.headlineSmall.copyWith(
            color: SnowtrakColors.textPrimary,
          ),
          leftChevronIcon: const Icon(
            Icons.chevron_left,
            color: SnowtrakColors.primary,
          ),
          rightChevronIcon: const Icon(
            Icons.chevron_right,
            color: SnowtrakColors.primary,
          ),
        ),
        daysOfWeekVisible: true,
        onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: SnowtrakTypography.labelSmall.copyWith(
            color: SnowtrakColors.textSecondary,
          ),
          weekendTextStyle: SnowtrakTypography.labelSmall.copyWith(
            color: SnowtrakColors.textSecondary,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: SnowtrakTypography.labelSmall.copyWith(
            color: SnowtrakColors.textTertiary,
          ),
          weekendStyle: SnowtrakTypography.labelSmall.copyWith(
            color: SnowtrakColors.textTertiary,
          ),
        ),
        selectedDayPredicate: (_) => false,
        onDaySelected: (_, __) {},
        calendarBuilders: CalendarBuilders(
          todayBuilder: (context, date, _) {
            final hasActivity = widget.activityDays
                .contains(DateTime(date.year, date.month, date.day));
            return _DayCell(
                date: date, hasActivity: hasActivity, isToday: true);
          },
          defaultBuilder: (context, date, _) {
            final hasActivity = widget.activityDays
                .contains(DateTime(date.year, date.month, date.day));
            return _DayCell(
                date: date, hasActivity: hasActivity, isToday: false);
          },
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell(
      {required this.date, required this.hasActivity, required this.isToday});

  final DateTime date;
  final bool hasActivity;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final Color bg = hasActivity
        ? SnowtrakColors.primary
        : Colors.transparent;
    final Color textColor = hasActivity
        ? SnowtrakColors.textOnPrimary
        : (isToday ? SnowtrakColors.primary : SnowtrakColors.textSecondary);

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border:
            isToday && !hasActivity ? Border.all(color: SnowtrakColors.primary, width: 2) : null,
      ),
      child: Center(
        child: Text(
          date.day.toString(),
          style: SnowtrakTypography.labelSmall.copyWith(
            color: textColor,
            fontWeight: (isToday || hasActivity) ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
