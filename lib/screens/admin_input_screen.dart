// lib/screens/admin_draft_input_screen.dart
import 'package:flutter/material.dart';
import '../services/live_draft_service.dart';
import '../utils/constants.dart';

class AdminDraftInputScreen extends StatefulWidget {
  const AdminDraftInputScreen({super.key});

  @override
  _AdminDraftInputScreenState createState() => _AdminDraftInputScreenState();
}

class _AdminDraftInputScreenState extends State<AdminDraftInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickController = TextEditingController();
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _schoolController = TextEditingController();
  
  String? _selectedTeam;
  final LiveDraftService _liveDraftService = LiveDraftService();
  bool _isSubmitting = false;
  
  @override
  void dispose() {
    _pickController.dispose();
    _nameController.dispose();
    _positionController.dispose();
    _schoolController.dispose();
    super.dispose();
  }
  
  Future<void> _submitPick() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      await _liveDraftService.addPick({
        'pickNumber': int.parse(_pickController.text),
        'playerName': _nameController.text,
        'position': _positionController.text,
        'school': _schoolController.text,
        'team': _selectedTeam,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Clear fields after successful submission
      _pickController.clear();
      _nameController.clear();
      _positionController.clear();
      _schoolController.clear();
      setState(() => _selectedTeam = null);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick submitted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Live Draft Pick'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _pickController,
                decoration: const InputDecoration(
                  labelText: 'Pick Number',
                  hintText: 'e.g., 1',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a pick number';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Player Name',
                  hintText: 'e.g., Caleb Williams',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a player name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  hintText: 'e.g., QB',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a position';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _schoolController,
                decoration: const InputDecoration(
                  labelText: 'School',
                  hintText: 'e.g., USC',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a school';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedTeam,
                decoration: const InputDecoration(
                  labelText: 'Team',
                ),
                items: NFLTeams.allTeams.map((team) {
                  return DropdownMenuItem<String>(
                    value: team,
                    child: Text(team),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedTeam = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a team';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPick,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Submit Pick'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}