import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgu_one/esociety/esociety_models.dart';

Idea _idea(
  String id, {
  DateTime? meetingAt,
  DateTime? requestedAt,
  bool deactivated = false,
}) => Idea(
  id: id,
  studentUid: 'student',
  studentName: 'Student',
  studentEmail: 'student@students.lgu.edu.pk',
  studentPhoto: null,
  degree: 'BSCS',
  semester: 3,
  whatsapp: '03001234567',
  title: 'Idea $id',
  description: '',
  category: 'Tech / App',
  roles: const [],
  teamSize: 1,
  teamWanted: 3,
  createdAt: null,
  meetingAt: meetingAt,
  meetingPlace: '',
  requestedAt: requestedAt,
  requestNote: '',
  deactivated: deactivated,
);

void main() {
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1, 11);

  group('Past or active', () {
    test('a new idea with no meeting is active', () {
      expect(_idea('a').isPast, isFalse);
    });

    test('an upcoming meeting is active', () {
      final idea = _idea('a', meetingAt: tomorrow);
      expect(idea.isPast, isFalse);
      expect(idea.hasUpcomingMeeting, isTrue);
    });

    test('a meeting that has happened moves the idea to Past', () {
      final idea = _idea(
        'a',
        meetingAt: now.subtract(const Duration(hours: 1)),
      );
      expect(idea.isPast, isTrue);
      expect(idea.hasUpcomingMeeting, isFalse);
    });

    test('a deactivated idea is Past, even with an upcoming meeting', () {
      final idea = _idea('a', meetingAt: tomorrow, deactivated: true);
      expect(idea.isPast, isTrue);
      expect(idea.hasUpcomingMeeting, isFalse);
    });

    test('a passed meeting with an open request stays active', () {
      final idea = _idea(
        'a',
        meetingAt: now.subtract(const Duration(hours: 1)),
        requestedAt: tomorrow,
      );
      expect(idea.isPast, isFalse);
    });
  });

  group('Meeting clashes', () {
    final booked = _idea('booked', meetingAt: tomorrow);

    test('a free time has no clash', () {
      final at = tomorrow.add(const Duration(hours: 2));
      expect(meetingClash([booked], at), isNull);
    });

    test('a time within 30 minutes of another meeting clashes', () {
      final at = tomorrow.add(const Duration(minutes: 20));
      expect(meetingClash([booked], at)?.id, 'booked');
      final before = tomorrow.subtract(const Duration(minutes: 29));
      expect(meetingClash([booked], before)?.id, 'booked');
    });

    test('exactly 30 minutes apart is allowed', () {
      final at = tomorrow.add(kMeetingLength);
      expect(meetingClash([booked], at), isNull);
    });

    test('an idea does not clash with its own meeting', () {
      expect(meetingClash([booked], tomorrow, except: 'booked'), isNull);
    });

    test('deactivated and past meetings free their slot', () {
      final off = _idea('off', meetingAt: tomorrow, deactivated: true);
      final done = _idea(
        'done',
        meetingAt: now.subtract(const Duration(days: 1)),
      );
      expect(meetingClash([off, done], tomorrow), isNull);
      expect(meetingClash([off, done], done.meetingAt!), isNull);
    });
  });

  group('Error messages', () {
    test('permission denied names the database rules', () {
      final error = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      expect(
        writeErrorText(error, action: 'Sending'),
        contains('database rules'),
      );
    });

    test('only a real connection error mentions the connection', () {
      final offline = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );
      expect(
        writeErrorText(offline, action: 'Sending'),
        contains('no connection'),
      );
      final other = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
      );
      expect(
        writeErrorText(other, action: 'Sending'),
        contains('invalid-argument'),
      );
      expect(
        writeErrorText(other, action: 'Sending'),
        isNot(contains('connection')),
      );
    });
  });
}
