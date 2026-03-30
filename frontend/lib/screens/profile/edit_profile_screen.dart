import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/auth/authenticated_session.dart';
import 'package:syntrak/core/di/service_locator.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileService _profileService = sl<ProfileService>();
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _skiLevelController = TextEditingController();
  final _homeController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _skiLevelController.dispose();
    _homeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final sessionOutcome = await ensureAuthenticatedSession(authProvider);
      if (sessionOutcome is AuthenticatedSessionError) {
        throw Exception(sessionOutcome.message);
      }

      final profile = await _profileService.getCurrentUserProfile();

      if (!mounted) {
        return;
      }

      _fullNameController.text = profile.fullName ?? '';
      _usernameController.text = profile.username ?? '';
      _bioController.text = profile.bio ?? '';
      _skiLevelController.text = profile.skiLevel ?? '';
      _homeController.text = profile.home ?? '';

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final sessionOutcome = await ensureAuthenticatedSession(authProvider);
      if (sessionOutcome is AuthenticatedSessionError) {
        throw Exception(sessionOutcome.message);
      }

      await _profileService.updateProfile(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        skiLevel: _skiLevelController.text.trim(),
        home: _homeController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(SyntrakSpacing.lg),
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(SyntrakSpacing.md),
                        decoration: BoxDecoration(
                          color: SyntrakColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(SyntrakRadius.md),
                        ),
                        child: Text(
                          _error!,
                          style: SyntrakTypography.bodyMedium.copyWith(
                            color: SyntrakColors.error,
                          ),
                        ),
                      ),
                      const SizedBox(height: SyntrakSpacing.md),
                    ],
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(labelText: 'Full name'),
                    ),
                    const SizedBox(height: SyntrakSpacing.md),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                    ),
                    const SizedBox(height: SyntrakSpacing.md),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'Bio'),
                      minLines: 3,
                      maxLines: 5,
                    ),
                    const SizedBox(height: SyntrakSpacing.md),
                    TextFormField(
                      controller: _skiLevelController,
                      decoration: const InputDecoration(labelText: 'Ski level'),
                    ),
                    const SizedBox(height: SyntrakSpacing.md),
                    TextFormField(
                      controller: _homeController,
                      decoration: const InputDecoration(labelText: 'Home mountain'),
                    ),
                    const SizedBox(height: SyntrakSpacing.lg),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}