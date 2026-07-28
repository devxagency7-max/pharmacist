import '../../domain/entities/branch_entity.dart';

abstract class BranchesState {}

class BranchesInitial extends BranchesState {}

class BranchesLoading extends BranchesState {}

class BranchesLoaded extends BranchesState {
  final List<BranchEntity> branches;
  BranchesLoaded(this.branches);
}

class BranchesGovernoratesLoaded extends BranchesState {
  final List<String> governorates;
  BranchesGovernoratesLoaded(this.governorates);
}

class PharmacyProfileUpdated extends BranchesState {
  final PharmacyEntity pharmacy;
  PharmacyProfileUpdated(this.pharmacy);
}

class BranchesActionSuccess extends BranchesState {
  final String message;
  BranchesActionSuccess(this.message);
}

class BranchesError extends BranchesState {
  final String message;
  BranchesError(this.message);
}
