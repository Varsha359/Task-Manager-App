import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class TaskFormScreen extends StatefulWidget {
  final ParseObject? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();

    if (widget.task != null) {
      titleController.text = widget.task!.get<String>('title') ?? '';
      descController.text = widget.task!.get<String>('description') ?? '';
    }
  }

  // ------------------------
  // SAVE TASK (Create or Update)
  // ------------------------
  Future<void> saveTask() async {
    final title = titleController.text.trim();
    final desc = descController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Title required")));
      return;
    }

    setState(() => loading = true);

    if (widget.task == null) {
      // ------------------
      // CREATE NEW TASK
      // ------------------
      final user = await ParseUser.currentUser();

      final task = ParseObject('Task')
        ..set('title', title)
        ..set('description', desc)
        ..set('user', user)     // IMPORTANT FIX
        ..set('isDone', false); // Default value

      final response = await task.save();
      setState(() => loading = false);

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task created")),
        );
        Navigator.pop(context);
      }

    } else {
      // ------------------
      // UPDATE EXISTING TASK
      // ------------------
      final task = widget.task!
        ..set('title', title)
        ..set('description', desc);

      final response = await task.save();
      setState(() => loading = false);

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task updated")),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.task != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Task" : "New Task")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Task Title"),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 20),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: saveTask,
                    child: Text(isEdit ? "Update" : "Create"),
                  ),
          ],
        ),
      ),
    );
  }
}
