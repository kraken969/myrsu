import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

/// Tappable circular avatar with a small camera badge. Works the same
/// way on every platform Flutter supports: tapping opens that device's
/// own native file picker — Photos/gallery on Android & iOS, Finder on
/// macOS, File Explorer on Windows, a file dialog on Linux, the
/// browser's file chooser on web — filtered to image files. The chosen
/// image is uploaded to Firebase Storage and the resulting URL is
/// saved onto the student's profile, so the avatar updates everywhere
/// it's shown (app bar, drawer, profile tab) via the existing
/// `watchUser` stream.
///
/// On web/desktop, hovering shows a pointer cursor and a gentle scale +
/// shadow lift so it visibly reads as interactive.
class ProfilePhotoPicker extends StatefulWidget {
  final String? photoUrl;
  final String name;
  final double radius;

  const ProfilePhotoPicker({
    super.key,
    required this.photoUrl,
    required this.name,
    this.radius = 40,
  });

  @override
  State<ProfilePhotoPicker> createState() => _ProfilePhotoPickerState();
}

class _ProfilePhotoPickerState extends State<ProfilePhotoPicker> {
  static const _maxBytes = 5 * 1024 * 1024; // 5 MB
  bool _uploading = false;
  bool _hovering = false;

  Future<void> _pickAndUpload() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, // guarantees in-memory bytes on every platform, including web
        allowMultiple: false,
      );
    } catch (e) {
      _showError('Could not open the file picker: $e');
      return;
    }
    if (result == null || result.files.isEmpty) return; // user cancelled

    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes == null) {
      _showError('Could not read that file. Please try a different image.');
      return;
    }
    if (bytes.lengthInBytes > _maxBytes) {
      _showError('Please choose an image under 5 MB.');
      return;
    }

    setState(() => _uploading = true);
    try {
      final uid = AuthService.instance.currentUser!.uid;
      final contentType = _guessContentType(picked.extension);
      final url = await StorageService.instance.uploadProfilePhoto(uid, bytes, contentType: contentType);
      await FirestoreService.instance.updateProfile(uid, {'photoUrl': url});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated.')),
        );
      }
    } catch (e) {
      _showError('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _guessContentType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: RsuColors.danger,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?';

    return MouseRegion(
      cursor: _uploading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: _uploading ? null : _pickAndUpload,
        child: AnimatedScale(
          scale: _hovering && !_uploading ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: _hovering && !_uploading
                  ? [BoxShadow(color: RsuColors.gold.withValues(alpha: 0.45), blurRadius: 16, spreadRadius: 2)]
                  : [],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: widget.radius,
                  backgroundColor: RsuColors.gold,
                  backgroundImage: widget.photoUrl != null ? NetworkImage(widget.photoUrl!) : null,
                  child: widget.photoUrl == null
                      ? Text(
                          initial,
                          style: TextStyle(fontSize: widget.radius * 0.7, color: RsuColors.navy, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                if (_uploading)
                  Positioned.fill(
                    child: CircleAvatar(
                      radius: widget.radius,
                      backgroundColor: Colors.black.withValues(alpha: 0.45),
                      child: const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    ),
                  ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: AnimatedScale(
                    scale: _hovering && !_uploading ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _hovering ? RsuColors.teal : RsuColors.navy,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}