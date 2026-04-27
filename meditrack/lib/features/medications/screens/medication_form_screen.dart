import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../data/local/app_database.dart';
import '../../../data/remote/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';

class MedicationFormScreen extends StatefulWidget {
  final Medication? medication;

  const MedicationFormScreen({super.key, this.medication});

  @override
  State<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends State<MedicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _notesController;
  late String _selectedUnit;
  File? _imageFile;
  String? _photoUrl;
  bool _isLoading = false;

  static const _units = ['mg', 'g', 'ml', 'tablet(s)', 'capsule(s)', 'drop(s)'];

  bool get _isEditing => widget.medication != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medication?.name ?? '');
    _dosageController = TextEditingController(text: widget.medication?.dosage ?? '');
    _notesController = TextEditingController(text: widget.medication?.notes ?? '');
    _selectedUnit = widget.medication?.unit ?? _units.first;
    _photoUrl = widget.medication?.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (picked == null) return;
    setState(() => _imageFile = File(picked.path));
  }

  Future<String> _savePhotoLocally(String medicationId) async {
    final dir = await getApplicationDocumentsDirectory();
    final dest = File(p.join(dir.path, 'med_photo_$medicationId.jpg'));
    await _imageFile!.copy(dest.path);
    return dest.path;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final db = context.read<AppDatabase>();
    final firestore = context.read<FirestoreService>();
    final user = context.read<AuthProvider>().currentUser!;
    final name = _nameController.text.trim();
    final dosage = _dosageController.text.trim();
    final notes = _notesController.text.trim();
    final notesValue = notes.isEmpty ? null : notes;
    final medId = _isEditing
        ? widget.medication!.id
        : '${user.uid}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      if (_imageFile != null) {
        _photoUrl = await _savePhotoLocally(medId);
      }

      if (_isEditing) {
        await db.medicationDao.updateMedication(
          MedicationsCompanion(
            id: Value(medId),
            name: Value(name),
            dosage: Value(dosage),
            unit: Value(_selectedUnit),
            photoUrl: Value(_photoUrl),
            notes: Value(notesValue),
          ),
        );
        await firestore.saveMedication(
          user.uid,
          Medication(
            id: medId,
            userId: widget.medication!.userId,
            name: name,
            dosage: dosage,
            unit: _selectedUnit,
            photoUrl: null,
            notes: notesValue,
            isActive: true,
          ),
        );
      } else {
        await db.medicationDao.insertMedication(
          MedicationsCompanion(
            id: Value(medId),
            userId: Value(user.uid),
            name: Value(name),
            dosage: Value(dosage),
            unit: Value(_selectedUnit),
            photoUrl: Value(_photoUrl),
            notes: Value(notesValue),
          ),
        );
        await firestore.saveMedication(
          user.uid,
          Medication(
            id: medId,
            userId: user.uid,
            name: name,
            dosage: dosage,
            unit: _selectedUnit,
            photoUrl: null,
            notes: notesValue,
            isActive: true,
          ),
        );
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Remove ${widget.medication!.name}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    final db = context.read<AppDatabase>();
    final firestore = context.read<FirestoreService>();
    final user = context.read<AuthProvider>().currentUser!;
    try {
      await db.medicationDao.deleteMedication(widget.medication!.id);
      await firestore.deactivateMedication(user.uid, widget.medication!.id);
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = _imageFile != null || _photoUrl != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Medication' : 'Add Medication'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _isLoading ? null : _delete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _isLoading ? null : _showImageSourceSheet,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: hasPhoto
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                _imageFile ?? File(_photoUrl!),
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.black54,
                                  child: const Icon(Icons.edit,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined,
                                  size: 48,
                                  color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to add photo',
                                style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Medication Name',
                  prefixIcon: Icon(Icons.medication_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _dosageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Dosage',
                        prefixIcon: Icon(Icons.scale_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: _units
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedUnit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEditing ? 'Save Changes' : 'Add Medication'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
