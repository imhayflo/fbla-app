import 'package:flutter/material.dart';
import '../models/member.dart';
import '../models/fbla_section.dart';
import '../services/database_service.dart';
import '../utils/validators.dart';
import '../utils/constants.dart';

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

  String? _selectedStateCode;
  FblaSection? _selectedSection;
  List<FblaSection> _sections = [];
  bool _sectionsLoading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.member.name;
    _schoolController.text = widget.member.school;
    _chapterController.text = widget.member.chapter;
    _phoneController.text = widget.member.phone;
    _selectedStateCode = widget.member.state.isNotEmpty ? widget.member.state : null;
    if (_selectedStateCode != null) _loadSectionsForState(_selectedStateCode);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _chapterController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSectionsForState(String? stateCode) async {
    if (stateCode == null || stateCode.isEmpty) {
      setState(() {
        _sections = [];
        _selectedSection = null;
        _sectionsLoading = false;
      });
      return;
    }
    setState(() {
      _sectionsLoading = true;
      _selectedSection = null;
    });
    final list = await _dbService.getFblaSectionsForState(stateCode);
    FblaSection? preserve;
    if (widget.member.section.isNotEmpty) {
      for (final s in list) {
        if (s.id == widget.member.section) {
          preserve = s;
          break;
        }
      }
    }
    if (mounted) {
      setState(() {
        _sections = list;
        _selectedSection = preserve ?? (list.isNotEmpty ? list.first : null);
        _sectionsLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStateCode == null || _selectedStateCode!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your state')),
      );
      return;
    }
    if (_selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your section')),
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _dbService.updateMember({
        'name': _nameController.text.trim(),
        'school': _schoolController.text.trim(),
        'chapter': _chapterController.text.trim(),
        'state': _selectedStateCode,
        'section': _selectedSection!.id,
        'phone': _phoneController.text.trim(),
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
      appBar: AppBar(
        title: const Text('Update Profile'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              DropdownButtonFormField<String>(
                value: _selectedStateCode,
                decoration: InputDecoration(
                  labelText: 'State *',
                  prefixIcon: const Icon(Icons.map_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                hint: const Text('Select state'),
                items: kUsStates
                    .map((s) => DropdownMenuItem<String>(
                          value: s['code'],
                          child: Text(s['name']!),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedStateCode = value);
                  _loadSectionsForState(value);
                },
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please select your state' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<FblaSection>(
                value: _selectedSection,
                decoration: InputDecoration(
                  labelText: 'Regional Section *',
                  prefixIcon: _sectionsLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: Padding(
                            padding: EdgeInsets.all(2),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                hint: Text(_selectedStateCode == null
                    ? 'Select state first'
                    : _sectionsLoading
                        ? 'Loading...'
                        : 'Select section'),
                items: _sections
                    .map((s) => DropdownMenuItem<FblaSection>(
                          value: s,
                          child: Text(s.name),
                        ))
                    .toList(),
                onChanged: (_selectedStateCode == null || _sectionsLoading)
                    ? null
                    : (value) => setState(() => _selectedSection = value),
                validator: (v) =>
                    v == null ? 'Please select your section' : null,
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
                onPressed: _saving ? null : _save,
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
    );
  }
}
