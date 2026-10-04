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
  final String? authUid;
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
    this.authUid,
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
  bool get hasLinkedAccount =>
      (authUid != null && authUid!.isNotEmpty) || email.isNotEmpty;

  AppUser copyWith({
    String? id,
    String? authUid,
    bool clearAuthUid = false,
    String? email,
    String? displayName,
    String? photoUrl,
    bool clearPhotoUrl = false,
    String? gcashNumber,
    List<UserRole>? roles,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      authUid: clearAuthUid ? null : (authUid ?? this.authUid),
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
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
      'authUid': authUid,
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
    final resolvedId = id ?? map['id'] as String? ?? '';
    final resolvedEmail = map['email'] as String? ?? '';
    final String? resolvedAuthUid;
    if (map.containsKey('authUid')) {
      final rawAuthUid = map['authUid'] as String?;
      resolvedAuthUid =
          (rawAuthUid != null && rawAuthUid.isNotEmpty) ? rawAuthUid : null;
    } else {
      // Backward compatibility for existing users created before authUid was added
      resolvedAuthUid = resolvedEmail.isNotEmpty ? resolvedId : null;
    }

    return AppUser(
      id: resolvedId,
      authUid: resolvedAuthUid,
      email: resolvedEmail,
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
  final Map<String, int> swearBreakdown;
  final double rateApplied;
  final double compensationApplied;
  final double totalAmount;
  final ReportStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime swearDate;
  final DateTime createdAt;

  SwearReport({
    required this.id,
    required this.reporterId,
    required this.accusedId,
    required this.count,
    this.note,
    this.swearBreakdown = const {},
    required this.rateApplied,
    this.compensationApplied = 0.0,
    required this.totalAmount,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    DateTime? swearDate,
    required this.createdAt,
  }) : swearDate = swearDate ?? createdAt;

  bool get isPending => status == ReportStatus.pending;
  bool get isConfirmed => status == ReportStatus.confirmed;
  bool get isRejected => status == ReportStatus.rejected;

  /// Total reporter compensation for this report (`count × compensationApplied`), capped at `totalAmount`.
  double get totalCompensation =>
      (count * compensationApplied).clamp(0.0, totalAmount);

  SwearReport copyWith({
    String? id,
    String? reporterId,
    String? accusedId,
    int? count,
    String? note,
    bool clearNote = false,
    Map<String, int>? swearBreakdown,
    double? rateApplied,
    double? compensationApplied,
    double? totalAmount,
    ReportStatus? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
    DateTime? swearDate,
    DateTime? createdAt,
  }) {
    return SwearReport(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      accusedId: accusedId ?? this.accusedId,
      count: count ?? this.count,
      note: clearNote ? null : (note ?? this.note),
      swearBreakdown: swearBreakdown ?? Map<String, int>.from(this.swearBreakdown),
      rateApplied: rateApplied ?? this.rateApplied,
      compensationApplied: compensationApplied ?? this.compensationApplied,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      swearDate: swearDate ?? this.swearDate,
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
      'swearBreakdown': swearBreakdown,
      'rateApplied': rateApplied,
      'compensationApplied': compensationApplied,
      'totalAmount': totalAmount,
      'status': status.toStr(),
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'swearDate': swearDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SwearReport.fromMap(Map<String, dynamic> map, {String? id}) {
    final countVal = (map['count'] as num?)?.toInt() ?? 1;
    final rateVal = (map['rateApplied'] as num?)?.toDouble() ?? 50.0;
    final compensationVal =
        (map['compensationApplied'] as num?)?.toDouble() ?? 0.0;
    final totalVal =
        (map['totalAmount'] as num?)?.toDouble() ?? (countVal * rateVal);
    final parsedCreatedAt = map['createdAt'] != null
        ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
        : DateTime.now();
    final parsedSwearDate = map['swearDate'] != null
        ? DateTime.tryParse(map['swearDate'].toString()) ?? parsedCreatedAt
        : parsedCreatedAt;

    final rawBreakdown = map['swearBreakdown'];
    final parsedBreakdown = <String, int>{};
    if (rawBreakdown is Map) {
      rawBreakdown.forEach((key, value) {
        final k = key.toString().trim();
        final v = (value as num?)?.toInt() ?? 0;
        if (k.isNotEmpty && v > 0) {
          parsedBreakdown[k] = v;
        }
      });
    }

    return SwearReport(
      id: id ?? map['id'] as String? ?? '',
      reporterId: map['reporterId'] as String? ?? '',
      accusedId: map['accusedId'] as String? ?? '',
      count: countVal,
      note: map['note'] as String?,
      swearBreakdown: parsedBreakdown,
      rateApplied: rateVal,
      compensationApplied: compensationVal,
      totalAmount: totalVal,
      status: ReportStatus.fromString(map['status'] as String? ?? 'pending'),
      reviewedBy: map['reviewedBy'] as String?,
      reviewedAt: map['reviewedAt'] != null
          ? DateTime.tryParse(map['reviewedAt'].toString())
          : null,
      rejectionReason: map['rejectionReason'] as String?,
      swearDate: parsedSwearDate,
      createdAt: parsedCreatedAt,
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

  /// Actual payment amount collected toward this obligation (excluding Keeper-swear auto-offsets, reporter compensation offsets, and dismissed write-offs).
  double get collectedAmount {
    final maxPossible =
        (originalAmount - remainingBalance).clamp(0.0, originalAmount);
    if (payments.isEmpty) {
      return isDismissed ? 0.0 : maxPossible;
    }

    final realPayments = payments
        .where(
          (p) =>
              p.recordedBy != 'SYSTEM_KEEPER_SWEAR_OFFSET' &&
              p.recordedBy != 'SYSTEM_REPORTER_COMPENSATION_OFFSET',
        )
        .toList();
    if (realPayments.isEmpty) return 0.0;

    final effectivePayments = isDismissed && realPayments.isNotEmpty
        ? realPayments.sublist(0, realPayments.length - 1)
        : realPayments;

    final sum = effectivePayments.fold<double>(0.0, (acc, p) => acc + p.amount);
    return sum.clamp(0.0, maxPossible);
  }

  bool get isPartiallyPaid =>
      isActive && collectedAmount > 0.001 && remainingBalance > 0.001;

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

class MemberLedgerSummary {
  final String debtorId;
  final String recipientId;
  final bool isTransferred;
  final double totalIncurred;
  final double collectedAlready;
  final double toBeReceived;
  final List<DebtObligation> debts;
  final DateTime? lastActivityAt;

  const MemberLedgerSummary({
    required this.debtorId,
    required this.recipientId,
    this.isTransferred = false,
    required this.totalIncurred,
    required this.collectedAlready,
    required this.toBeReceived,
    this.debts = const [],
    this.lastActivityAt,
  });

  List<DebtObligation> get activeDebts =>
      debts.where((d) => d.isActive && d.remainingBalance > 0.001).toList();

  bool get hasActiveBalance => toBeReceived > 0.001;
  bool get isPartiallyPaid =>
      toBeReceived > 0.001 && collectedAlready > 0.001;
  bool get isSettled => toBeReceived <= 0.001 && collectedAlready > 0.001;

  double get collectionProgress {
    final denom = collectedAlready + toBeReceived;
    if (denom <= 0.001) return 0.0;
    return (collectedAlready / denom).clamp(0.0, 1.0);
  }
}

class PaymentHistoryItem {
  final String id;
  final List<String> paymentIds;
  final String debtorId;
  final String recipientId;
  final double amount;
  final String recordedBy;
  final DateTime recordedAt;
  final String? note;
  final bool isPartial;

  const PaymentHistoryItem({
    required this.id,
    this.paymentIds = const [],
    required this.debtorId,
    required this.recipientId,
    required this.amount,
    required this.recordedBy,
    required this.recordedAt,
    this.note,
    this.isPartial = false,
  });
}

class SwearLanguage {
  final String id;
  final String name;
  final List<String> swears;

  const SwearLanguage({
    required this.id,
    required this.name,
    this.swears = const [],
  });

  SwearLanguage copyWith({
    String? id,
    String? name,
    List<String>? swears,
  }) {
    return SwearLanguage(
      id: id ?? this.id,
      name: name ?? this.name,
      swears: swears ?? List<String>.from(this.swears),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'swears': swears,
    };
  }

  factory SwearLanguage.fromMap(Map<String, dynamic> map) {
    final rawSwears = map['swears'];
    final parsedSwears = <String>[];
    if (rawSwears is List) {
      for (final item in rawSwears) {
        final s = item.toString().trim();
        if (s.isNotEmpty && !parsedSwears.contains(s)) {
          parsedSwears.add(s);
        }
      }
    }
    final nameStr = map['name'] as String? ?? 'Language';
    return SwearLanguage(
      id: map['id'] as String? ?? nameStr.toLowerCase().replaceAll(' ', '_'),
      name: nameStr,
      swears: parsedSwears,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SwearLanguage || runtimeType != other.runtimeType) {
      return false;
    }
    if (id != other.id ||
        name != other.name ||
        swears.length != other.swears.length) {
      return false;
    }
    for (var i = 0; i < swears.length; i++) {
      if (swears[i] != other.swears[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, name, Object.hashAll(swears));
}

class SystemConfig {
  final String activeKeeperId;
  final double currentRatePerSwear;
  final double currentCompensationPerSwear;
  final String groupName;
  final int totalSwearsAllTime;
  final List<SwearLanguage> swearLanguages;
  final DateTime updatedAt;

  const SystemConfig({
    required this.activeKeeperId,
    this.currentRatePerSwear = 50.0,
    this.currentCompensationPerSwear = 0.0,
    this.groupName = 'Our Friend Group',
    this.totalSwearsAllTime = 0,
    this.swearLanguages = const [],
    required this.updatedAt,
  });

  SystemConfig copyWith({
    String? activeKeeperId,
    double? currentRatePerSwear,
    double? currentCompensationPerSwear,
    String? groupName,
    int? totalSwearsAllTime,
    List<SwearLanguage>? swearLanguages,
    DateTime? updatedAt,
  }) {
    return SystemConfig(
      activeKeeperId: activeKeeperId ?? this.activeKeeperId,
      currentRatePerSwear: currentRatePerSwear ?? this.currentRatePerSwear,
      currentCompensationPerSwear:
          currentCompensationPerSwear ?? this.currentCompensationPerSwear,
      groupName: groupName ?? this.groupName,
      totalSwearsAllTime: totalSwearsAllTime ?? this.totalSwearsAllTime,
      swearLanguages:
          swearLanguages ?? List<SwearLanguage>.from(this.swearLanguages),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activeKeeperId': activeKeeperId,
      'currentRatePerSwear': currentRatePerSwear,
      'currentCompensationPerSwear': currentCompensationPerSwear,
      'groupName': groupName,
      'totalSwearsAllTime': totalSwearsAllTime,
      'swearLanguages': swearLanguages.map((l) => l.toMap()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SystemConfig.fromMap(Map<String, dynamic> map) {
    final rawLanguages = map['swearLanguages'];
    final parsedLanguages = <SwearLanguage>[];
    if (rawLanguages is List) {
      for (final item in rawLanguages) {
        if (item is Map) {
          parsedLanguages.add(
            SwearLanguage.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return SystemConfig(
      activeKeeperId: map['activeKeeperId'] as String? ?? '',
      currentRatePerSwear:
          (map['currentRatePerSwear'] as num?)?.toDouble() ?? 50.0,
      currentCompensationPerSwear:
          (map['currentCompensationPerSwear'] as num?)?.toDouble() ?? 0.0,
      groupName: map['groupName'] as String? ?? 'Our Friend Group',
      totalSwearsAllTime: (map['totalSwearsAllTime'] as num?)?.toInt() ?? 0,
      swearLanguages: parsedLanguages,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SwearPersonStat {
  final String userId;
  final int swearCount;
  final int reportCount;
  final double totalAmount;
  final double shareOfSwears;

  const SwearPersonStat({
    required this.userId,
    required this.swearCount,
    required this.reportCount,
    required this.totalAmount,
    required this.shareOfSwears,
  });
}

class SwearWordStat {
  final String word;
  final int count;
  final double shareOfWords;
  final bool isUnspecified;

  const SwearWordStat({
    required this.word,
    required this.count,
    required this.shareOfWords,
    this.isUnspecified = false,
  });
}

class ReportAnalyticsSummary {
  final int totalSwears;
  final int totalReports;
  final double totalPenaltyAmount;
  final List<SwearPersonStat> peopleStats;
  final List<SwearWordStat> wordStats;

  const ReportAnalyticsSummary({
    required this.totalSwears,
    required this.totalReports,
    required this.totalPenaltyAmount,
    this.peopleStats = const [],
    this.wordStats = const [],
  });
}

