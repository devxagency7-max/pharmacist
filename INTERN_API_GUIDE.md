# PharmacyIntern — Complete API Guide

> **Audience:** Flutter team building the intern-facing screens.
> **Base URL (current):** `http://187.7.30.23`
> **Auth:** `Authorization: Bearer <FIREBASE_ID_TOKEN>` on every request except where explicitly marked otherwise.

---

## 1. Who is a "PharmacyIntern"?

`PharmacyIntern` is `UserRole = 4` in the enum (see `Enums/UserRole.cs`). It's the pharmacy student role — someone still in their academic pharmacy program who is doing a supervised internship inside a real pharmacy. They:

- **Can** author *drafts* of prescription reviews and medication plans for their supervisor to accept or reject. They never write directly to the live clinical records.
- **Can** log their own training hours toward internship completion.
- **Can** view their own internship progress.
- **Cannot** approve/reject prescriptions themselves.
- **Cannot** manage a patient roster like a real Pharmacist does (`/pharmacists/my-patients`, `/pharmacists/pending-requests`).
- **Cannot** perform any Admin, SuperAdmin, PharmacyOwner, Dean, or Supervisor action.
- **Cannot** access the AI Chat (`/chat/ai-message`) — that's Pharmacist-only.

Everything else the app offers that's role-neutral — profile, notifications, chat with patients, file upload — works for an Intern the same as it does for any authenticated user.

---

## 2. Role transitions (how a user becomes a PharmacyIntern)

```
     ┌────────────────────┐
     │  New user signs in │
     │  via Firebase      │
     └─────────┬──────────┘
               │  auto-registered by FirebaseAuthMiddleware
               ▼
     ┌────────────────────┐
     │  Role: Patient (2) │        ← every account starts here
     └─────────┬──────────┘
               │  POST /api/v1/pharmacist/apply
               │  (ApplicationType = "Intern")
               ▼
     ┌───────────────────────────────┐
     │  PharmacistApplication row    │
     │  Status: Pending              │        ← awaiting admin
     └────────────┬──────────────────┘
                  │
       ┌──────────┴─────────────┐
       │                        │
       ▼                        ▼
  Admin approves            Admin rejects
       │                        │
       ▼                        ▼
  Role: PharmacyIntern     Status stays Patient
  (4) + Patient (2)        MembershipNumber released
                           user can re-apply
```

Once the application is `Approved`, `FirebaseAuthMiddleware` on the next request populates the user's ClaimsPrincipal with `PharmacyIntern`, and the `[Authorize(Policy = "InternOnly")]` endpoints open up.

---

## 3. Endpoint reference — everything an Intern touches

Legend for the **Access** column:
- 🟢 works for `PharmacyIntern` role
- 🟡 works only *before* they were approved (they were still a `Patient`) — used to become an Intern in the first place
- 🔴 will return 403 for `PharmacyIntern`
- ⚪ role-neutral — any authenticated user

### 3.1 Application / on-boarding (used *once*, before role is upgraded)

These live under `PharmacistController` — `[Route("api/v1/pharmacist")]`, `[Authorize]`. No specific role required — the intern-to-be is still just a `Patient` when they call these.

| Method | Path | Access | What it does | Body / important notes |
|---|---|---|---|---|
| POST | `/api/v1/pharmacist/apply` | 🟡 | Submit application to become an Intern (or Pharmacist). | Body: `{ applicationType: "Intern", membershipNumber, universityId, facultyId, universityName?, ... }`. Sets `Users.MembershipNumber` (uniquely). Resumable: re-POSTing before approval updates the same pending row instead of erroring. |
| GET | `/api/v1/pharmacist/application-status` | 🟢 🟡 | Returns the caller's most recent non-deleted application. **This is what the "Pending" screen in the app reads.** | 200 with `{ id, status, applicationType, submittedAt, reviewedAt, ... }` or 404 if the user has never applied. No cache — every call is a fresh DB read. |
| POST | `/api/v1/pharmacist/{applicationId}/documents` | 🟡 | Attach a document (National ID scan, syndicate card, etc.) to a *Pending* application. | Multipart. Uploads live in R2 via `IFileService`. |
| DELETE | `/api/v1/pharmacist/{applicationId}` | 🟡 | Withdraw a Pending application. | **Only works while status is Pending.** Once Admin has Approved/Rejected, returns **400** with `errorCode = "APPLICATION_NOT_PENDING"` and `details = { currentStatus, reviewedAt }` — see §5 for how to react. |

**Once role becomes `PharmacyIntern` there is nothing else to do here** — the intern doesn't POST /apply again. If the screen still shows the withdraw button after approval, that's the stale-state bug (see §5).

### 3.2 Intern-only endpoints (the real work — under `InternController`)

All of these require `[Authorize(Policy = "InternOnly")]`. Also all of them require that the intern has an **active `InternshipAssignment`** in the DB — that row is created by a `FacultyDean` inside the Academic module. Without it, every call in this section returns **403 "No active internship assignment found for this account."**

Path prefix: `/api/v1` (the routes don't share a common suffix — they're grouped by controller, not by URL).

| Method | Path | Access | What it does | Notes |
|---|---|---|---|---|
| POST | `/api/v1/prescriptions/{id}/draft-recommendation` | 🟢 | Submit the intern's **draft review** of an existing prescription for their supervisor to accept or reject. | Body: `{ payloadJson, notes? }`. Creates an `InternClinicalDraft` row with `EntityKind = PrescriptionReview` and `Status = PendingSupervisorReview`. The real `Prescription` is not touched. |
| POST | `/api/v1/medications/draft` | 🟢 | Submit a **draft medication plan** — either revising an existing plan or proposing a brand-new one. | Body: `{ existingMedicationPlanId?, payloadJson, notes? }`. If `existingMedicationPlanId` is null → it's a proposal for a patient with no plan yet, and `TargetEntityId` stays null. |
| POST | `/api/v1/intern/activities/log-hours` | 🟢 | Record training hours toward internship completion (self-report). | Body: `{ activityType, hours, notes?, ... }` — schema in `LogTrainingHoursRequest`. |
| GET | `/api/v1/intern/progress` | 🟢 | Read the intern's own progress: assignment status, hours logged vs required, drafts submitted, drafts accepted, etc. | Response: `InternProgressResponse`. |

**No "list my drafts" endpoint exists yet** — supervisors see drafts through the Supervisor controller, but the intern themselves has no dedicated read endpoint for their own submissions beyond `/intern/progress`. Track them on the client side after the POST returns.

### 3.3 Shared endpoints (Intern gets access as an authenticated user)

These are `[Authorize]`-only, no role restriction. An Intern can use them freely.

| Method | Path | Access | What it does |
|---|---|---|---|
| GET | `/api/v1/users/me` | ⚪ | Read the caller's profile: id, name, email, phone, roles, status, membership number. |
| PUT | `/api/v1/users/me` | ⚪ | Update the caller's profile (name/phone/etc.). |
| DELETE | `/api/v1/users/me` | ⚪ | Delete the account. Also removes the Firebase auth record. |
| POST | `/api/v1/users/sync` | ⚪ | Compat endpoint from before auto-registration existed. Safe to skip on new clients — `FirebaseAuthMiddleware` already auto-creates the row on first login. |
| POST | `/api/v1/users/profile/complete` | ⚪ | Fill in required fields the auto-registered user was missing (phone, etc.) before hitting a phone-required endpoint. |
| GET / POST / PATCH / DELETE | `/api/v1/users/me/addresses` (+ sub-paths) | ⚪ | CRUD the caller's saved addresses. |
| GET | `/api/v1/notifications` | ⚪ | Paginated notifications for the caller. |
| GET | `/api/v1/notifications/unread-count` | ⚪ | Badge count. |
| PUT | `/api/v1/notifications/{id}/read` | ⚪ | Mark one as read. |
| PUT | `/api/v1/notifications/read-all` | ⚪ | Mark all as read. |
| GET | `/api/v1/chat/conversations` | ⚪ | List conversations the caller participates in. |
| POST | `/api/v1/chat/conversations` | ⚪ | Start a new one (typically Intern ↔ Patient). |
| GET | `/api/v1/chat/{id}/messages` | ⚪ | Fetch messages in a conversation (cursor-paginated). |
| POST | `/api/v1/chat/{id}/messages` | ⚪ | Send a message. |
| PUT | `/api/v1/chat/conversations/{id}/read` | ⚪ | Mark a whole conversation read. |
| POST | `/api/files/upload` | ⚪ | Upload a file to R2. Returns `{ id, url }`. Same endpoint used for application documents, chat attachments, etc. |
| GET | `/api/files/my` | ⚪ | List files the caller has uploaded. |
| GET | `/api/files/{id}` | ⚪ | Get a fresh signed URL for a stored file. |
| DELETE | `/api/files/{id}` | ⚪ | Delete an uploaded file. |
| GET | `/api/v1/search/medicines?q=…` | ⚪ | Medicine catalog search (public/authenticated). |
| GET | `/api/v1/search/pharmacies?...` | ⚪ | Pharmacy directory search. |
| GET | `/api/v1/medicines/search?...` | ⚪ | Same catalog under a different route (deprecated alias). |
| GET | `/api/v1/medicines/{id}` | ⚪ | Medicine detail. |
| GET | `/api/v1/pharmacists` (Discovery) | ⚪ | Browse pharmacists — the *directory*, not admin management. |
| GET | `/api/v1/pharmacists/{id}` | ⚪ | Pharmacist public profile. |
| GET | `/api/v1/ratings/pharmacist/{id}` | ⚪ *(also `[AllowAnonymous]`)* | Read pharmacist ratings. Works even without a token — do **not** treat a 200 here as "my token is valid." |
| GET | `/api/v1/ratings/pharmacy/{id}` | ⚪ *(also `[AllowAnonymous]`)* | Same, for pharmacy ratings. |
| POST | `/api/v1/ratings` | ⚪ | Submit a rating. |
| GET | `/health` | ⚪ (no auth) | Liveness probe. Never depends on DB or Firebase. |

### 3.4 Endpoints an Intern **cannot** use (returns 403)

These require a different role. Show them as **disabled / hidden** in the Intern build:

| Path | Required role | Note |
|---|---|---|
| `GET /api/v1/pharmacists/my-patients` | Pharmacist | Managing a patient roster. Intern doesn't have their own patients. |
| `GET /api/v1/pharmacists/pending-requests` | Pharmacist | Same reason. |
| `PUT /api/v1/pharmacists/requests/{id}/respond` | Pharmacist | Same. |
| `GET /api/v1/pharmacists/patients/{id}` | Pharmacist | Same. |
| `PUT /api/v1/pharmacists/patients/{id}/terminate` | Pharmacist | Same. |
| `POST /api/v1/pharmacists/patients/{id}/reminders` | Pharmacist | Same. |
| `POST /api/v1/prescriptions` | Patient (upload) or Pharmacist (create-on-behalf) | Interns don't upload prescriptions themselves. |
| `POST /api/v1/prescriptions/{id}/approve` | Pharmacist / PharmacyOwner | Only *supervisors* accept the intern's drafts. |
| `POST /api/v1/prescriptions/{id}/reject` | Pharmacist / PharmacyOwner | Same. |
| `POST /api/v1/prescriptions/{id}/review` | Pharmacist | Same. |
| `GET /api/v1/prescriptions/pending` | Pharmacist | The reviewer queue, not the intern queue. |
| `POST /api/v1/chat/ai-message` | Pharmacist | AI assistant is Pharmacist-only by design. |
| `POST /api/v1/admin/*` | Admin / SuperAdmin | All admin dashboard endpoints. |
| `POST /api/v1/super-admin/*` | SuperAdmin | Admin-management endpoints. |
| `GET/POST /api/v1/dean/*` | FacultyDean | Faculty-side operations. |
| `GET/POST /api/v1/supervisor/*` | Pharmacist *acting as* Supervisor | Supervisors approve intern drafts here — the intern themselves does not. |

If you're not sure whether an endpoint should be exposed to the Intern build, the safe default is **hide it and add it only when a real screen needs it** — the backend's 403 is clear but a hidden feature avoids the user seeing "Access denied" toasts.

---

## 4. Recommended screen-by-screen flow (Flutter)

### 4.1 On app launch (or resume) after Firebase auth

```
1. FirebaseAuth.instance.currentUser.getIdToken(true)   ← force refresh; role changes only take effect on a NEW token
2. GET /api/v1/users/me
       → { roles: ["Patient"] }        → show onboarding / "Apply as Intern" screen
       → { roles: [..., "PharmacyIntern"] }  → show Intern home
3. If roles contains PharmacyIntern:
       GET /api/v1/intern/progress
              → 200: show progress dashboard
              → 403 "No active internship assignment...":
                        show a "Waiting for your faculty to assign you a supervisor" screen
```

Never trust roles cached in Flutter across sessions — always re-read `users/me` on cold start.

### 4.2 On the "Application under review" screen

**This is the screen from the bug report.** Do this exactly:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  _refresh();
}

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) _refresh();
}

Future<void> _refresh() async {
  final r = await api.getApplicationStatus();
  if (mounted) setState(() => _application = r);
}
```

Also call `_refresh()` right before firing the withdraw request. Rationale: admin approval is fast, the app's cached "Pending" can be seconds out of date, and calling withdraw then produces a 400 the user shouldn't have to see.

### 4.3 On the "Withdraw" button

```dart
Future<void> _onWithdrawTap() async {
  await _refresh();
  if (_application?.status != 'Pending') {
    showSnackBar('حالة الطلب اتغيرت لـ ${_application?.status}');
    return; // don't fire the DELETE at all
  }

  try {
    await api.withdraw(_application!.id);
    // route back to "Apply again" screen
  } on ApiError catch (e) {
    if (e.errorCode == 'APPLICATION_NOT_PENDING') {
      final current = e.details?['currentStatus'];
      setState(() => _application = _application!.copyWith(status: current));
      showSnackBar('تم مراجعة الطلب بالفعل ($current).');
      return;
    }
    rethrow;
  }
}
```

### 4.4 On the "Log training hours" screen

```
POST /api/v1/intern/activities/log-hours
403 "No active internship assignment..." → tell the user their faculty hasn't onboarded them yet
200 → show confirmation, refresh progress
```

### 4.5 On the "Draft a prescription review" screen

Prerequisite: an existing `Prescription` id (from a supervisor sharing one with the intern, or from `GET /api/v1/prescriptions/me` if the intern is also a patient with their own prescriptions).

```
POST /api/v1/prescriptions/{id}/draft-recommendation
     body: { payloadJson: "<intern's proposed review as JSON string>", notes: "<free text>" }
200 → ClinicalDraftResponse with id + status = PendingSupervisorReview
        show "Sent to your supervisor" state
403 → intern has no active assignment
404 → prescription id is wrong / soft-deleted
```

### 4.6 On the "Draft a medication plan" screen

```
POST /api/v1/medications/draft
     body: { existingMedicationPlanId?: uuid, payloadJson: "…", notes?: "…" }
200 → ClinicalDraftResponse with status = PendingSupervisorReview
```

Same 403/404 behavior as above.

---

## 5. Response envelope contract (relevant to all of the above)

Every success response wraps its payload in:

```json
{
  "success": true,
  "message": "…",
  "data": { … },
  "errors": null,
  "errorCode": null,
  "details": null
}
```

Every failure response uses the same envelope with `success: false` and `data` omitted. Since today's deploy, failures caused by a business rule may carry structured context in `details`:

```json
{
  "success": false,
  "message": "Only a pending application can be withdrawn. Current status: Approved.",
  "errors": null,
  "errorCode": "APPLICATION_NOT_PENDING",
  "details": {
    "currentStatus": "Approved",
    "reviewedAt": "2026-09-29T21:00:30Z"
  }
}
```

Prefer switching on `errorCode` over matching `message` strings — messages are subject to copy edits, error codes are stable.

Known status-code semantics for this section:
- **200** — success.
- **400** — validation failed, or a business-rule guard tripped. Look at `errorCode`.
- **401** — no token, expired token, or Firebase signature verification failed. Force re-login.
- **403** — token is valid but the user's role isn't allowed **or** the user is `Banned`/`Suspended`/`Rejected`. Not something the user can fix by refreshing — show a role-appropriate message.
- **404** — resource not found *or* the resource exists but doesn't belong to the caller (returned as 404 on purpose to avoid enumeration).
- **409** — a unique-constraint conflict. `IX_Users_MembershipNumber` (someone else already used this National ID / Syndicate ID) and `IX_Pharmacies_RegistrationNumber` are the two you're likely to hit. **Phone is no longer unique** — you won't see 409 from that.
- **429** — rate-limited. Slow down and retry after `Retry-After`.
- **500** — an unhandled exception. Send us the correlation id (log line prefix) and a timestamp.

---

## 6. Auth-token gotchas the app team has hit before

1. **Role changes require a fresh ID token.** When Admin approves the application, the intern's role in DB becomes `PharmacyIntern`, but their current Firebase ID token was minted while they were a `Patient` and doesn't reflect the change. `FirebaseAuthMiddleware` reads the DB user on every request anyway, so the effective role updates immediately server-side — but if your Flutter app is caching claims client-side, force `getIdToken(true)` after any promotion-related action.

2. **`ratings` endpoints are marked `[AllowAnonymous]`.** They will 200 even with no token or a bad token. Never use them to smoke-test whether "my Bearer token works."

3. **`/health` is deliberately independent of auth and DB.** Same reason — smoke-testing your API base URL is fine, but a healthy `/health` does not mean anything about token acceptance.

4. **Firebase custom tokens ≠ Firebase ID tokens.** Only ID tokens (`FirebaseAuth.instance.currentUser.getIdToken()`) work with the backend. Custom tokens (rare — usually server-minted for special sign-in flows) don't.

5. **Clock skew on the phone rejects a fresh token.** If a user's phone clock is >5 minutes off, `iat`/`exp` fall outside the accepted window and Firebase Admin rejects the token with the same "invalid signature" wording. If a single user gets 401 on everything but others are fine, ask them to check their device date/time.

---

## 7. Quick curl reference

```bash
# 1. Health (no auth)
curl http://187.7.30.23/health

# 2. My profile
curl -H "Authorization: Bearer $TOKEN" http://187.7.30.23/api/v1/users/me

# 3. My application status
curl -H "Authorization: Bearer $TOKEN" http://187.7.30.23/api/v1/pharmacist/application-status

# 4. Apply as Intern
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
     -d '{"applicationType":"Intern","membershipNumber":"12345","universityId":"...","facultyId":"..."}' \
     http://187.7.30.23/api/v1/pharmacist/apply

# 5. Withdraw a Pending application
curl -X DELETE -H "Authorization: Bearer $TOKEN" \
     http://187.7.30.23/api/v1/pharmacist/{applicationId}

# 6. My internship progress
curl -H "Authorization: Bearer $TOKEN" http://187.7.30.23/api/v1/intern/progress

# 7. Log training hours
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
     -d '{"activityType":"...","hours":4,"notes":"…"}' \
     http://187.7.30.23/api/v1/intern/activities/log-hours

# 8. Draft a prescription review
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
     -d '{"payloadJson":"…","notes":"…"}' \
     http://187.7.30.23/api/v1/prescriptions/{prescriptionId}/draft-recommendation

# 9. Draft a medication plan
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
     -d '{"existingMedicationPlanId":null,"payloadJson":"…","notes":"…"}' \
     http://187.7.30.23/api/v1/medications/draft
```

---

## 8. If you get stuck

- **Every request has a correlation id in the log line prefix** (e.g. `[21:14:16 INF] … 3d81cc20fcba…`). Include it when you ping backend.
- Backend server: `ssh -i ~/.ssh/pharmacare_hostinger deploy@187.7.30.23`, then `cd /opt/pharmacare/app && docker compose logs api --tail=200`.
- **Base URL will change to `https://…` once the domain is set up.** Store it as a build config, not a hard-coded literal in every file.
