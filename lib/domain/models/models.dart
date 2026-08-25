import 'dart:convert';

enum UserRole {
  member,
  keeper,
  admin;

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'keeper':
        return UserRole.keeper;
      case 'member':
      default:
        return UserRole.member;
    }
  }

  String toStr() => name;
}

enum UserStatus {
  pending,
  approved,
  rejected;

  static UserStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'approved':
        return UserStatus.approved;
      case 'rejected':
        return UserStatus.rejected;
      case 'pending':
      default:
        return UserStatus.pending;
    }
  }

  String toStr() => name;
}

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? gcashNumber;
  final List<UserRole> roles;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.gcashNumber,
    required this.roles,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isApproved => status == UserStatus.approved;
  bool get isPending => status == UserStatus.pending;
  bool get isRejected => status == UserStatus.rejected;
  bool get isAdmin => roles.contains(UserRole.admin);
  bool get isKeeper => roles.contains(UserRole.keeper);
  bool get isMember => roles.contains(UserRole.member);

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? gcashNumber,
    List<UserRole>? roles,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      gcashNumber: gcashNumber ?? this.gcashNumber,
      roles: roles ?? List.from(this.roles),
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'gcashNumber': gcashNumber,
      'roles': roles.map((r) => r.toStr()).toList(),
      'status': status.toStr(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, {String? id}) {
    return AppUser(
      id: id ?? map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Unnamed User',
      photoUrl: map['photoUrl'] as String?,
      gcashNumber: map['gcashNumber'] as String?,
      roles: (map['roles'] as List<dynamic>?)
              ?.map((r) => UserRole.fromString(r.toString()))
              .toList() ??
          [UserRole.member],
      status: UserStatus.fromString(map['status'] as String? ?? 'pending'),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());
  factory AppUser.fromJson(String source) =>
      AppUser.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum ReportStatus {
  pending,
  confirmed,
  rejected;

  static ReportStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'confirmed':
        return ReportStatus.confirmed;
      case 'rejected':
        return ReportStatus.rejected;
      case 'pending':
      default:
        return ReportStatus.pending;
    }
  }

  String toStr() => name;
}

class SwearReport {
  final String id;
  final String reporterId;
  final String accusedId;
  final int count;
  final String? note;
  final double rateApplied;
  final double totalAmount;
  final ReportStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime createdAt;

  const SwearReport({
    required this.id,
    required this.reporterId,
    required this.accusedId,
    required this.count,
    this.note,
    required this.rateApplied,
    required this.totalAmount,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    required this.createdAt,
  });

  bool get isPending => status == ReportStatus.pending;
  bool get isConfirmed => status == ReportStatus.confirmed;
  bool get isRejected => status == ReportStatus.rejected;

  SwearReport copyWith({
    String? id,
    String? reporterId,
    String? accusedId,
    int? count,
    String? note,
    double? rateApplied,
    double? totalAmount,
    ReportStatus? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
    DateTime? createdAt,
  }) {
    return SwearReport(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      accusedId: accusedId ?? this.accusedId,
      count: count ?? this.count,
      note: note ?? this.note,
      rateApplied: rateApplied ?? this.rateApplied,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporterId': reporterId,
      'accusedId': accusedId,
      'count': count,
      'note': note,
      'rateApplied': rateApplied,
      'totalAmount': totalAmount,
      'status': status.toStr(),
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SwearReport.fromMap(Map<String, dynamic> map, {String? id}) {
    final countVal = (map['count'] as num?)?.toInt() ?? 1;
    final rateVal = (map['rateApplied'] as num?)?.toDouble() ?? 50.0;
    final totalVal =
        (map['totalAmount'] as num?)?.toDouble() ?? (countVal * rateVal);

    return SwearReport(
      id: id ?? map['id'] as String? ?? '',
      reporterId: map['reporterId'] as String? ?? '',
      accusedId: map['accusedId'] as String? ?? '',
      count: countVal,
      note: map['note'] as String?,
      rateApplied: rateVal,
      totalAmount: totalVal,
      status: ReportStatus.fromString(map['status'] as String? ?? 'pending'),
      reviewedBy: map['reviewedBy'] as String?,
      reviewedAt: map['reviewedAt'] != null
          ? DateTime.tryParse(map['reviewedAt'].toString())
          : null,
      rejectionReason: map['rejectionReason'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwearReport && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum DebtStatus {
  active,
  paid,
  dismissed;

  static DebtStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'paid':
        return DebtStatus.paid;
      case 'dismissed':
        return DebtStatus.dismissed;
      case 'active':
      default:
        return DebtStatus.active;
    }
  }

  String toStr() => name;
}

class PaymentRecord {
  final String id;
  final String debtId;
  final double amount;
  final String recordedBy;
  final DateTime recordedAt;
  final String? note;

  const PaymentRecord({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.recordedBy,
    required this.recordedAt,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debtId': debtId,
      'amount': amount,
      'recordedBy': recordedBy,
      'recordedAt': recordedAt.toIso8601String(),
      'note': note,
    };
  }

  factory PaymentRecord.fromMap(Map<String, dynamic> map, {String? id}) {
    return PaymentRecord(
      id: id ?? map['id'] as String? ?? '',
      debtId: map['debtId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      recordedBy: map['recordedBy'] as String? ?? '',
      recordedAt: map['recordedAt'] != null
          ? DateTime.tryParse(map['recordedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      note: map['note'] as String?,
    );
  }
}

class DebtObligation {
  final String id;
  final String reportId;
  final String debtorId;
  final String recipientId;
  final double originalAmount;
  final double remainingBalance;
  final DebtStatus status;
  final bool isTransferred;
  final String? transferredFromKeeperId;
  final List<PaymentRecord> payments;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const DebtObligation({
    required this.id,
    required this.reportId,
    required this.debtorId,
    required this.recipientId,
    required this.originalAmount,
    required this.remainingBalance,
    required this.status,
    this.isTransferred = false,
    this.transferredFromKeeperId,
    this.payments = const [],
    required this.createdAt,
    this.resolvedAt,
  });

  bool get isActive => status == DebtStatus.active;
  bool get isPaid => status == DebtStatus.paid;
  bool get isDismissed => status == DebtStatus.dismissed;

  DebtObligation copyWith({
    String? id,
    String? reportId,
    String? debtorId,
    String? recipientId,
    double? originalAmount,
    double? remainingBalance,
    DebtStatus? status,
    bool? isTransferred,
    String? transferredFromKeeperId,
    List<PaymentRecord>? payments,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return DebtObligation(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      debtorId: debtorId ?? this.debtorId,
      recipientId: recipientId ?? this.recipientId,
      originalAmount: originalAmount ?? this.originalAmount,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      status: status ?? this.status,
      isTransferred: isTransferred ?? this.isTransferred,
      transferredFromKeeperId:
          transferredFromKeeperId ?? this.transferredFromKeeperId,
      payments: payments ?? List.from(this.payments),
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reportId': reportId,
      'debtorId': debtorId,
      'recipientId': recipientId,
      'originalAmount': originalAmount,
      'remainingBalance': remainingBalance,
      'status': status.toStr(),
      'isTransferred': isTransferred,
      'transferredFromKeeperId': transferredFromKeeperId,
      'payments': payments.map((p) => p.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  factory DebtObligation.fromMap(Map<String, dynamic> map, {String? id}) {
    return DebtObligation(
      id: id ?? map['id'] as String? ?? '',
      reportId: map['reportId'] as String? ?? '',
      debtorId: map['debtorId'] as String? ?? '',
      recipientId: map['recipientId'] as String? ?? '',
      originalAmount: (map['originalAmount'] as num?)?.toDouble() ?? 0.0,
      remainingBalance: (map['remainingBalance'] as num?)?.toDouble() ?? 0.0,
      status: DebtStatus.fromString(map['status'] as String? ?? 'active'),
      isTransferred: map['isTransferred'] as bool? ?? false,
      transferredFromKeeperId: map['transferredFromKeeperId'] as String?,
      payments: (map['payments'] as List<dynamic>?)
              ?.map((p) =>
                  PaymentRecord.fromMap(Map<String, dynamic>.from(p as Map)))
              .toList() ??
          [],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      resolvedAt: map['resolvedAt'] != null
          ? DateTime.tryParse(map['resolvedAt'].toString())
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtObligation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class SystemConfig {
  final String activeKeeperId;
  final double currentRatePerSwear;
  final String groupName;
  final int totalSwearsAllTime;
  final DateTime updatedAt;

  const SystemConfig({
    required this.activeKeeperId,
    this.currentRatePerSwear = 50.0,
    this.groupName = 'Our Friend Group',
    this.totalSwearsAllTime = 0,
    required this.updatedAt,
  });

  SystemConfig copyWith({
    String? activeKeeperId,
    double? currentRatePerSwear,
    String? groupName,
    int? totalSwearsAllTime,
    DateTime? updatedAt,
  }) {
    return SystemConfig(
      activeKeeperId: activeKeeperId ?? this.activeKeeperId,
      currentRatePerSwear: currentRatePerSwear ?? this.currentRatePerSwear,
      groupName: groupName ?? this.groupName,
      totalSwearsAllTime: totalSwearsAllTime ?? this.totalSwearsAllTime,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activeKeeperId': activeKeeperId,
      'currentRatePerSwear': currentRatePerSwear,
      'groupName': groupName,
      'totalSwearsAllTime': totalSwearsAllTime,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SystemConfig.fromMap(Map<String, dynamic> map) {
    return SystemConfig(
      activeKeeperId: map['activeKeeperId'] as String? ?? '',
      currentRatePerSwear:
          (map['currentRatePerSwear'] as num?)?.toDouble() ?? 50.0,
      groupName: map['groupName'] as String? ?? 'Our Friend Group',
      totalSwearsAllTime: (map['totalSwearsAllTime'] as num?)?.toInt() ?? 0,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
