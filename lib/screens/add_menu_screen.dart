import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/menu_item.dart';
import '../config/app_config.dart';
import '../widgets/animations.dart';

class AddMenuScreen extends StatefulWidget {
  final MenuItem? existingItem; // null = mode tambah, ada isi = mode edit

  const AddMenuScreen({super.key, this.existingItem});

  @override
  State<AddMenuScreen> createState() => _AddMenuScreenState();
}

class _AddMenuScreenState extends State<AddMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late String _selectedCategory;

  final List<String> _categories = ['Makanan', 'Minuman', 'Snack'];

  final Map<String, IconData> _categoryIcons = {
    'Makanan': Icons.lunch_dining,
    'Minuman': Icons.local_cafe,
    'Snack': Icons.cookie,
  };

  final Map<String, Color> _categoryColors = {
    'Makanan': const Color(0xFFE57373),
    'Minuman': const Color(0xFF64B5F6),
    'Snack': const Color(0xFFFFD54F),
  };

  bool get _isEditMode => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingItem?.name ?? '',
    );
    _priceController = TextEditingController(
      text: widget.existingItem != null
          ? widget.existingItem!.price.toStringAsFixed(0)
          : '',
    );
    _selectedCategory = widget.existingItem?.category ?? 'Makanan';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveMenu() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isEditMode) {
      final updatedItem = MenuItem(
        id: widget.existingItem!.id,
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        category: _selectedCategory,
      );
      await DatabaseHelper.instance.updateMenuItem(updatedItem);
    } else {
      final newItem = MenuItem(
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        category: _selectedCategory,
      );
      await DatabaseHelper.instance.insertMenuItem(newItem);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Hapus Menu'),
          ],
        ),
        content: Text(
          'Yakin hapus "${widget.existingItem!.name}"?\nTindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await DatabaseHelper.instance.deleteMenuItem(widget.existingItem!.id!);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColors[_selectedCategory] ?? AppConfig.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Menu' : 'Tambah Menu'),
        actions: _isEditMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _confirmDelete,
                  tooltip: 'Hapus menu',
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview card
              ScaleIn(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 140,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              _categoryIcons[_selectedCategory],
                              key: ValueKey(_selectedCategory),
                              size: 40,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _nameController.text.isEmpty
                              ? 'Nama Menu'
                              : _nameController.text,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _nameController.text.isEmpty
                                ? Colors.grey[400]
                                : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Nama menu
              FadeInUp(
                delayMs: 150,
                child: const Text(
                  'Nama Menu',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConfig.secondaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeInUp(
                delayMs: 200,
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Nasi Goreng Spesial',
                    prefixIcon: Icon(Icons.restaurant_menu_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama menu wajib diisi';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Harga
              FadeInUp(
                delayMs: 250,
                child: const Text(
                  'Harga',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConfig.secondaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeInUp(
                delayMs: 300,
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: 25000',
                    prefixIcon: Icon(Icons.attach_money_outlined),
                    prefixText: 'Rp ',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Harga wajib diisi';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Harga harus berupa angka';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Harga harus lebih dari 0';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Kategori
              FadeInUp(
                delayMs: 350,
                child: const Text(
                  'Kategori',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConfig.secondaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeInUp(
                delayMs: 400,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      final catColor =
                          _categoryColors[cat] ?? AppConfig.primaryColor;

                      return Expanded(
                        child: AnimatedPress(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? catColor
                                  : catColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? catColor : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: Icon(
                                    _categoryIcons[cat],
                                    key: ValueKey('$cat-$isSelected'),
                                    size: 28,
                                    color: isSelected ? Colors.white : catColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isSelected ? Colors.white : catColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Tombol simpan
              FadeInUp(
                delayMs: 500,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _saveMenu,
                  icon: Icon(_isEditMode ? Icons.save_outlined : Icons.add),
                  label: Text(
                    _isEditMode ? 'Update Menu' : 'Simpan Menu',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Tombol hapus (mode edit)
              if (_isEditMode) ...[
                const SizedBox(height: 12),
                FadeInUp(
                  delayMs: 550,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text(
                      'Hapus Menu',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
