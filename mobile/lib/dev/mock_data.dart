import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';

/// Compile-time toggle for development and screenshot mock fixtures.
/// In production and release builds, this is ALWAYS false.
const bool kUseMockData = bool.fromEnvironment('MOCK', defaultValue: false);

/// Mock Care Team member definition.
class MockCareMember {
  final String initials;
  final String name;
  final Color color;

  const MockCareMember({
    required this.initials,
    required this.name,
    required this.color,
  });
}

/// Development & test fixtures isolated behind [kUseMockData].
class DevMockData {
  static const List<MockCareMember> mockCareTeam = [
    MockCareMember(initials: 'VJ', name: 'Vaishnavi', color: Color(0xFF56B4E9)),
    MockCareMember(initials: 'RP', name: 'Rajendra', color: Color(0xFFE69F00)),
    MockCareMember(initials: 'GS', name: 'Gautam', color: Color(0xFF009E73)),
    MockCareMember(initials: 'KS', name: 'Krushna', color: Color(0xFFC8F05F)),
    MockCareMember(initials: 'DJ', name: 'Dr. Joshi', color: Color(0xFFE4C41B)),
  ];

  /// Realistic mock sessions for preview mode.
  static List<SessionRecord> createMockSessions() {
    final now = DateTime.now();
    return [
      SessionRecord(
        id: 'mock_sess_01',
        patientId: 'P-014',
        exerciseCode: 'fist_clench',
        planVersion: 1,
        startedAt: now.subtract(const Duration(hours: 2)),
        endedAt: now.subtract(const Duration(hours: 1, minutes: 55)),
        durationS: 300,
        repsCompleted: 10,
        repsTarget: 10,
        meanRom: 82.5,
        maxRom: 94.0,
        meanRepDurationS: 2.8,
        smoothness: 1.45,
        holdS: 0.5,
        consistency: 0.88,
        fatigueDropPct: 8.5,
        painAfter: 1,
        fatigueAfter: 2,
        dataQuality: 'good',
        dataSource: 'simulated',
        deviceId: 'H10-SIM-01',
        firmware: '1.0.0',
        calibrationRef: 'cal_default',
        clientVersion: '2.0.0',
        syncStatus: 'synced',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      SessionRecord(
        id: 'mock_sess_02',
        patientId: 'P-014',
        exerciseCode: 'pinch',
        planVersion: 1,
        startedAt: now.subtract(const Duration(days: 1, hours: 3)),
        endedAt: now.subtract(const Duration(days: 1, hours: 2, minutes: 54)),
        durationS: 360,
        repsCompleted: 12,
        repsTarget: 10,
        meanRom: 84.0,
        maxRom: 91.0,
        meanRepDurationS: 2.6,
        smoothness: 1.30,
        holdS: 0.5,
        consistency: 0.91,
        fatigueDropPct: 6.2,
        painAfter: 2,
        fatigueAfter: 3,
        dataQuality: 'good',
        dataSource: 'simulated',
        deviceId: 'H10-SIM-01',
        firmware: '1.0.0',
        calibrationRef: 'cal_default',
        clientVersion: '2.0.0',
        syncStatus: 'synced',
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      SessionRecord(
        id: 'mock_sess_03',
        patientId: 'P-014',
        exerciseCode: 'fist_clench',
        planVersion: 1,
        startedAt: now.subtract(const Duration(days: 2)),
        endedAt: now.subtract(const Duration(days: 2)).add(const Duration(minutes: 5)),
        durationS: 300,
        repsCompleted: 8,
        repsTarget: 10,
        meanRom: 76.0,
        maxRom: 88.0,
        meanRepDurationS: 3.1,
        smoothness: 1.62,
        holdS: 0.5,
        consistency: 0.82,
        fatigueDropPct: 12.0,
        painAfter: 1,
        fatigueAfter: 3,
        dataQuality: 'good',
        dataSource: 'simulated',
        deviceId: 'H10-SIM-01',
        firmware: '1.0.0',
        calibrationRef: 'cal_default',
        clientVersion: '2.0.0',
        syncStatus: 'synced',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}
