// add_edit_product_screen.dart

import 'dart:io';                          // ADD THIS
import 'package:image_picker/image_picker.dart';  // ADD THIS
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/db_service.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product;
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
  final _picker = ImagePicker();        // ADD THIS — image picker instance
  bool _isSaving = false;
  File? _pickedImageFile;              // ADD THIS — stores picked image file

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

  // ─── NEW METHOD: Pick image from gallery or camera ───
  Future<void> _pickImage(ImageSource source) async {
    // ImageSource.gallery → phone gallery
    // ImageSource.camera  → take new photo
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,   // compress to 80% quality (saves storage)
      maxWidth: 800,       // resize to max 800px wide
    );

    if (picked != null) {
      setState(() {
        _pickedImageFile = File(picked.path); // save the file
        _imageUrlCtrl.text = picked.path;     // save path as URL
      });
    }
  }

  // ─── NEW METHOD: Show bottom sheet to choose Gallery or Camera ───
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Image Source',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Gallery option
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF0F3460),
                child: Icon(Icons.photo_library, color: Colors.white),
              ),
              title: const Text('Choose from Gallery',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Pick an existing photo',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () {
                Navigator.pop(context); // close bottom sheet
                _pickImage(ImageSource.gallery);
              },
            ),

            // Camera option
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF0F3460),
                child: Icon(Icons.camera_alt, color: Colors.white),
              ),
              title: const Text('Take a Photo',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Use your camera',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),

            // URL option
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF0F3460),
                child: Icon(Icons.link, color: Colors.white),
              ),
              title: const Text('Enter Image URL',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Paste a link from internet',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () => Navigator.pop(context),
              // just closes sheet, user types in URL field below
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
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
      if (mounted) Navigator.pop(context, true);
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

              // ─── IMAGE PREVIEW + PICKER BUTTON ───
              GestureDetector(
                onTap: _showImageSourceDialog, // tap anywhere on image to change it
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white24,
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildImagePreview(),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap image to change',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // ─── FORM FIELDS ───
              _buildField('Product Title', _titleCtrl, Icons.title,
                  validator: (v) => v!.isEmpty ? 'Title is required' : null),
              const SizedBox(height: 14),

              _buildField('Description', _descCtrl,
                  Icons.description_outlined,
                  maxLines: 3,
                  validator: (v) =>
                  v!.isEmpty ? 'Description is required' : null),
              const SizedBox(height: 14),

              _buildField('Price रु', _priceCtrl,
                  Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v!.isEmpty) return 'Price is required';
                    if (double.tryParse(v) == null) return 'Enter valid number';
                    return null;
                  }),
              const SizedBox(height: 14),

              // Image URL field (manual entry option)
              TextFormField(
                controller: _imageUrlCtrl,
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => setState(() {
                  _pickedImageFile = null; // clear picked file if URL typed
                }),
                decoration: InputDecoration(
                  labelText: 'Image URL (or pick above)',
                  labelStyle: const TextStyle(color: Colors.white54),
                  prefixIcon:
                  const Icon(Icons.image_outlined, color: Colors.white38),
                  // Camera button inside the URL field
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_photo_alternate_outlined,
                        color: Colors.blueAccent),
                    onPressed: _showImageSourceDialog,
                    tooltip: 'Pick image',
                  ),
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
                ),
                validator: (v) =>
                v!.isEmpty ? 'Image is required' : null,
              ),
              const SizedBox(height: 14),

              _buildField('Category', _categoryCtrl, Icons.category_outlined,
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
                  label:
                  Text(_isEditing ? 'Update Product' : 'Add Product'),
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

  // ─── BUILD IMAGE PREVIEW ───
  Widget _buildImagePreview() {
    // Priority 1: show picked file from gallery/camera
    if (_pickedImageFile != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_pickedImageFile!, fit: BoxFit.cover),
          // small edit icon overlay
          Positioned(
            bottom: 8, right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 16),
            ),
          ),
        ],
      );
    }

    // Priority 2: show network image from URL field
    if (_imageUrlCtrl.text.isNotEmpty &&
        _imageUrlCtrl.text.startsWith('http')) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _imageUrlCtrl.text,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _emptyImagePlaceholder(),
          ),
          Positioned(
            bottom: 8, right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 16),
            ),
          ),
        ],
      );
    }

    // Priority 3: nothing selected yet
    return _emptyImagePlaceholder();
  }

  // Placeholder when no image is selected
  Widget _emptyImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined,
            size: 52, color: Colors.white24),
        const SizedBox(height: 10),
        const Text('Tap to add image',
            style: TextStyle(color: Colors.white38, fontSize: 13)),
        const SizedBox(height: 4),
        const Text('Gallery • Camera • URL',
            style: TextStyle(color: Colors.white24, fontSize: 11)),
      ],
    );
  }

  Widget _buildField(
      String label,
      TextEditingController ctrl,
      IconData icon, {
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
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
          borderSide: const BorderSide(color: Color(0xFF0F3460), width: 2),
        ),
        errorStyle: const TextStyle(color: Colors.orangeAccent),
      ),
      validator: validator,
    );
  }
}