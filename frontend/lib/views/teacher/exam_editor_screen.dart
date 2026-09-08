import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/exam_model.dart';
import '../../providers/exam_provider.dart';

class ExamEditorScreen extends StatefulWidget {
  final ExamModel? exam;

  const ExamEditorScreen({super.key, this.exam});

  @override
  State<ExamEditorScreen> createState() => _ExamEditorScreenState();
}

class _ExamEditorScreenState extends State<ExamEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _durationController = TextEditingController();
  final _totalMarksController = TextEditingController();
  final _passMarksController = TextEditingController();
  final _negFactorController = TextEditingController();

  int? _selectedSubjectId;
  DateTime _startTime = DateTime.now().add(const Duration(hours: 1));
  DateTime _endTime = DateTime.now().add(const Duration(hours: 3));

  bool _randomizeQuestions = false;
  bool _randomizeOptions = false;
  bool _antiCheatingEnabled = true;
  bool _isPublished = false;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    
    // Fill in default values if editing existing
    if (widget.exam != null) {
      final exam = widget.exam!;
      _titleController.text = exam.title;
      _descController.text = exam.description ?? '';
      _durationController.text = exam.durationMinutes.toString();
      _totalMarksController.text = exam.totalMarks.toString();
      _passMarksController.text = exam.passingMarks.toString();
      _negFactorController.text = exam.negativeMarkingFactor.toString();
      _selectedSubjectId = exam.subjectId;
      _startTime = exam.startTime;
      _endTime = exam.endTime;
      _randomizeQuestions = exam.randomizeQuestions;
      _randomizeOptions = exam.randomizeOptions;
      _antiCheatingEnabled = exam.antiCheatingEnabled;
      _isPublished = exam.isPublished;
    } else {
      _durationController.text = "60";
      _totalMarksController.text = "10.00";
      _passMarksController.text = "4.00";
      _negFactorController.text = "0.25";
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? _startTime : _endTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _startTime : _endTime),
      );

      if (pickedTime != null) {
        setState(() {
          final newDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (isStart) {
            _startTime = newDateTime;
          } else {
            _endTime = newDateTime;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ep = Provider.of<ExamProvider>(context);
    final isEditing = widget.exam != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Exam Settings' : 'Create New Exam'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Exam Title', hintText: 'Mid-term DBMS Quiz'),
                validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Instructions / Description'),
              ),
              const SizedBox(height: 16),

              // Subject Dropdown
              DropdownButtonFormField<int>(
                value: _selectedSubjectId,
                decoration: const InputDecoration(labelText: 'Subject'),
                items: ep.subjects.map((sub) {
                  return DropdownMenuItem(value: sub.id, child: Text('[${sub.code}] ${sub.name}'));
                }).toList(),
                onChanged: (val) => setState(() => _selectedSubjectId = val),
                validator: (val) => val == null ? 'Subject is required' : null,
              ),
              const SizedBox(height: 16),

              // Duration & Marks Grid
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Duration (Mins)'),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _totalMarksController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Total Marks'),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _passMarksController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Passing Marks'),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _negFactorController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Negative Factor (0.0 - 1.0)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Schedules
              const Text('Exam Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text('Start Date & Time'),
                subtitle: Text(_startTime.toString().substring(0, 16)),
                trailing: TextButton(onPressed: () => _selectDateTime(context, true), child: const Text('Select')),
              ),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text('End Date & Time'),
                subtitle: Text(_endTime.toString().substring(0, 16)),
                trailing: TextButton(onPressed: () => _selectDateTime(context, false), child: const Text('Select')),
              ),
              const SizedBox(height: 24),

              // Advanced configurations / switches
              const Text('Exam Configuration Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SwitchListTile(
                title: const Text('Randomize Questions order'),
                value: _randomizeQuestions,
                onChanged: (val) => setState(() => _randomizeQuestions = val),
              ),
              SwitchListTile(
                title: const Text('Randomize Choices order'),
                value: _randomizeOptions,
                onChanged: (val) => setState(() => _randomizeOptions = val),
              ),
              SwitchListTile(
                title: const Text('Enforce Anti-Cheating protocols'),
                value: _antiCheatingEnabled,
                onChanged: (val) => setState(() => _antiCheatingEnabled = val),
              ),
              SwitchListTile(
                title: const Text('Publish Immediately'),
                subtitle: const Text('Students can see it once published'),
                value: _isPublished,
                onChanged: (val) => setState(() => _isPublished = val),
              ),
              const SizedBox(height: 40),

              // Save button
              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _submitting
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _submitting = true);
                          final data = {
                            'title': _titleController.text.trim(),
                            'description': _descController.text.trim(),
                            'subject_id': _selectedSubjectId,
                            'duration_minutes': int.parse(_durationController.text),
                            'total_marks': double.parse(_totalMarksController.text),
                            'passing_marks': double.parse(_passMarksController.text),
                            'negative_marking_factor': double.parse(_negFactorController.text),
                            'start_time': _startTime.toIso8601String().replaceFirst('T', ' ').substring(0, 19),
                            'end_time': _endTime.toIso8601String().replaceFirst('T', ' ').substring(0, 19),
                            'randomize_questions': _randomizeQuestions ? 1 : 0,
                            'randomize_options': _randomizeOptions ? 1 : 0,
                            'anti_cheating_enabled': _antiCheatingEnabled ? 1 : 0,
                            'is_published': _isPublished ? 1 : 0,
                          };

                          try {
                            bool success;
                            if (isEditing) {
                              success = await ep.updateExam(widget.exam!.id, data);
                            } else {
                              success = await ep.createExam(data);
                            }
                            if (!context.mounted) return;
                            setState(() => _submitting = false);
                            if (success) {
                              if (context.mounted) Navigator.pop(context);
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            setState(() => _submitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                            );
                          }
                        }
                      },
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isEditing ? 'Save Configurations' : 'Launch Assessment'),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    _totalMarksController.dispose();
    _passMarksController.dispose();
    _negFactorController.dispose();
    super.dispose();
  }
}
