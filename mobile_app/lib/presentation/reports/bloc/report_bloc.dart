import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/upload_report_usecase.dart';
import 'report_event.dart';
import 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final UploadReportUseCase uploadReport;

  ReportBloc({required this.uploadReport}) : super(ReportInitial()) {
    on<UploadReportEvent>((event, emit) async {
      emit(ReportLoading());
      try {
        final result = await uploadReport(
          fileBytes: event.fileBytes,
          fileName: event.fileName,
          mimeType: event.mimeType,
          reportType: event.reportType,
        );
        emit(ReportUploaded(result));
      } catch (e) {
        emit(ReportError(e.toString()));
      }
    });
  }
}
