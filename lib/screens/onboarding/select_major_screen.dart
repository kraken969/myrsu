import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/major.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

/// Shown right after sign-up (or whenever `hasCompletedOnboarding` is
/// false) so the student can pick their major and, optionally, enter
/// their student ID before landing on the dashboard.
class SelectMajorScreen extends StatefulWidget {
  const SelectMajorScreen({super.key});

  @override
  State<SelectMajorScreen> createState() => _SelectMajorScreenState();
}

class _SelectMajorScreenState extends State<SelectMajorScreen> {
  final _studentIdCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  Major? _selected;
  bool _saving = false;
  String _search = '';

  // The majors list is fetched ONCE and kept here; typing filters this
  // in-memory list instead of re-querying Firestore on every keystroke
  // (which was the cause of the "loading forever while typing" issue).
  List<Major> _allMajors = [];
  bool _loadingMajors = true;
  String? _loadError;
  late final StreamSubscription<List<Major>> _majorsSub;

  @override
  void initState() {
    super.initState();
    _majorsSub = FirestoreService.instance.watchMajors().listen(
      (majors) {
        if (!mounted) return;
        setState(() {
          _allMajors = majors;
          _loadingMajors = false;
          _loadError = null;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _loadingMajors = false;
          _loadError = '$e';
        });
      },
    );
  }

  @override
  void dispose() {
    _majorsSub.cancel();
    _studentIdCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Called when the student taps a major from the filtered list.
  /// Fills the search box with the chosen name (so it's visually clear
  /// what's selected) and collapses the keyboard.
  void _choose(Major m) {
    setState(() {
      _selected = m;
      _searchCtrl.text = m.name;
      _searchCtrl.selection = TextSelection.collapsed(offset: m.name.length);
      _search = m.name.toLowerCase();
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _save() async {
    if (_selected == null) return;
    setState(() => _saving = true);
    try {
      final uid = AuthService.instance.currentUser!.uid;
      await FirestoreService.instance.setMajor(uid, _selected!);
      if (_studentIdCtrl.text.trim().isNotEmpty) {
        await FirestoreService.instance
            .updateProfile(uid, {'studentId': _studentIdCtrl.text.trim()});
      }
      // AuthGate re-evaluates hasCompletedOnboarding and routes to home.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save your profile: $e'),
            backgroundColor: RsuColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _allMajors
        .where((m) => m.name.toLowerCase().contains(_search) || m.faculty.toLowerCase().contains(_search))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to MyRSU')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Let's set up your profile", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Choose your major so we can tailor your dashboard.', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                TextField(
                  controller: _studentIdCtrl,
                  decoration: const InputDecoration(labelText: 'Student ID (optional)', prefixIcon: Icon(Icons.badge_outlined)),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    labelText: 'Search major',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _selected != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear selection',
                            onPressed: () {
                              setState(() {
                                _selected = null;
                                _searchCtrl.clear();
                                _search = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) => setState(() {
                    _search = v.toLowerCase();
                    // Typing again after a selection means they're
                    // changing their mind — don't keep the old pick
                    // silently selected underneath new search text.
                    if (_selected != null && v != _selected!.name) {
                      _selected = null;
                    }
                  }),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 320,
                  child: _loadingMajors
                      ? const Center(child: CircularProgressIndicator())
                      : _loadError != null
                          ? Center(
                              child: Text(
                                'Could not load majors:\n$_loadError',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: RsuColors.danger),
                              ),
                            )
                          : filtered.isEmpty
                              ? const Center(child: Text('No majors match your search.'))
                              : ListView.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                                  itemBuilder: (context, i) {
                                    final m = filtered[i];
                                    final selected = _selected?.id == m.id;
                                    return Material(
                                      color: selected ? RsuColors.navy.withValues(alpha: 0.08) : Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () => _choose(m),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                    Text(m.faculty, style: Theme.of(context).textTheme.bodySmall),
                                                  ],
                                                ),
                                              ),
                                              if (selected) const Icon(Icons.check_circle, color: RsuColors.navy),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: (_selected == null || _saving) ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}