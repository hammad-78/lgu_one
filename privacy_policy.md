# Privacy Policy for LGU Connect

**Last updated:** September 17, 2026

This Privacy Policy explains how LGU-Connect team collects, uses, shares, and protects information when you use the LGU Connect mobile application (the "App").


1. Information we collect

We collect only the information needed to provide the App's campus services, publish community submissions, deliver notifications, and operate administrator functions.

Information you provide

- **Student email address:** The App may ask for an LGU student email address to apply its student-access check. The current student email check stores the remembered address on your device for convenience; it is not used as a student Firebase account and is not sent to our Firestore database by that check.
- **Lost and found submissions:** title, description, category, lost/found type, typed location, relevant date, WhatsApp number, photographs you select or take, and a private edit/delete code. A one-way hash of the lost-and-found code is stored so the code itself is not stored in that field.
- **Collaboration submissions:** title, description, category, required and existing member counts, required roles, WhatsApp number, a submission management key, and the device notification token associated with the submission when available.
- **Recommendations:** category, title, free-text details, and submission time.
- **Administrator information:** administrator email and password are processed by Firebase Authentication. Authorized administrator records may also contain a name, role, or administrator identifier.
- **Content managed by administrators:** events, jobs, news, societies, locations, dates, links, photographs, and contact details such as a society president's WhatsApp number.

Do not include sensitive personal information, passwords, government identifiers, financial information, or information about another person in a public submission. Use a phone number only when you understand that it may be visible to other App users.

Information collected automatically

- **Push-notification device token:** When notifications are enabled, Firebase Cloud Messaging provides a device token. We store the token, platform, and, where available, an associated Firebase user identifier so we can send App announcements and service notifications.
- **Notification state:** The App stores notification read-state identifiers locally on your device.
- **Technical and service information:** Firebase, the operating system, and hosting providers may process technical information needed to deliver, secure, and maintain their services, such as request metadata, timestamps, device/platform information, and service logs. We do not use a separate analytics or crash-reporting SDK in the current App.

The App does **not** intentionally collect precise device location, contacts, microphone recordings, call logs, browsing history, advertising identifiers for targeted advertising, or biometric information.

Information from other services

The App includes a student portal in a web view that loads `student.lgu.edu.pk`. Any login credentials, account information, cookies, or activity entered or collected in that portal are handled by that portal's operator under its own privacy policy and terms. We do not control or independently audit that third-party service.

2. How we use information

We use information to:

- provide, display, moderate, and manage lost-and-found and collaboration listings;
- allow users to contact a submitter through WhatsApp when the submitter has provided a WhatsApp number;
- publish campus events, jobs, news, society information, and recommendations;
- send general announcements, listing updates, and event reminders when notifications are enabled;
- authenticate and authorize administrators;
- store submitted photographs and other content;
- respond to support, safety, abuse, or deletion requests;
- maintain, troubleshoot, secure, and improve the App and its backend; and
- comply with legal obligations and enforce our terms or community rules.

3. Public content and sharing

Some App content is designed to be publicly readable. Once a listing is approved or published, its title, description, category, typed location, date, photographs, and provided contact number may be visible to other App users or anyone who can access the public App data. Administrators may review and moderate submissions.

We share information:

- **With Google Firebase:** We use Firebase Authentication, Cloud Firestore, Firebase Storage, Firebase Cloud Messaging, and server-side Firebase Cloud Functions to authenticate administrators, store content and images, deliver notifications, and operate the App.
- **With notification providers:** Device tokens and notification content are processed by Firebase Cloud Messaging so messages can be delivered to registered devices. Notifications are broadcast generally rather than targeted based on a personal profile, except where the relevant service behavior requires a token.
- **With WhatsApp:** If you tap a WhatsApp contact action, the selected phone number and message are passed to WhatsApp or its `wa.me` service. WhatsApp processes that information under its own privacy policy.
- **With service providers and authorities:** We may use hosting, storage, security, support, or legal service providers, and may disclose information when required by law, to protect users, or to investigate fraud, abuse, or security incidents.
- **During organizational changes:** Information may be transferred as part of a merger, acquisition, restructuring, or transfer of the App, subject to applicable law.

We do not sell personal information. We do not use personal information for third-party behavioral advertising in the current App.

4. Permissions

The App may request the following permissions, depending on your device and the feature you use:

- **Camera and photos/media:** to take or select photographs for lost-and-found or administrator-managed content. The App uploads selected photographs to Firebase Storage when you submit them.
- **Notifications:** to deliver App announcements, listing updates, and reminders. You can deny or later change this permission in your device settings.
- **Internet:** to connect to Firebase, the student portal, WhatsApp, and other App services.
- **Alarms and background restart on Android:** to support scheduled local reminders and notification delivery. These permissions do not give the App access to your contacts or precise location.

You can use many App features without granting optional camera, photo, or notification permissions, although the related feature may not work.

5. Retention

We retain information for as long as needed to provide the service, moderate and maintain community records, resolve disputes, comply with legal obligations, and protect the App. Retention depends on the type of information and the operational needs of the service.

The current notification history is limited by the backend to the most recent 20 notification records. Local remembered email and notification read-state can be removed from the device through the App's available clear/reset action or by clearing the App's local data in device settings.

Public submissions may remain available until they are removed by the submitter where the feature allows it, by an administrator, or after a deletion request is reviewed. Backups, logs, and copies maintained by Firebase or other providers may persist for a limited period after deletion under their retention and backup processes.

6. Your choices and deletion requests

You can:

- decline or revoke camera, photo, notification, and other device permissions in system settings;
- avoid submitting a phone number or photograph if you do not want it published;
- use the available lost-and-found edit/delete flow with the listing's management code; and
- request access, correction, or deletion of personal information by contacting [hammadalikhan9078@gmail.com].

To help us locate a submission, include the listing title or identifier, the email address used to contact us, and enough information to verify your request. We may need to verify your identity and may retain information where required by law or needed for security, fraud prevention, dispute resolution, or legal claims.

The App does not currently provide a general in-App account-deletion or data-export feature for students. A deletion request can therefore be submitted through the contact above. Administrator accounts are managed through the responsible institution and Firebase Authentication; administrators should contact the publisher to request account or associated-data deletion.

7. Security

We use Firebase Authentication, access rules, server-side functions, hashing for lost-and-found management codes, and encrypted connections provided by the platform and service providers. No method of transmission or storage is completely secure. You are responsible for keeping any submission management key private and for not posting information that you do not want publicly visible.

8. Children

The App is intended for university or college community members and is not directed to children under 13. We do not knowingly collect personal information from children under 13. If you believe a child has provided personal information, contact us at **[insert privacy or support email address]** so we can review and delete it where required.

If the App is made available to users under the applicable digital-consent age in a particular country, the publisher must update this section and the App's practices to satisfy that country's requirements before distribution there.

9. International processing

Firebase and other service providers may process information on servers located outside your country. Where required, we use appropriate safeguards for cross-border processing and require service providers to protect information according to their contractual and legal obligations.

10. Changes to this policy

We may update this Privacy Policy when the App, its data practices, or legal requirements change. We will update the "Last updated" date and, where appropriate, provide notice in the App or through another reasonable channel. Continued use after an update means the updated policy applies to future use of the App.

11. Contact us

For privacy questions, requests, complaints, or deletion requests, contact:

**Email:** [hammadalikhan9078@gmail.com]  
