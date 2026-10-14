import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/personal_event.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/event_card.dart';
import '../event/add_edit_event_screen.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  List<PersonalEvent> _eventsOn(List<PersonalEvent> all, DateTime day) {
    return all.where((e) => e.isSameDay(day)).toList()
      ..sort((a, b) => (a.startMinutes ?? -1).compareTo(b.startMinutes ?? -1));
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser!.uid;

    return StreamBuilder<List<PersonalEvent>>(
      stream: FirestoreService.instance.watchPersonalEvents(uid),
      builder: (context, snap) {
        final allEvents = snap.data ?? [];
        final selectedEvents = _eventsOn(allEvents, _selectedDay);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Personal calendar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AddEditEventScreen(initialDate: _selectedDay)),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add event'),
                  ),
                ],
              ),
              if (snap.hasError)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: RsuColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text('Could not load your calendar: ${snap.error}', style: const TextStyle(color: RsuColors.danger)),
                  ),
                ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TableCalendar<PersonalEvent>(
                    firstDay: DateTime.now().subtract(const Duration(days: 365)),
                    lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
                    focusedDay: _focusedDay,
                    rowHeight: 78,
                    daysOfWeekHeight: 24,
                    selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                    eventLoader: (day) => _eventsOn(allEvents, day),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    },
                    onPageChanged: (focused) => _focusedDay = focused,
                    calendarFormat: CalendarFormat.month,
                    headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RsuColors.teal),
                      weekendStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RsuColors.gold),
                    ),
                    // Custom boxed day cells (see _CalendarDayCell below) replace
                    // table_calendar's default plain-number + dot rendering, so
                    // every day reads as a distinct card with a quick preview of
                    // what's on it, plus hover feedback on web/desktop.
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) =>
                          _CalendarDayCell(day: day, events: _eventsOn(allEvents, day)),
                      outsideBuilder: (context, day, focusedDay) =>
                          _CalendarDayCell(day: day, events: _eventsOn(allEvents, day), isOutsideMonth: true),
                      todayBuilder: (context, day, focusedDay) =>
                          _CalendarDayCell(day: day, events: _eventsOn(allEvents, day), isToday: true),
                      selectedBuilder: (context, day, focusedDay) =>
                          _CalendarDayCell(day: day, events: _eventsOn(allEvents, day), isSelected: true),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (selectedEvents.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('No events on this day.', style: Theme.of(context).textTheme.bodyMedium),
                )
              else
                ...selectedEvents.map(
                  (e) => EventCard(
                    event: e,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AddEditEventScreen(existing: e)),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

/// One boxed day cell in the month grid: date number, a thin divider,
/// then a quick at-a-glance preview of that day's first event (and a
/// "+N more" hint if there's more than one) — so the student can scan
/// the whole month without tapping into each day. Hovering (web/desktop)
/// lifts the box slightly with a gold glow, matching the feedback style
/// used on the profile photo picker.
class _CalendarDayCell extends StatefulWidget {
  final DateTime day;
  final List<PersonalEvent> events;
  final bool isSelected;
  final bool isToday;
  final bool isOutsideMonth;

  const _CalendarDayCell({
    required this.day,
    required this.events,
    this.isSelected = false,
    this.isToday = false,
    this.isOutsideMonth = false,
  });

  @override
  State<_CalendarDayCell> createState() => _CalendarDayCellState();
}

class _CalendarDayCellState extends State<_CalendarDayCell> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasEvents = widget.events.isNotEmpty;

    final Color bg;
    final Color borderColor;
    final Color numberColor;

    if (widget.isSelected) {
      bg = RsuColors.navy;
      borderColor = RsuColors.navy;
      numberColor = Colors.white;
    } else if (widget.isToday) {
      bg = isDark ? RsuColors.surfaceDark : Colors.white;
      borderColor = RsuColors.teal;
      numberColor = RsuColors.teal;
    } else {
      bg = isDark ? RsuColors.surfaceDark : Colors.white;
      borderColor = isDark ? const Color(0xFF26305C) : const Color(0xFFE3E7F2);
      numberColor = widget.isOutsideMonth
          ? (isDark ? Colors.white24 : Colors.black26)
          : (isDark ? Colors.white : Colors.black87);
    }

    final dividerColor = widget.isSelected ? Colors.white30 : borderColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _hovering ? RsuColors.gold : borderColor, width: _hovering ? 1.4 : 1),
            boxShadow: _hovering
                ? [BoxShadow(color: RsuColors.gold.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.day.day}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: numberColor),
              ),
              const SizedBox(height: 3),
              Container(height: 1, color: dividerColor),
              const SizedBox(height: 3),
              Expanded(
                child: hasEvents
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            widget.events.first.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              height: 1.15,
                              fontWeight: FontWeight.w600,
                              color: widget.isSelected ? Colors.white70 : RsuColors.gold,
                            ),
                          ),
                          if (widget.events.length > 1)
                            Text(
                              '+${widget.events.length - 1} more',
                              style: TextStyle(
                                fontSize: 8.5,
                                color: widget.isSelected ? Colors.white54 : numberColor.withOpacity(0.55),
                              ),
                            ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}