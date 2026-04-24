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
  final String? title;
  UploadReportEvent({
    required this.fileBytes,
    required this.fileName,
    required this.mimeType,
    this.reportType,
    this.title,
  });
}
