import 'package:equatable/equatable.dart';

abstract class ReportState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {}
class ReportLoading extends ReportState {}

class ReportsLoaded extends ReportState {
  final List<Map<String, dynamic>> reports;
  ReportsLoaded(this.reports);
  @override
  List<Object?> get props => [reports];
}

class ReportUploaded extends ReportState {
  final Map<String, dynamic> result;
  ReportUploaded(this.result);
}

class ReportError extends ReportState {
  final String message;
  ReportError(this.message);
  @override
  List<Object?> get props => [message];
}
