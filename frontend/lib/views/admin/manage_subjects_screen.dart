import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/exam_provider.dart';

class ManageSubjectsScreen extends StatefulWidget {
  const ManageSubjectsScreen({super.key});

  @override
  State<ManageSubjectsScreen> createState() => _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends State<ManageSubjectsScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ep = Provider.of<ExamProvider>(context, listen: false);
      ep.fetchCourses();
      ep.fetchSubjects();
    });
  }

  void _showAddCourseDialog(ExamProvider ep) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add New Course'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Course Name', hintText: 'Bachelor of Computer Science')),
              const SizedBox(height: 8),
              TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Course Code', hintText: 'B.Sc CS')),
              const SizedBox(height: 8),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || codeController.text.trim().isEmpty) return;
                Navigator.pop(dialogContext);
                try {
                  final success = await ep.createCourse(nameController.text.trim(), codeController.text.trim(), descController.text.trim());
                  if (!mounted) return;
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Course created successfully'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                  );
                }
              },
              child: const Text('Create'),
            )
          ],
        );
      },
    );
  }

  void _showAddSubjectDialog(ExamProvider ep) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final descController = TextEditingController();
    int? courseId = ep.courses.isNotEmpty ? ep.courses[0].id : null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext2, setModalState) {
            return AlertDialog(
              title: const Text('Add New Subject'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: courseId,
                    decoration: const InputDecoration(labelText: 'Belongs to Course'),
                    items: ep.courses.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text('[${c.code}] ${c.name}'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => courseId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Subject Name')),
                  const SizedBox(height: 8),
                  TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Subject Code')),
                  const SizedBox(height: 8),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext2), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty || codeController.text.trim().isEmpty || courseId == null) return;
                    Navigator.pop(dialogContext2);
                    try {
                      final success = await ep.createSubject(courseId!, nameController.text.trim(), codeController.text.trim(), descController.text.trim());
                      if (!mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Subject created successfully'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                      );
                    }
                  },
                  child: const Text('Create'),
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
    final ep = Provider.of<ExamProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Curriculum Manager'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Courses'),
            Tab(text: 'Subjects'),
          ],
        ),
      ),
      body: ep.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Courses Tab
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ep.courses.length,
                  itemBuilder: (context, index) {
                    final course = ep.courses[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.bookmark, color: Colors.blue),
                        title: Text(course.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Code: ${course.code} • ${course.description ?? ""}'),
                      ),
                    );
                  },
                ),

                // Subjects Tab
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ep.subjects.length,
                  itemBuilder: (context, index) {
                    final subject = ep.subjects[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.class_, color: Colors.green),
                        title: Text(subject.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Code: ${subject.code} • Course: ${subject.courseName ?? "Curriculum"}'),
                      ),
                    );
                  },
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController!.index == 0) {
            _showAddCourseDialog(ep);
          } else {
            _showAddSubjectDialog(ep);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
}
