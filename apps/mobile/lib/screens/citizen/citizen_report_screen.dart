import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import '../../services/api_service.dart';

/// Screen M-14: Citizen Report Screen
class CitizenReportScreen extends StatefulWidget {
  const CitizenReportScreen({super.key});

  @override
  State<CitizenReportScreen> createState() => _CitizenReportScreenState();
}

class _CitizenReportScreenState extends State<CitizenReportScreen> {
  File? _imageFile;
  String _problemType = 'mrp';
  String _locationText = 'Sadar Bazaar, Delhi';
  double _latitude = 28.6562;
  double _longitude = 77.2167;
  final _descriptionCtrl = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _isSubmitting = false;
  String? _trackingId;
  String? _errorMessage;

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick photo: $e')),
      );
    }
  }

  void _showImageSourceModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLocationDialog() {
    final locCtrl = TextEditingController(text: _locationText);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Location'),
        content: TextField(
          controller: locCtrl,
          decoration: const InputDecoration(
            labelText: 'Market / Location',
            hintText: 'e.g. Connaught Place, New Delhi',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _locationText = locCtrl.text.trim();
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture or attach a photo of the product label')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.submitCitizenReport(
        image: _imageFile!,
        problemType: _problemType,
        description: _descriptionCtrl.text.trim().isNotEmpty 
          ? '${_descriptionCtrl.text.trim()} (Location: $_locationText)' 
          : 'Location: $_locationText',
        latitude: _latitude,
        longitude: _longitude,
      );

      setState(() {
        _trackingId = res['tracking_id'];
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSubmitting = false;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _imageFile = null;
      _problemType = 'mrp';
      _descriptionCtrl.clear();
      _trackingId = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LabelLensColors.surface1,
      appBar: AppBar(
        backgroundColor: LabelLensColors.brandPrimary,
        foregroundColor: Colors.white,
        title: const Text('Report Violation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LabelLensSpacing.s4),
        child: _trackingId != null ? _buildSuccessView() : _buildFormView(),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LabelLensSpacing.s6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LabelLensColors.statusPassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: LabelLensColors.statusPass),
          const SizedBox(height: 16),
          const Text(
            'Report Submitted Successfully',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: LabelLensColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Thank you for reporting. Your tracking reference is:',
            style: TextStyle(fontSize: 13, color: LabelLensColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: LabelLensColors.surface2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: LabelLensColors.surface3),
            ),
            child: SelectableText(
              _trackingId!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: LabelLensColors.brandPrimary),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _resetForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: LabelLensColors.brandPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Submit Another Report', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(LabelLensSpacing.s6),
          decoration: BoxDecoration(
            color: LabelLensColors.surface0,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: LabelLensColors.statusFailBorder),
          ),
          child: const Column(
            children: [
              Icon(Icons.warning_amber_rounded, size: 48, color: LabelLensColors.statusFail),
              SizedBox(height: 12),
              Text('Help us enforce LMPC rules.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text('Your identity remains confidential.',
                  style: TextStyle(fontSize: 13, color: LabelLensColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: LabelLensSpacing.s6),

        // Photo Upload
        const Text('1. Photo of Product Label', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showImageSourceModal,
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: LabelLensColors.surface2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: LabelLensColors.surface3, style: BorderStyle.solid),
            ),
            child: _imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: LabelLensColors.textTertiary, size: 32),
                      SizedBox(height: 8),
                      Text('Tap to take photo or choose from gallery', 
                        style: TextStyle(color: LabelLensColors.textTertiary, fontSize: 13)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: LabelLensSpacing.s6),

        // Violation Type Dropdown
        const Text('2. What is wrong?', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: LabelLensColors.surface0,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: LabelLensColors.surface3),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _problemType,
              items: const [
                DropdownMenuItem(value: 'mrp', child: Text('MRP missing or tampered')),
                DropdownMenuItem(value: 'qty', child: Text('Net quantity missing')),
                DropdownMenuItem(value: 'contact', child: Text('No consumer care details')),
                DropdownMenuItem(value: 'other', child: Text('Other LMPC violation')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _problemType = v);
              },
            ),
          ),
        ),
        const SizedBox(height: LabelLensSpacing.s6),

        // Optional Description
        const Text('3. Details (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Describe where and how the violation occurred...',
            hintStyle: const TextStyle(fontSize: 13, color: LabelLensColors.textTertiary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: LabelLensColors.surface3)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: LabelLensColors.surface3)),
          ),
        ),
        const SizedBox(height: LabelLensSpacing.s6),

        // Location Row
        const Text('4. Location', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: LabelLensColors.surface3),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: LabelLensColors.brandSecondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_locationText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              TextButton(
                onPressed: _showEditLocationDialog,
                child: const Text('Edit'),
              ),
            ],
          ),
        ),
        const SizedBox(height: LabelLensSpacing.s6),

        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: LabelLensColors.statusFail.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: LabelLensColors.statusFail.withOpacity(0.3)),
            ),
            child: Text(_errorMessage!, style: const TextStyle(color: LabelLensColors.statusFail, fontSize: 13)),
          ),
        ],

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: LabelLensColors.brandPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSubmitting
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
