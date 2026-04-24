import '../repositories/report_repository.dart';

class UpdateReportUseCase {
  final ReportRepository repository;
  UpdateReportUseCase(this.repository);

  Future<Map<String, dynamic>> call(String id, {String? title}) {
    return repository.updateReport(id, title: title);
  }
}
