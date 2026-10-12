abstract class InternHomeEvent {}

class InternHomeRequested extends InternHomeEvent {}

class InternTrainingHoursLogSubmitted extends InternHomeEvent {
  final DateTime date;
  final double hours;
  final String activityDescription;

  InternTrainingHoursLogSubmitted({
    required this.date,
    required this.hours,
    required this.activityDescription,
  });
}
