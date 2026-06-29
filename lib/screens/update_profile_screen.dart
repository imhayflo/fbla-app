import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/member.dart';
import '../services/database_service.dart';
import '../utils/validators.dart';
import '../widgets/fbla_app_bar.dart';
import '../widgets/fbla_screen_shell.dart';

class UpdateProfileScreen extends StatefulWidget {
  final Member member;

  const UpdateProfileScreen({super.key, required this.member});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _chapterController = TextEditingController();
  final _phoneController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _saving = false;
  bool _uploadingPhoto = false;
  String? _error;
  late String _photoUrl;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.member.name;
    _schoolController.text = widget.member.school;
    _chapterController.text = widget.member.chapter;
    _phoneController.text = widget.member.phone;
    _photoUrl = widget.member.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _chapterController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 86,
      );
      if (image == null) return;
      setState(() {
        _uploadingPhoto = true;
        _error = null;
      });
      final url = await _dbService.uploadProfilePhoto(image);
      await _dbService.updateMember({'photoUrl': url});
      if (!mounted) return;
      setState(() => _photoUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo uploaded')),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _dbService.updateMember({
        'name': _nameController.text.trim(),
        'school': _schoolController.text.trim(),
        'chapter': _chapterController.text.trim(),
        'phone': _phoneController.text.trim(),
        'photoUrl': _photoUrl,
      });
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: FblaAppBar.standard(context, title: 'Update Profile'),
      body: FblaScreenShell(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: _ProfilePhotoPicker(
                    photoUrl: _photoUrl,
                    initials: widget.member.initials,
                    uploading: _uploadingPhoto,
                    onTap: _uploadingPhoto ? null : _pickProfilePhoto,
                  ),
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: const Icon(Icons.person_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => validateRequiredName(v, fieldName: 'your name'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _schoolController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'School *',
                    prefixIcon: const Icon(Icons.school_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => validateRequired(v, 'your school'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _chapterController,
                  decoration: InputDecoration(
                    labelText: 'Chapter ID/Name *',
                    prefixIcon: const Icon(Icons.group_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => validateRequired(v, 'your chapter'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone (Optional)',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: validatePhoneOptional,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: (_saving || _uploadingPhoto) ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfilePhotoPicker extends StatelessWidget {
  final String photoUrl;
  final String initials;
  final bool uploading;
  final VoidCallback? onTap;

  const _ProfilePhotoPicker({
    required this.photoUrl,
    required this.initials,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = photoUrl.isNotEmpty;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(56),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 54,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                child: hasPhoto
                    ? null
                    : Text(
                        initials,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.surface, width: 3),
                  ),
                  child: uploading
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_a_photo_outlined, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(uploading ? 'Uploading photo...' : 'Choose profile photo'),
        ),
      ],
    );
  }
}
