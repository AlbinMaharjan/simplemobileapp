// lib/screens/add_edit_product_screen.dart

import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/db_service.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product; // null = adding new, non-null = editing

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();

  final _db = DbService();
  bool _isSaving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.product!;
      _titleCtrl.text = p.title;
      _descCtrl.text = p.description;
      _priceCtrl.text = p.price.toString();
      _imageUrlCtrl.text = p.imageUrl;
      _categoryCtrl.text = p.category;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _imageUrlCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final product = ProductModel(
      id: widget.product?.id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: double.parse(_priceCtrl.text.trim()),
      imageUrl: _imageUrlCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
    );

    try {
      if (_isEditing) {
        await _db.updateProduct(product);
      } else {
        await _db.insertProduct(product);
      }
      if (mounted) Navigator.pop(context, true); // true = refresh list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Text(
          _isEditing ? 'Edit Product' : 'Add Product',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Image preview
              if (_imageUrlCtrl.text.isNotEmpty)
                Container(
                  height: 160,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF16213E),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    _imageUrlCtrl.text,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.white30, size: 48),
                    ),
                  ),
                ),

              _buildField('Product Title', _titleCtrl, Icons.title,
                  validator: (v) =>
                      v!.isEmpty ? 'Title is required' : null),
              const SizedBox(height: 14),

              _buildField(
                'Description',
                _descCtrl,
                Icons.description_outlined,
                maxLines: 3,
                validator: (v) =>
                    v!.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 14),

              _buildField('Price (USD)', _priceCtrl,
                  Icons.attach_money_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                if (v!.isEmpty) return 'Price is required';
                if (double.tryParse(v) == null) return 'Enter valid number';
                return null;
              }),
              const SizedBox(height: 14),

              _buildField(
                'Image URL',
                _imageUrlCtrl,
                Icons.image_outlined,
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    v!.isEmpty ? 'Image URL is required' : null,
              ),
              const SizedBox(height: 14),

              _buildField('Category', _categoryCtrl,
                  Icons.category_outlined,
                  validator: (v) =>
                      v!.isEmpty ? 'Category is required' : null),
              const SizedBox(height: 28),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(_isEditing ? Icons.save : Icons.add),
                  label: Text(_isEditing ? 'Update Product' : 'Add Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3460),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF16213E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF0F3460), width: 2),
        ),
        errorStyle: const TextStyle(color: Colors.orangeAccent),
      ),
      validator: validator,
    );
  }
}
