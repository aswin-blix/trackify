import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../providers/expense_provider.dart';
import '../utils/icon_helpers.dart';

class CategoryFormScreen extends StatefulWidget {
  final CategoryModel? category;

  const CategoryFormScreen({super.key, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  late TextEditingController _nameController;
  late String _selectedColor;
  late String _selectedIcon;

  bool get _isEditMode => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedColor = widget.category?.colorCode ?? IconHelpers.availableColors.first;
    _selectedIcon = widget.category?.iconCode ?? IconHelpers.availableIcons.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name.')),
      );
      return;
    }

    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final cat = CategoryModel(
      id: widget.category?.id,
      name: _nameController.text.trim(),
      colorCode: _selectedColor,
      iconCode: _selectedIcon,
    );

    if (_isEditMode) {
      await provider.updateCategory(cat);
    } else {
      await provider.addCategory(cat);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? 'Edit Category' : 'New Category',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _save,
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPreview(context),
            const SizedBox(height: 28),
            _buildNameField(context),
            const SizedBox(height: 28),
            const Text('Color', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildColorPicker(),
            const SizedBox(height: 28),
            const Text('Icon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildIconPicker(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final color = IconHelpers.parseColor(_selectedColor);
    final icon = IconHelpers.getIcon(_selectedIcon);
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color, size: 36),
          ),
          const SizedBox(height: 10),
          Text(
            _nameController.text.isNotEmpty ? _nameController.text : 'Category Name',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _nameController,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          labelText: 'Category Name',
          border: InputBorder.none,
        ),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: IconHelpers.availableColors.map((colorHex) {
        final color = IconHelpers.parseColor(colorHex);
        final isSelected = _selectedColor == colorHex;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = colorHex),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                  : null,
            ),
            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIconPicker(BuildContext context) {
    final selectionColor = IconHelpers.parseColor(_selectedColor);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: IconHelpers.availableIcons.length,
      itemBuilder: (context, index) {
        final iconCode = IconHelpers.availableIcons[index];
        final icon = IconHelpers.getIcon(iconCode);
        final isSelected = _selectedIcon == iconCode;
        return GestureDetector(
          onTap: () => setState(() => _selectedIcon = iconCode),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? selectionColor.withValues(alpha: 0.2)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: selectionColor, width: 2)
                  : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Icon(
              icon,
              color: isSelected ? selectionColor : Colors.grey,
              size: 24,
            ),
          ),
        );
      },
    );
  }
}
