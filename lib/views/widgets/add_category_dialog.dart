import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/expense_controller.dart';
import 'icon_mapper.dart';

class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final nameController = TextEditingController();
  final controller = Get.find<ExpenseController>();

  String selectedIconName = 'home';
  Color selectedColor = Colors.blue;

  final List<Color> colorPalette = [
    Colors.red, Colors.blue, Colors.green, Colors.amber,
    Colors.orange, Colors.purple, Colors.pink, Colors.teal,
    Colors.indigo, Colors.cyan, Colors.brown, Colors.blueGrey,
  ];

  @override
  Widget build(BuildContext context) {
    final customIcons = getAvailableCustomIcons();
    return AlertDialog(
      title: const Text('Add Custom Category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Choose Icon', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: customIcons.map((item) {
                final isSelected = selectedIconName == item['name'];
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedIconName = item['name'];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? selectedColor.withOpacity(0.2) : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? selectedColor : Colors.grey.shade400,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item['icon'], color: isSelected ? selectedColor : Colors.grey.shade700),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Choose Accent Color', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: colorPalette.map((color) {
                final isSelected = selectedColor == color;
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedColor = color;
                    });
                  },
                  child: CircleAvatar(
                    backgroundColor: color,
                    radius: 16,
                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = nameController.text.trim();
            if (name.isNotEmpty) {
              controller.addCategory(name, selectedIconName, selectedColor);              Navigator.pop(context);
            } else {
              Get.snackbar('Error', 'Category name cannot be empty.');
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}