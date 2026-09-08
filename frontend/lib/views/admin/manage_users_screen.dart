import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/teacher_provider.dart';
import '../../models/user_model.dart';
import '../../constants/app_colors.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _tabController!.addListener(() {
      _fetchData();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    final role = _tabController!.index == 0 ? 'student' : 'teacher';
    Provider.of<TeacherProvider>(context, listen: false).fetchUsers(
      role: role,
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
    );
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final role = _tabController!.index == 0 ? 'student' : 'teacher';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Add New ${role == 'student' ? 'Student' : 'Teacher'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 8),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email Address')),
              const SizedBox(height: 8),
              TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty || passwordController.text.isEmpty) return;
                
                final tp = Provider.of<TeacherProvider>(dialogContext, listen: false);
                Navigator.pop(dialogContext);
                try {
                  final success = await tp.createUser(
                    nameController.text.trim(),
                    emailController.text.trim(),
                    passwordController.text,
                    role,
                  );
                  if (!mounted) return;
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Account created successfully'), backgroundColor: Colors.green),
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

  void _showEditUserDialog(UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    String status = user.status;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext2, setModalState) {
            return AlertDialog(
              title: const Text('Edit Account details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                  const SizedBox(height: 8),
                  TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email Address')),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => status = val);
                      }
                    },
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext2), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final tp = Provider.of<TeacherProvider>(dialogContext2, listen: false);
                    Navigator.pop(dialogContext2);
                    try {
                      final success = await tp.updateUser(user.id, nameController.text.trim(), emailController.text.trim(), status, user.role);
                      if (!mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Details saved'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                      );
                    }
                  },
                  child: const Text('Save'),
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
        title: const Text('Manage Accounts'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Students'),
            Tab(text: 'Teachers'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search account...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => _fetchData(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showAddUserDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add'),
                )
              ],
            ),
          ),

          // User listings grid
          Expanded(
            child: tp.isLoading
                ? const Center(child: CircularProgressIndicator())
                : tp.users.isEmpty
                    ? const Center(child: Text('No accounts found.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: tp.users.length,
                        itemBuilder: (context, index) {
                          final user = tp.users[index];
                          final isActive = user.status == 'active';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Text(user.name.substring(0, 1).toUpperCase()),
                              ),
                              title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(user.email),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isActive ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      user.status.toUpperCase(),
                                      style: TextStyle(
                                        color: isActive ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                    onPressed: () => _showEditUserDialog(user),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () async {
                                      try {
                                        final success = await tp.deleteUser(user.id, role: user.role);
                                        if (!context.mounted) return;
                                        if (success) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Account deleted'), backgroundColor: Colors.green),
                                          );
                                        }
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                                        );
                                      }
                                    },
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
