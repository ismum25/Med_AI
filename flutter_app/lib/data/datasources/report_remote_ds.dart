import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/dio_client.dart';

abstract class ReportRemoteDataSource {
  Future<Map<String, dynamic>> uploadReport({
    required List<int> fileBytes,
    required String fileName,
    required String mimeType,
    String? reportType,
    String? title,
  });
  Future<List<Map<String, dynamic>>> getReports();
  Future<Map<String, dynamic>> getReport(String id);
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final DioClient client;
  ReportRemoteDataSourceImpl(this.client);

  @override
  Future<Map<String, dynamic>> uploadReport({
    required List<int> fileBytes,
    required String fileName,
    required String mimeType,
    String? reportType,
    String? title,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
        contentType: DioMediaType.parse(mimeType),
      ),
      if (reportType != null) 'report_type': reportType,
      if (title != null) 'title': title,
    });
    final response = await client.dio.post(ApiEndpoints.reports, data: formData);
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<List<Map<String, dynamic>>> getReports() async {
    final response = await client.dio.get(ApiEndpoints.reports);
    return List<Map<String, dynamic>>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> getReport(String id) async {
    final response = await client.dio.get(ApiEndpoints.reportById(id));
    return Map<String, dynamic>.from(response.data);
  }
}
