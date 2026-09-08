import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/exam_model.dart';
import '../../providers/teacher_provider.dart';
import '../../providers/exam_provider.dart';
import '../../services/api_service.dart';
import '../../constants/api_endpoints.dart';

class QuestionsBankScreen extends StatefulWidget {
  final ExamModel exam;

  const QuestionsBankScreen({super.key, required this.exam});

  @override
  State<QuestionsBankScreen> createState() => _QuestionsBankScreenState();
}

class _QuestionsBankScreenState extends State<QuestionsBankScreen> {
  bool _loading = true;
  List<dynamic> _questions = [];

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final res = await ApiService.get('${ApiEndpoints.teacherQuestions}?exam_id=${widget.exam.id}');
      if (res['success'] == true) {
        setState(() {
          _questions = res['questions'] as List? ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      _showSnackbar('Error loading questions: $e');
    }
  }

  Future<void> _triggerBulkUpload(TeacherProvider tp) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _loading = true);
      try {
        final path = result.files.single.path!;
        final success = await tp.uploadCSV(widget.exam.id, path);
        if (success) {
          _showSuccess('Bulk upload complete!');
          _fetchQuestions();
        } else {
          _showSnackbar('Bulk upload failed');
        }
      } catch (e) {
        setState(() => _loading = false);
        _showSnackbar('Upload error: $e');
      }
    }
  }

  void _showAddQuestionDialog() {
    final qTextController = TextEditingController();
    final opt1Controller = TextEditingController();
    final opt2Controller = TextEditingController();
    final opt3Controller = TextEditingController();
    final opt4Controller = TextEditingController();
    int correctOption = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Add MCQ Question'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: qTextController,
                      decoration: const InputDecoration(labelText: 'Question Text'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: opt1Controller,
                      decoration: const InputDecoration(labelText: 'Option A'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: opt2Controller,
                      decoration: const InputDecoration(labelText: 'Option B'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: opt3Controller,
                      decoration: const InputDecoration(labelText: 'Option C'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: opt4Controller,
                      decoration: const InputDecoration(labelText: 'Option D'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: correctOption,
                      decoration: const InputDecoration(labelText: 'Correct Choice'),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Option A')),
                        DropdownMenuItem(value: 2, child: Text('Option B')),
                        DropdownMenuItem(value: 3, child: Text('Option C')),
                        DropdownMenuItem(value: 4, child: Text('Option D')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => correctOption = val);
                        }
                      },
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (qTextController.text.trim().isEmpty) return;

                    final Map<String, dynamic> payload = {
                      'exam_id': widget.exam.id,
                      'question_text': qTextController.text.trim(),
                      'question_type': 'mcq',
                      'options': [
                        {'option_text': opt1Controller.text.trim(), 'is_correct': correctOption == 1},
                        {'option_text': opt2Controller.text.trim(), 'is_correct': correctOption == 2},
                        {'option_text': opt3Controller.text.trim(), 'is_correct': correctOption == 3},
                        {'option_text': opt4Controller.text.trim(), 'is_correct': correctOption == 4},
                      ]
                    };

                    Navigator.pop(context);
                    setState(() => _loading = true);

                    try {
                      final res = await ApiService.post(ApiEndpoints.teacherQuestions, payload);
                      if (res['success'] == true) {
                        _showSuccess('Question added');
                        _fetchQuestions();
                      }
                    } catch (e) {
                      setState(() => _loading = false);
                      _showSnackbar('Failed to add: $e');
                    }
                  },
                  child: const Text('Add'),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TeacherProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Questions Bank: ${widget.exam.title}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Bulk Upload CSV',
            onPressed: () => _triggerBulkUpload(tp),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Question',
            onPressed: _showAddQuestionDialog,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.help_outline, size: 60, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('Questions Bank is empty.', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _showAddQuestionDialog,
                        child: const Text('Add Question Manually'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => _triggerBulkUpload(tp),
                        child: const Text('Bulk Upload Questions (CSV)'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final q = _questions[index];
                    final opts = q['options'] as List? ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Question ${index + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () async {
                                    setState(() => _loading = true);
                                    try {
                                      final res = await ApiService.delete('${ApiEndpoints.teacherQuestions}?id=${q['id']}');
                                      if (res['success'] == true) {
                                        _showSuccess('Question deleted');
                                        _fetchQuestions();
                                      }
                                    } catch (e) {
                                      setState(() => _loading = false);
                                      _showSnackbar('Delete error: $e');
                                    }
                                  },
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(q['question_text'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            ...List.generate(opts.length, (optIdx) {
                              final opt = opts[optIdx];
                              final isCorrect = opt['is_correct'].toString() == '1' || opt['is_correct'] == true;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: isCorrect ? Colors.green : Colors.grey,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        opt['option_text'],
                                        style: TextStyle(
                                          fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                          color: isCorrect ? Colors.green : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            })
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }
}
