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
      ..whereEqualTo('user', user)     // IMPORTANT FIX
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
      loadTasks(); // Refresh list
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Delete failed")));
    }
  }

  // ------------------------
  // LOGOUT
  // ------------------------
  Future<void> logout() async {
    final user = await ParseUser.currentUser();
    await user?.logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  // CONFIRM DELETE DIALOG
  void confirmDelete(ParseObject task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteTask(task);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Tasks"),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          )
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TaskFormScreen()),
          );
          loadTasks(); // Refresh after returning
        },
        child: const Icon(Icons.add),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? const Center(child: Text("No tasks yet. Tap + to add."))
              : RefreshIndicator(
                  onRefresh: loadTasks,
                  child: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final title = task.get<String>('title') ?? '';
                      final desc =
                          task.get<String>('description') ?? '';
                      final isDone = task.get<bool>('isDone') ?? false;

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            isDone ? Icons.check_circle : Icons.circle_outlined,
                            color: isDone ? Colors.green : Colors.grey,
                          ),
                          title: Text(title),
                          subtitle: Text(desc),

                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaskFormScreen(task: task),
                              ),
                            );
                            loadTasks(); // Refresh after editing
                          },

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
