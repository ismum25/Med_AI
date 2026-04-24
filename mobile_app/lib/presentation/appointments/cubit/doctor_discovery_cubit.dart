import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_error_message.dart';
import '../../../domain/entities/doctor.dart';
import '../../../domain/usecases/get_doctor_specializations_usecase.dart';
import '../../../domain/usecases/list_doctors_usecase.dart';

class DoctorDiscoveryState extends Equatable {
  final List<String> specializations;
  final String? selectedSpecialization;
  final List<DoctorListItemEntity> doctors;
  final bool loading;
  final String? error;

  const DoctorDiscoveryState({
    this.specializations = const [],
    this.selectedSpecialization,
    this.doctors = const [],
    this.loading = false,
    this.error,
  });

  DoctorDiscoveryState copyWith({
    List<String>? specializations,
    String? selectedSpecialization,
    bool assignSelectedSpecialization = false,
    List<DoctorListItemEntity>? doctors,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return DoctorDiscoveryState(
      specializations: specializations ?? this.specializations,
      selectedSpecialization: assignSelectedSpecialization
          ? selectedSpecialization
          : this.selectedSpecialization,
      doctors: doctors ?? this.doctors,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [specializations, selectedSpecialization, doctors, loading, error];
}

class DoctorDiscoveryCubit extends Cubit<DoctorDiscoveryState> {
  final GetDoctorSpecializationsUseCase _getSpecs;
  final ListDoctorsUseCase _listDoctors;

  DoctorDiscoveryCubit({
    required GetDoctorSpecializationsUseCase getSpecializations,
    required ListDoctorsUseCase listDoctors,
  })  : _getSpecs = getSpecializations,
        _listDoctors = listDoctors,
        super(const DoctorDiscoveryState());

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final specs = await _getSpecs();
      final docs = await _listDoctors();
      emit(state.copyWith(
        specializations: specs,
        doctors: docs,
        loading: false,
        assignSelectedSpecialization: true,
        selectedSpecialization: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: userFacingApiMessage(e),
      ));
    }
  }

  Future<void> selectSpecialization(String? spec) async {
    emit(state.copyWith(
      loading: true,
      assignSelectedSpecialization: true,
      selectedSpecialization: spec,
      clearError: true,
    ));
    try {
      final docs = await _listDoctors(
        specialization: spec == null || spec.isEmpty ? null : spec,
      );
      emit(state.copyWith(doctors: docs, loading: false));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: userFacingApiMessage(e),
      ));
    }
  }
}
