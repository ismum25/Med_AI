import 'package:equatable/equatable.dart';

abstract class ReportEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadReports extends ReportEvent {}

class UploadReportEvent extends ReportEvent {
  final List<int> fileBytes;
  final String fileName;
  final String mimeType;
  final String? reportType;
  UploadReportEvent({
    required this.fileBytes,
    required this.fileName,
    required this.mimeType,
    this.reportType,
  });
}
