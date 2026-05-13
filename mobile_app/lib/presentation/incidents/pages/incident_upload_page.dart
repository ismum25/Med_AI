import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/underline_text_field.dart';
import '../../../injection_container.dart';

class IncidentUploadPage extends StatefulWidget {
  const IncidentUploadPage({super.key});

  @override
  State<IncidentUploadPage> createState() => _IncidentUploadPageState();
}

class _IncidentUploadPageState extends State<IncidentUploadPage> {
  XFile? _selectedFile;
  bool _uploading = false;
  final _picker = ImagePicker();
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file != null) setState(() => _selectedFile = file);
  }

  Future<void> _submit() async {
    if (_selectedFile == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await _selectedFile!.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes,
            filename: _selectedFile!.name,
            contentType: DioMediaType.parse('image/jpeg')),
        if (_titleCtrl.text.trim().isNotEmpty) 'title': _titleCtrl.text.trim(),
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      });
      final client = sl<DioClient>();
      final response =
          await client.dio.post(ApiEndpoints.uploadIncident, data: formData);
      if (!mounted) return;
      final incident = Map<String, dynamic>.from(response.data as Map);
      final id = incident['id']?.toString();
      if (id == null) {
        throw Exception('Missing incident id in response');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Incident uploaded and analyzed'),
            backgroundColor: Colors.green),
      );
      context.go(AppRoutes.patientIncidentDetail(id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Incident')),
      body: SingleChildScrollView(
        padding: AppLayoutMetrics.scrollPadding(
          context,
          left: 24,
          top: 24,
          right: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedFile != null ? Colors.blue : Colors.grey,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _selectedFile != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 48),
                          const SizedBox(height: 8),
                          Text(_selectedFile!.name),
                        ],
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No photo selected',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploading
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploading
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            UnderlineTextField(
              controller: _titleCtrl,
              label: 'Title (optional)',
              icon: Icons.title_rounded,
              enabled: !_uploading,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            UnderlineTextField(
              controller: _notesCtrl,
              label: 'Notes (optional)',
              icon: Icons.notes_rounded,
              enabled: !_uploading,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            if (_uploading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                onPressed: _selectedFile == null ? null : _submit,
                icon: const Icon(Icons.upload),
                label: const Text('Analyze Incident'),
              ),
            const SizedBox(height: 12),
            Text(
              'Upload a clear injury photo so the AI can identify the injury type and severity.',
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
