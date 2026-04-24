import '../../domain/repositories/report_repository.dart';
import '../datasources/report_remote_ds.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource remoteDataSource;
  ReportRepositoryImpl(this.remoteDataSource);

  @override
  Future<Map<String, dynamic>> uploadReport({
    required List<int> fileBytes,
    required String fileName,
    required String mimeType,
    String? reportType,
    String? title,
  }) =>
      remoteDataSource.uploadReport(
        fileBytes: fileBytes,
        fileName: fileName,
        mimeType: mimeType,
        reportType: reportType,
        title: title,
      );

  @override
  Future<List<Map<String, dynamic>>> getReports() => remoteDataSource.getReports();

  @override
  Future<Map<String, dynamic>> getReport(String id) => remoteDataSource.getReport(id);

  @override
  Future<Map<String, dynamic>> updateReport(String id, {String? title}) =>
      remoteDataSource.updateReport(id, title: title);
}
