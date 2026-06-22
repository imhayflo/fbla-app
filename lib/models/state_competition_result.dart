import 'package:cloud_firestore/cloud_firestore.dart';

class StateCompetitionResult {
  final String id;
  final String memberName;
  final String normalizedName;
  final int placement;
  final String eventName;
  final String stateCode;
  final int conferenceYear;
  final int? conferenceMonth;
  final String conferenceLabel;
  final String? linkedUserId;

  const StateCompetitionResult({
    required this.id,
    required this.memberName,
    required this.normalizedName,
    required this.placement,
    required this.eventName,
    required this.stateCode,
    required this.conferenceYear,
    this.conferenceMonth,
    required this.conferenceLabel,
    this.linkedUserId,
  });

  String get placementOrdinal => _ordinal(placement);

  String get eventShortLabel {
    if (eventName.length <= 28) return eventName;
    return '${eventName.substring(0, 25)}…';
  }

  static String _ordinal(int n) {
    if (n <= 0) return '$n';
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  factory StateCompetitionResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StateCompetitionResult(
      id: doc.id,
      memberName: data['memberName']?.toString() ?? '',
      normalizedName: data['normalizedName']?.toString() ?? '',
      placement: data['placement'] is int
          ? data['placement'] as int
          : int.tryParse(data['placement']?.toString() ?? '') ?? 0,
      eventName: data['eventName']?.toString() ?? '',
      stateCode: data['stateCode']?.toString() ?? '',
      conferenceYear: data['conferenceYear'] is int
          ? data['conferenceYear'] as int
          : int.tryParse(data['conferenceYear']?.toString() ?? '') ?? 0,
      conferenceMonth: data['conferenceMonth'] is int
          ? data['conferenceMonth'] as int
          : int.tryParse(data['conferenceMonth']?.toString() ?? ''),
      conferenceLabel: data['conferenceLabel']?.toString() ?? 'State Leadership Conference',
      linkedUserId: data['linkedUserId']?.toString(),
    );
  }

  factory StateCompetitionResult.fromMap(Map<String, dynamic> data, {String? id}) {
    final name = data['memberName']?.toString() ?? '';
    return StateCompetitionResult(
      id: id ?? '',
      memberName: name,
      normalizedName:
          data['normalizedName']?.toString() ?? normalizeMemberName(name),
      placement: data['placement'] is int
          ? data['placement'] as int
          : int.tryParse(data['placement']?.toString() ?? '') ?? 0,
      eventName: data['eventName']?.toString() ?? '',
      stateCode: (data['stateCode']?.toString() ?? '').toUpperCase(),
      conferenceYear: data['conferenceYear'] is int
          ? data['conferenceYear'] as int
          : int.tryParse(data['conferenceYear']?.toString() ?? '') ?? 0,
      conferenceMonth: data['conferenceMonth'] is int
          ? data['conferenceMonth'] as int
          : int.tryParse(data['conferenceMonth']?.toString() ?? ''),
      conferenceLabel:
          data['conferenceLabel']?.toString() ?? 'State Leadership Conference',
      linkedUserId: data['linkedUserId']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberName': memberName,
      'normalizedName': normalizedName,
      'placement': placement,
      'eventName': eventName,
      'stateCode': stateCode,
      'conferenceYear': conferenceYear,
      if (conferenceMonth != null) 'conferenceMonth': conferenceMonth,
      'conferenceLabel': conferenceLabel,
      if (linkedUserId != null) 'linkedUserId': linkedUserId,
    };
  }

  static String normalizeMemberName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
