import '../repositories/report_repository.dart';

class UploadReportUseCase {
  final ReportRepository repository;
  UploadReportUseCase(this.repository);

  Future<Map<String, dynamic>> call({
    required List<int> fileBytes,
    required String fileName,
    required String mimeType,
    String? reportType,
    String? title,
  }) {
    return repository.uploadReport(
      fileBytes: fileBytes,
      fileName: fileName,
      mimeType: mimeType,
      reportType: reportType,
      title: title,
    );
  }
}
