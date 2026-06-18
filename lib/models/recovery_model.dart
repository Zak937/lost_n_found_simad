class RecoveryModel {
  final String id;
  final String targetItemId;
  final String claimantId;
  final String claimantEmail;
  final String statement;
  final String finderId;
  final bool isFakeClaim;
  final int? securityCode;
  final DateTime timestamp;

  RecoveryModel({
    required this.id,
    required this.targetItemId,
    required this.claimantId,
    required this.claimantEmail,
    required this.statement,
    required this.finderId,
    this.isFakeClaim = false,
    this.securityCode,
    required this.timestamp,
  });

  factory RecoveryModel.fromMap(Map<String, dynamic> map, String docId) {
    return RecoveryModel(
      id: docId,
      targetItemId: map['targetItemId'] ?? '',
      claimantId: map['claimantId'] ?? '',
      claimantEmail: map['claimantEmail'] ?? '',
      statement: map['statement'] ?? '',
      finderId: map['finderId'] ?? '',
      isFakeClaim: map['isFakeClaim'] ?? false,
      securityCode: map['securityCode'],
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'targetItemId': targetItemId,
      'claimantId': claimantId,
      'claimantEmail': claimantEmail,
      'statement': statement,
      'finderId': finderId,
      'isFakeClaim': isFakeClaim,
      'securityCode': securityCode,
      'timestamp': timestamp,
    };
  }
}
