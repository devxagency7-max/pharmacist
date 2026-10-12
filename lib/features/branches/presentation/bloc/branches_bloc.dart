import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacist/core/errors/error_message_mapper.dart';
import '../../domain/repositories/branches_repository.dart';
import 'branches_event.dart';
import 'branches_state.dart';

class BranchesBloc extends Bloc<BranchesEvent, BranchesState> {
  final BranchesRepository _branchesRepository;

  BranchesBloc(this._branchesRepository) : super(BranchesInitial()) {
    on<BranchesLoadList>(_onLoadList);
    on<BranchesCreateRequested>(_onCreateBranch);
    on<BranchesToggleStatusRequested>(_onToggleStatus);
    on<PharmacyUpdateProfileRequested>(_onUpdateProfile);
    on<BranchesLoadGovernorates>(_onLoadGovernorates);
  }

  Future<void> _onLoadList(
    BranchesLoadList event,
    Emitter<BranchesState> emit,
  ) async {
    emit(BranchesLoading());
    try {
      final list = await _branchesRepository.getBranches(pharmacyId: event.pharmacyId);
      emit(BranchesLoaded(list));
    } catch (e) {
      emit(BranchesError(mapErrorToMessage(e)));
    }
  }

  Future<void> _onCreateBranch(
    BranchesCreateRequested event,
    Emitter<BranchesState> emit,
  ) async {
    emit(BranchesLoading());
    try {
      await _branchesRepository.addBranch(
        pharmacyId: event.pharmacyId,
        name: event.name,
        address: event.address,
        phoneNumber: event.phoneNumber,
        isMainBranch: event.isMainBranch,
        latitude: event.latitude,
        longitude: event.longitude,
      );
      emit(BranchesActionSuccess('تم إضافة الفرع بنجاح'));
      add(BranchesLoadList(event.pharmacyId));
    } catch (e) {
      emit(BranchesError(mapErrorToMessage(e)));
    }
  }

  Future<void> _onToggleStatus(
    BranchesToggleStatusRequested event,
    Emitter<BranchesState> emit,
  ) async {
    emit(BranchesLoading());
    try {
      await _branchesRepository.setBranchStatus(
        branchId: event.branchId,
        status: event.status,
      );
      emit(BranchesActionSuccess('تم تعديل حالة الفرع بنجاح'));
      add(BranchesLoadList(event.pharmacyId));
    } catch (e) {
      emit(BranchesError(mapErrorToMessage(e)));
    }
  }

  Future<void> _onUpdateProfile(
    PharmacyUpdateProfileRequested event,
    Emitter<BranchesState> emit,
  ) async {
    emit(BranchesLoading());
    try {
      final pharmacy = await _branchesRepository.updatePharmacyProfile(
        name: event.name,
        logoUploadedFileId: event.logoUploadedFileId,
        governorate: event.governorate,
        address: event.address,
        workingHoursDescription: event.workingHoursDescription,
        isOpen: event.isOpen,
      );
      emit(PharmacyProfileUpdated(pharmacy));
    } catch (e) {
      emit(BranchesError(mapErrorToMessage(e)));
    }
  }

  Future<void> _onLoadGovernorates(
    BranchesLoadGovernorates event,
    Emitter<BranchesState> emit,
  ) async {
    try {
      final governorates = await _branchesRepository.getGovernorates();
      emit(BranchesGovernoratesLoaded(governorates));
    } catch (e) {
      emit(BranchesError(mapErrorToMessage(e)));
    }
  }
}
