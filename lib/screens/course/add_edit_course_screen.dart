import 'package:flutter/material.dart';

import '../../models/course_entry.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AddEditCourseScreen extends StatefulWidget {
  final CourseEntry? existing;
  const AddEditCourseScreen({super.key, this.existing});

  @override
  State<AddEditCourseScreen> createState() => _AddEditCourseScreenState();
}

class _AddEditCourseScreenState extends State<AddEditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _sectionCtrl;
  late final TextEditingController _roomCtrl;
  late final TextEditingController _instructorCtrl;

  int _day = 0;
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 12, minute: 0);
  int _colorIndex = 0;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _codeCtrl = TextEditingController(text: e?.code ?? '');
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _sectionCtrl = TextEditingController(text: e?.section ?? '');
    _roomCtrl = TextEditingController(text: e?.room ?? '');
    _instructorCtrl = TextEditingController(text: e?.instructor ?? '');
    if (e != null) {
      _day = e.day;
      _start = TimeOfDay(hour: e.startMinutes ~/ 60, minute: e.startMinutes % 60);
      _end = TimeOfDay(hour: e.endMinutes ~/ 60, minute: e.endMinutes % 60);
      _colorIndex = e.colorIndex;
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _titleCtrl.dispose();
    _sectionCtrl.dispose();
    _roomCtrl.dispose();
    _instructorCtrl.dispose();
    super.dispose();
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

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
    if (_toMinutes(_end) <= _toMinutes(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    setState(() => _saving = true);
    final uid = AuthService.instance.currentUser!.uid;
    final entry = CourseEntry(
      id: widget.existing?.id ?? '',
      code: _codeCtrl.text.trim().toUpperCase(),
      title: _titleCtrl.text.trim(),
      section: _sectionCtrl.text.trim(),
      room: _roomCtrl.text.trim(),
      instructor: _instructorCtrl.text.trim(),
      day: _day,
      startMinutes: _toMinutes(_start),
      endMinutes: _toMinutes(_end),
      colorIndex: _colorIndex,
    );

    if (_isEditing) {
      await FirestoreService.instance.updateCourse(uid, entry);
    } else {
      await FirestoreService.instance.addCourse(uid, entry);
    }

    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove course?'),
        content: Text('Delete ${_codeCtrl.text} from your timetable?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: RsuColors.danger))),
        ],
      ),
    );
    if (confirm != true) return;
    final uid = AuthService.instance.currentUser!.uid;
    await FirestoreService.instance.deleteCourse(uid, widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tints = isDark ? RsuColors.courseTintsDark : RsuColors.courseTints;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit course' : 'Add course'),
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
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Course code (e.g. CSC480)', prefixIcon: Icon(Icons.tag)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Course title (optional)', prefixIcon: Icon(Icons.title)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sectionCtrl,
                          decoration: const InputDecoration(labelText: 'Section'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _roomCtrl,
                          decoration: const InputDecoration(labelText: 'Room'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _instructorCtrl,
                    decoration: const InputDecoration(labelText: 'Instructor (optional)', prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<int>(
                    initialValue: _day,
                    decoration: const InputDecoration(labelText: 'Day'),
                    items: [
                      for (int i = 0; i < 7; i++) DropdownMenuItem(value: i, child: Text(CourseEntry.dayNames[i])),
                    ],
                    onChanged: (v) => setState(() => _day = v!),
                  ),
                  const SizedBox(height: 14),
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
                  const SizedBox(height: 20),
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
                        : Text(_isEditing ? 'Save changes' : 'Add to timetable'),
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
