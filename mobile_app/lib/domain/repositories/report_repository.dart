abstract class ReportRepository {
  Future<Map<String, dynamic>> uploadReport({
    required List<int> fileBytes,
    required String fileName,
    required String mimeType,
    String? reportType,
    String? title,
  });
  Future<List<Map<String, dynamic>>> getReports();
  Future<Map<String, dynamic>> getReport(String id);
  Future<Map<String, dynamic>> updateReport(String id, {String? title});
}
