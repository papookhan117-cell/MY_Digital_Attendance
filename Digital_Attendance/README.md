# Digital Attendance

**Smart Face & QR Attendance System** — an offline-first PWA upgraded from the provided Offline Face Attendance Starter. Records are always saved locally first. If Sync & Access is configured, employee and attendance records also sync through the authenticated Supabase project; face descriptors stay only in each device's IndexedDB.

## Run and install

Camera APIs and service workers require a secure context. Serve this folder from `https://` or `http://localhost`; opening `index.html` directly as a file is not supported for camera use.

1. Copy the complete `Digital_Attendance` folder to a static HTTPS host or a local web server. It has no server-side code or remote database.
2. Open the address in a current version of Google Chrome. On first launch, wait for the local face models to load and accept camera permission.
3. In Chrome, use **Install app** / **Add to Home screen** to install the PWA. After the first successful load, the service worker caches the app, QR library, face-recognition library and models for offline use.
4. Test offline by reopening the installed app after the first load, then switching on airplane mode.

### Windows PC

1. Keep the entire `Digital_Attendance` folder together.
2. Double-click `Start-Digital-Attendance.bat`. Leave the black server window open while using the app.
3. In Chrome open `http://localhost:8080`. After changing/updating the folder, close old app tabs and reopen this address; use Ctrl+F5 if it still shows an old page.
4. Allow camera access when prompted. Do not open `index.html` directly from File Explorer.

### Android phone

The local PC address above works only on that PC. For Android, upload the updated folder contents to an HTTPS static host, open that HTTPS address in Chrome, allow camera access, then use **Add to Home screen**. Reload the hosted site after deploying a new version. The app has no runtime CDN dependency.

For first setup, keep an internet connection on until the local app files and face models have loaded once.

## Attendance behavior

- Every employee's attendance is one daily summary: one required check-in and an optional check-out.
- Each employee is assigned Support Staff, Management Staff, or Teaching Staff and checked against that group’s start time plus one shared grace period. A scan records Present or Late and stores the scheduled time, check-in time, and minutes late.
- Check-out updates that day's summary; it cannot create a record without a check-in and can only be saved once per date.
- **Mark absent remaining** writes Absent for active employees with no record today. If one arrives later and scans, that same row becomes Present or Late. Individual attendance rows can be deleted from a daily report; deleting one allows a new check-in for that day.
- Employees are not deleted. Deactivate an employee to reject both recognition and QR attendance while preserving all saved history.
- Employee IDs are case-insensitively unique and remain fixed once saved so historical attendance stays linked.
- CSV exports actual attendance records, with separate employee ID, name, date, status, check-in/out times and methods. Employee IDs are exported as quoted text for Excel / Access imports.

## Modules

- Employee registration and editing, optional compressed local profile photo, staff category assignment, face enrollment, active status, generated QR display, and printable QR card. Adding, editing, or deactivating employees requires an unlocked admin session.
- Automatically migrates records from the provided starter app's `OfflineFaceAttendanceDB` into the new local database on first launch, preserving known employees and valid attendance history.
- Live face matching with locally bundled face-api runtime and Tiny Face Detector, tiny 68-point landmark and face-recognition models.
- Live QR detection with Chrome's built-in `BarcodeDetector` on the camera stream, with the bundled scanner as a QR-only fallback when needed; QR image generation uses a bundled library.
- Dashboard greeting with live clock and clickable employee/attendance totals; employee monthly profiles with Present/Late/Absent totals; mobile back navigation, an in-app update checker, and side-by-side scanner/result with live marked/remaining counts; password-protected Admin Dashboard for company information, group start times and shared late grace period; employee schedule assignment overview; front/back camera selection; daily and monthly reports, row deletion, CSV export and native share sheet for reports (choose Gmail or another installed app), JSON backup and validated merge restore.
- PWA manifest and service-worker cache for offline operation after the initial load.
- Optional shared-device sync through Supabase Auth and Row Level Security. It is not active until the owner creates the free project, runs the SQL setup, and signs in on each device.

## Admin access

On first use, open **Admin Dashboard** and create a password (8 or more characters). The app stores a salted PBKDF2 password verifier, not the plain password. Admin access locks after 10 minutes without activity or when you press **Lock admin**. Company details, schedules, and the password verifier sync to the authenticated Supabase account when sync is configured. If sync is not configured, each browser keeps its own settings and admin password. The password gate controls the app interface; it does not encrypt local attendance data or replace server-side authentication. Keep the device and browser profile protected.

## Optional free sync between devices

This adds a remote database, changing the original local-only requirement. Employee details, active status, QR identifiers and attendance are sent to the Supabase project after sign-in. Face descriptors are intentionally excluded and remain on the device where each face was enrolled. On a second device, QR/report work after sync; face attendance requires enrolling each employee on that device.

1. Create a Supabase account and a project on the **Free** plan. Do not add a paid plan or service-role key to the app.
2. In the project dashboard, open **SQL Editor**, paste and run `supabase/setup.sql`. It creates employee, attendance, deletion-marker, and shared settings tables with authenticated-user Row Level Security and a unique employee/date attendance constraint. Run the script again after installing this update to add the new schedule, Late, and Absent columns to an existing project.
3. In **Project Settings → API**, copy the Project URL and the **publishable** (or legacy anon) key. Never use or share the `service_role` secret.
4. Create an Auth user in **Authentication → Users** with an email and password you control.
5. On the PC and every mobile device, open **Sync & Access** in Digital Attendance. Enter that same Project URL, public key and Auth account, then choose **Save & sign in**. Use the same account on every device.
6. Keep the app online briefly on each device so local records can upload and shared records can download. The page retries every 15 seconds, on reconnect, and while the app is in use.

While offline, records are written to the device's IndexedDB and wait for a connection. If two devices each mark the same employee while both are offline, both can temporarily show a locally saved check-in. On reconnect the unique cloud key keeps one daily record; the first record accepted by the shared database wins, and the other device replaces its pending copy with that shared record. Keep backups before testing sync or clearing data.

The current Supabase Free plan has usage limits (including 500 MB per project and 5 GB egress) and may pause projects after seven days of low activity. Sync therefore is useful for a small deployment but is not a guaranteed always-on service. A paused project must be restored from its dashboard. Check current plan terms before relying on it for payroll or other critical records. Source: [Supabase Free plan and limits](https://supabase.com/pricing), [Free project pausing](https://supabase.com/docs/guides/platform/free-project-pausing).

## Backup and privacy

Create a JSON backup from **Backup & Restore** before clearing browser storage, reinstalling Chrome, or moving devices. Restore the JSON on the destination device; the app merges employees by ID and attendance by daily record key. Face descriptors are part of the backup and are biometric data. Store backup files privately and limit access. Without setting up Sync & Access, devices do not sync. Clearing browser data or uninstalling can erase the only local copy.

## Face recognition and limitations

The app stores a 128-number face descriptor locally, not a cloud photo. It compares live descriptors against active employees with a fixed similarity threshold. This is face recognition, but it is not a certified biometric terminal. Robust liveness / anti-spoofing is not implemented, so a photo or screen replay may fool it. Camera quality, lighting, angle and device performance affect matching. Use employee consent and retain an alternative attendance process where needed.

QR payloads identify an employee ID and are not cryptographically signed. They are convenient local identifiers, not proof of identity; use supervised scanning.

## Technical structure

```text
Digital_Attendance/
├── index.html
├── manifest.webmanifest
├── sw.js
├── README.md
├── css/style.css
├── js/{app,database,employees,attendance,face-recognition,sync}.js
├── libraries/{face-api.min,html5-qrcode.min,qrcode.min}.js
├── models/                    # local face model manifests and weights
├── assets/icons/icon.svg
└── supabase/setup.sql
```

No employee data, generated backups or camera captures belong in the source repository. Third-party code and face model files are included for local operation; see `THIRD_PARTY_NOTICES.md` for license references.

## Developer

Usaid ul Hassan · [0304-0307828](tel:03040307828) · [usaidulhassan@gmail.com](mailto:usaidulhassan@gmail.com)

## Verification status

Source syntax, local resource paths and service-worker precache entries are checked before delivery. Camera-based face and QR recognition, Android installation, and offline behavior need to be verified on actual supported devices with camera permissions. No liveness detection is claimed.

