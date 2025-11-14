import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'task_form_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ParseObject> tasks = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  // ------------------------
  // LOAD TASKS
  // ------------------------
  Future<void> loadTasks() async {
    setState(() => loading = true);

    final user = await ParseUser.currentUser();
    final query = QueryBuilder<ParseObject>(ParseObject('Task'))
      ..whereEqualTo('user', user)
      ..orderByDescending('createdAt');

    final response = await query.query();

    setState(() {
      loading = false;
      tasks = response.success && response.result != null
          ? List<ParseObject>.from(response.result)
          : [];
    });
  }

  // ------------------------
  // DELETE TASK
  // ------------------------
  Future<void> deleteTask(ParseObject task) async {
    final response = await task.delete();

    if (response.success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Task deleted")));
      loadTasks();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to delete task")));
    }
  }

  // ------------------------
  // LOGOUT
  // ------------------------
  Future<void> logout() async {
    final user = await ParseUser.currentUser();
    await user?.logout();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Logged out successfully")));

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  // ------------------------
  // CONFIRM DELETE
  // ------------------------
  void confirmDelete(ParseObject task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Delete Task',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              deleteTask(task);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ------------------------
  // UI
  // ------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        centerTitle: true,
        title: const Text(
          "My Tasks",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: logout),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Add Task"),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TaskFormScreen()),
          );
          loadTasks();
        },
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? const Center(
                  child: Text(
                    "No tasks yet.\nTap + to add one.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadTasks,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final title = task.get<String>('title') ?? '';
                      final desc = task.get<String>('description') ?? '';
                      final isDone = task.get<bool>('isDone') ?? false;

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),

                          // ✔ CHECKBOX WITH SNACKBAR FEEDBACK
                          leading: Checkbox(
                            value: isDone,
                            onChanged: (value) async {
                              task.set('isDone', value);
                              await task.save();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    value == true
                                        ? "Task marked as completed"
                                        : "Task marked as incomplete",
                                  ),
                                ),
                              );

                              setState(() {});
                            },
                          ),

                          title: Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              decoration:
                                  isDone ? TextDecoration.lineThrough : null,
                              color: isDone ? Colors.grey : Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            desc,
                            style: TextStyle(
                              fontSize: 14,
                              decoration:
                                  isDone ? TextDecoration.lineThrough : null,
                              color: isDone
                                  ? Colors.grey.shade600
                                  : Colors.black87,
                            ),
                          ),

                          // EDIT
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => TaskFormScreen(task: task)),
                            );
                            loadTasks();
                          },

                          // DELETE
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => confirmDelete(task),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
