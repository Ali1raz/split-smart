import 'package:flutter/material.dart';

class EditGroupNameDialog extends StatefulWidget {
  final String initialName;
  const EditGroupNameDialog({super.key, required this.initialName});

  @override
  State<EditGroupNameDialog> createState() => _EditGroupNameDialogState();
}

class _EditGroupNameDialogState extends State<EditGroupNameDialog> {
  late TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename Group'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Group Name',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
