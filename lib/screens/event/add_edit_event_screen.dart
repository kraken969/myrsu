import 'package:flutter/material.dart';

import '../../models/personal_event.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AddEditEventScreen extends StatefulWidget {
  final PersonalEvent? existing;
  final DateTime? initialDate;

  const AddEditEventScreen({super.key, this.existing, this.initialDate});

  @override
  State<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _locationCtrl;

  late DateTime _date;
  bool _allDay = true;
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);
  int _colorIndex = 0;
  bool _remindDayBefore = true;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _locationCtrl = TextEditingController(text: e?.location ?? '');
    _date = e?.date ?? widget.initialDate ?? DateTime.now();
    if (e != null) {
      _allDay = e.allDay;
      _colorIndex = e.colorIndex;
      _remindDayBefore = e.remindDayBefore;
      if (e.startMinutes != null) {
        _start = TimeOfDay(hour: e.startMinutes! ~/ 60, minute: e.startMinutes! % 60);
      }
      if (e.endMinutes != null) {
        _end = TimeOfDay(hour: e.endMinutes! ~/ 60, minute: e.endMinutes! % 60);
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(context: context, initialTime: isStart ? _start : _end);
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_allDay && _toMinutes(_end) <= _toMinutes(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final uid = AuthService.instance.currentUser!.uid;
      final event = PersonalEvent(
        id: widget.existing?.id ?? '',
        title: _titleCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        date: _date,
        allDay: _allDay,
        startMinutes: _allDay ? null : _toMinutes(_start),
        endMinutes: _allDay ? null : _toMinutes(_end),
        location: _locationCtrl.text.trim(),
        colorIndex: _colorIndex,
        remindDayBefore: _remindDayBefore,
      );

      if (_isEditing) {
        await FirestoreService.instance.updatePersonalEvent(uid, event);
      } else {
        await FirestoreService.instance.addPersonalEvent(uid, event);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e'), backgroundColor: RsuColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove event?'),
        content: Text('Delete "${_titleCtrl.text}" from your calendar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: RsuColors.danger))),
        ],
      ),
    );
    if (confirm != true) return;
    final uid = AuthService.instance.currentUser!.uid;
    await FirestoreService.instance.deletePersonalEvent(uid, widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tints = isDark ? RsuColors.courseTintsDark : RsuColors.courseTints;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit event' : 'Add event'),
        actions: [
          if (_isEditing) IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.event_outlined)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.notes_outlined)),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _locationCtrl,
                    decoration: const InputDecoration(labelText: 'Location (optional)', prefixIcon: Icon(Icons.place_outlined)),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text('${_date.day}/${_date.month}/${_date.year}'),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('All day'),
                    value: _allDay,
                    onChanged: (v) => setState(() => _allDay = v),
                  ),
                  if (!_allDay) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickTime(isStart: true),
                            icon: const Icon(Icons.schedule),
                            label: Text('Start: ${_start.format(context)}'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickTime(isStart: false),
                            icon: const Icon(Icons.schedule_outlined),
                            label: Text('End: ${_end.format(context)}'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Remind me the day before'),
                    subtitle: const Text('Shows up alongside your class reminders'),
                    value: _remindDayBefore,
                    onChanged: (v) => setState(() => _remindDayBefore = v),
                  ),
                  const SizedBox(height: 12),
                  const Text('Color tag', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (int i = 0; i < tints.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => setState(() => _colorIndex = i),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: tints[i],
                              child: _colorIndex == i ? const Icon(Icons.check, size: 16, color: Colors.black54) : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isEditing ? 'Save changes' : 'Add to calendar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
