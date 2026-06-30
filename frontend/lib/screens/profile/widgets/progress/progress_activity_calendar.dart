import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
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
      margin: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
      padding: const EdgeInsets.all(SyntrakSpacing.lg),
      decoration: BoxDecoration(
        color: SyntrakColors.surface,
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        border: Border.all(color: SyntrakColors.divider),
        boxShadow: SyntrakElevation.sm,
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
          titleTextStyle: SyntrakTypography.headlineSmall.copyWith(
            color: SyntrakColors.textPrimary,
          ),
          leftChevronIcon: const Icon(
            Icons.chevron_left,
            color: SyntrakColors.primary,
          ),
          rightChevronIcon: const Icon(
            Icons.chevron_right,
            color: SyntrakColors.primary,
          ),
        ),
        daysOfWeekVisible: true,
        onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: SyntrakTypography.labelSmall.copyWith(
            color: SyntrakColors.textSecondary,
          ),
          weekendTextStyle: SyntrakTypography.labelSmall.copyWith(
            color: SyntrakColors.textSecondary,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: SyntrakTypography.labelSmall.copyWith(
            color: SyntrakColors.textTertiary,
          ),
          weekendStyle: SyntrakTypography.labelSmall.copyWith(
            color: SyntrakColors.textTertiary,
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
        ? SyntrakColors.primary
        : Colors.transparent;
    final Color textColor = hasActivity
        ? SyntrakColors.textOnPrimary
        : (isToday ? SyntrakColors.primary : SyntrakColors.textSecondary);

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border:
            isToday && !hasActivity ? Border.all(color: SyntrakColors.primary, width: 2) : null,
      ),
      child: Center(
        child: Text(
          date.day.toString(),
          style: SyntrakTypography.labelSmall.copyWith(
            color: textColor,
            fontWeight: (isToday || hasActivity) ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
