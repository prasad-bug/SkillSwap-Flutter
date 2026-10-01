import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/app_user.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _wantedCtrl;
  bool _isLoading = false;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _locationCtrl = TextEditingController();
    _wantedCtrl = TextEditingController();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await ref.read(userRepositoryProvider).getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _user = user;
        _nameCtrl.text = user.name;
        _bioCtrl.text = user.bio;
        _locationCtrl.text = user.location;
        _wantedCtrl.text = user.wantedSkills.join(', ');
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _user == null) return;
    setState(() => _isLoading = true);
    try {
      final wanted = _wantedCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final updated = _user!.copyWith(
        name: _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        wantedSkills: wanted,
      );
      await ref.read(userRepositoryProvider).updateUser(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    _wantedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spaceMD),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().length < 2) ? 'Name required' : null,
                    ),
                    const SizedBox(height: AppConstants.spaceMD),
                    TextFormField(
                      controller: _bioCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        prefixIcon: Icon(Icons.info_outline_rounded),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spaceMD),
                    TextFormField(
                      controller: _locationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spaceMD),
                    TextFormField(
                      controller: _wantedCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Skills I want to learn (comma separated)',
                        prefixIcon: Icon(Icons.school_outlined),
                        hintText: 'Flutter, Yoga, Cooking',
                      ),
                    ),
                    const SizedBox(height: AppConstants.spaceXL),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Profile'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
