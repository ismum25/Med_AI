import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/underline_text_field.dart';
import '../../../injection_container.dart';
import '../bloc/report_bloc.dart';
import '../bloc/report_event.dart';
import '../bloc/report_state.dart';

class UploadReportPage extends StatefulWidget {
  const UploadReportPage({super.key});
  @override
  State<UploadReportPage> createState() => _UploadReportPageState();
}

class _UploadReportPageState extends State<UploadReportPage> {
  XFile? _selectedFile;
  String _reportType = 'blood_test';
  final _picker = ImagePicker();
  final _titleCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file != null) setState(() => _selectedFile = file);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReportBloc>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Upload Report')),
        body: BlocConsumer<ReportBloc, ReportState>(
          listener: (context, state) {
            if (state is ReportUploaded) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report uploaded! OCR processing started.'), backgroundColor: Colors.green),
              );
              Navigator.pop(context);
            } else if (state is ReportError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(24),
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
                        ? Center(child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 48),
                              const SizedBox(height: 8),
                              Text(_selectedFile!.name),
                            ],
                          ))
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('No file selected', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
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
                    enabled: state is! ReportLoading,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _reportType,
                    decoration: const InputDecoration(labelText: 'Report Type'),
                    items: const [
                      DropdownMenuItem(value: 'blood_test', child: Text('Blood Test')),
                      DropdownMenuItem(value: 'xray', child: Text('X-Ray')),
                      DropdownMenuItem(value: 'mri', child: Text('MRI')),
                      DropdownMenuItem(value: 'urine', child: Text('Urinalysis')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _reportType = v!),
                  ),
                  const SizedBox(height: 24),
                  if (state is ReportLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton.icon(
                      onPressed: _selectedFile == null
                          ? null
                          : () async {
                              final bytes = await _selectedFile!.readAsBytes();
                              final trimmedTitle = _titleCtrl.text.trim();
                              if (context.mounted) {
                                context.read<ReportBloc>().add(UploadReportEvent(
                                  fileBytes: bytes,
                                  fileName: _selectedFile!.name,
                                  mimeType: 'image/jpeg',
                                  reportType: _reportType,
                                  title: trimmedTitle.isEmpty ? null : trimmedTitle,
                                ));
                              }
                            },
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload Report'),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
