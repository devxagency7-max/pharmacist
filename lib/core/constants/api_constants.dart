class ApiConstants {
  static const String baseUrl = 'http://204.168.149.185/api/v1';

  // Well-known, fixed system user id for the AI assistant — every
  // pharmacist/patient has exactly one conversation with this participant,
  // auto-created on first use. Used to identify/filter the AI conversation
  // among a participant's regular conversations.
  static const String aiParticipantId =
      '00000000-0000-0000-0000-000000000001';

  // The one route in the entire API that omits the `/v1` segment — must be
  // requested as an absolute path, not relative to [baseUrl].
  static const String filesUpload = 'http://204.168.149.185/api/files/upload';

  // Paths below are relative to [baseUrl] — ApiClient's BaseOptions already
  // carries the base, so callers using ApiClient should pass these as-is.
  static const String syncUser = '/users/sync';
  static const String usersMe = '/users/me';
  static const String completeProfile = '/users/profile/complete';

  // Module A: Onboarding & Application
  static const String pharmacistApply = '/pharmacist/apply';
  static const String pharmacistApplicationStatus = '/pharmacist/application-status';
  static String pharmacistDocuments(String applicationId) => '/pharmacist/$applicationId/documents';
  static String pharmacistWithdraw(String applicationId) => '/pharmacist/$applicationId';

  // Module B: Orders Queue & Fulfillment
  static String ordersBranch(String branchId) => '/orders/branch/$branchId';
  static String orderRespond(String id) => '/orders/$id/respond';
  static String orderComplete(String id) => '/orders/$id/complete';
  static String orderCancel(String id) => '/orders/$id/cancel';
  static const String ordersSummary = '/orders/summary';

  // Module C: Prescriptions Review
  static const String prescriptionsPending = '/prescriptions/pending';
  static String prescriptionDetail(String id) => '/prescriptions/$id';
  static String prescriptionApprove(String id) => '/prescriptions/$id/approve';
  static String prescriptionReject(String id) => '/prescriptions/$id/reject';

  // Module D: Patient Assignment & Management
  static const String pendingPatientRequests = '/pharmacists/pending-requests';
  static String respondToPatientRequest(String assignmentId) =>
      '/pharmacists/requests/$assignmentId/respond';
  static const String myPatients = '/pharmacists/my-patients';
  static String patientDetail(String patientId) => '/pharmacists/patients/$patientId';
  static String terminatePatient(String patientId) =>
      '/pharmacists/patients/$patientId/terminate';

  // Module D2: Medication Plans (Pharmacist-authored)
  static const String createMedicationPlan = '/medications';
  static String updateMedicationPlan(String id) => '/medications/$id';
  static const String medicationPlans = '/medications';
  static String medicationPlanDetail(String id) => '/medications/$id';

  // Module E: Branches & Pharmacy Profile
  static const String updatePharmacyProfile = '/pharmacies/profile';
  static String pharmacyBranches(String pharmacyId) => '/pharmacies/$pharmacyId/branches';
  // NOTE: full path is under /pharmacies, not /branches directly — backend
  // route is `PUT /api/v1/pharmacies/branches/{id}/status`.
  static String setBranchStatus(String branchId) => '/pharmacies/branches/$branchId/status';
  static const String getGovernorates = '/pharmacies/governorates';

  // Module F: Dashboard Analytics
  // NOTE: corrected to match the actual backend routes (PharmacyDashboardController):
  // `summary` (not `metrics`) and `order-source` (not `order-distribution`).
  static const String dashboardMetrics = '/pharmacy/dashboard/summary';
  static const String dashboardOrderDistribution = '/pharmacy/dashboard/order-source';
  static const String dashboardFulfillmentTrend = '/pharmacy/dashboard/fulfillment-trend';
  static const String dashboardTopMedications = '/pharmacy/dashboard/top-medications';
  static const String dashboardRejectionNotes = '/pharmacy/dashboard/rejection-notes';
  static const String dashboardPerformance = '/pharmacy/dashboard/performance';

  // Module G: Notifications
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static String notificationRead(String id) => '/notifications/$id/read';

  // Module H: Ratings
  static String pharmacistRatings(String pharmacistId) => '/ratings/pharmacist/$pharmacistId';

  // Module I: Chat
  static const String chatHubUrl = 'http://204.168.149.185/hubs/chat';
  static const String chatConversations = '/chat/conversations';
  static String chatMessages(String conversationId) => '/chat/$conversationId/messages';
  static String chatConversationRead(String conversationId) =>
      '/chat/conversations/$conversationId/read';
  // General-purpose AI assistant chat (Pharmacist-only) — the pharmacist's
  // own conversation with the AI assistant, with optional patient context.
  static const String chatAiMessage = '/chat/ai-message';

  // Module J: Pharmacist Reminder Management
  static String createReminder(String patientId) => '/pharmacists/patients/$patientId/reminders';
  static String updateReminder(String scheduleId) => '/pharmacists/reminders/$scheduleId';
  static String deleteReminder(String scheduleId) => '/pharmacists/reminders/$scheduleId';
  static String pauseReminder(String scheduleId) => '/pharmacists/reminders/$scheduleId/pause';
  static String resumeReminder(String scheduleId) => '/pharmacists/reminders/$scheduleId/resume';
}
