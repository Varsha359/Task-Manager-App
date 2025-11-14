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

  Future<void> saveTask() async {
    final title = titleController.text.trim();
    final desc = descController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Title is required")));
      return;
    }

    setState(() => loading = true);

    if (widget.task == null) {
      final user = await ParseUser.currentUser();

      final task = ParseObject('Task')
        ..set('title', title)
        ..set('description', desc)
        ..set('user', user)
        ..set('isDone', false);

      final response = await task.save();
      setState(() => loading = false);

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task created successfully")),
        );
        Navigator.pop(context);
      }
    } else {
      widget.task!
        ..set('title', title)
        ..set('description', desc);

      final response = await widget.task!.save();
      setState(() => loading = false);

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task updated successfully")),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.task != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? "Edit Task" : "New Task"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Task Title",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 25),

            loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: Text(editing ? "Update Task" : "Create Task"),
                      onPressed: saveTask,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
