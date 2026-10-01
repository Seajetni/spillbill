import 'package:flutter/material.dart';

class Member {
  final String id;
  final String name;
  final String avatarEmoji;
  final Color avatarColor;
  final bool isCurrentUser;
  final String? promptPayNumber;
  final String? bankName;

  const Member({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    required this.avatarColor,
    this.isCurrentUser = false,
    this.promptPayNumber,
    this.bankName,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'avatarEmoji': avatarEmoji,
    'avatarColor': avatarColor.toARGB32(),
    'isCurrentUser': isCurrentUser,
    'promptPayNumber': promptPayNumber,
    'bankName': bankName,
  };

  factory Member.fromMap(Map<String, dynamic> map) => Member(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? '',
    avatarEmoji: map['avatarEmoji'] as String? ?? '👤',
    avatarColor: Color(map['avatarColor'] as int? ?? 0xFF2D6BFF),
    isCurrentUser: map['isCurrentUser'] as bool? ?? false,
    promptPayNumber: map['promptPayNumber'] as String?,
    bankName: map['bankName'] as String?,
  );
}

enum SplitMode {
  equal,
  itemized,
}

enum RoundingStrategy {
  payerAbsorbs, // คนสำรองจ่ายรับผิดชอบเศษสตางค์
  distributeEvenly, // กระจายเศษ 1 สตางค์ตามลำดับ
  roundToBaht, // ปัดเป็นจำนวนเต็มบาท (ไม่มีเศษสตางค์)
}

class BillItem {
  final String id;
  String name;
  double price;
  int quantity;
  List<String> assignedMemberIds;
  bool hasWarning;
  String? warningMessage;

  BillItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    List<String>? assignedMemberIds,
    this.hasWarning = false,
    this.warningMessage,
  }) : assignedMemberIds = assignedMemberIds ?? [];

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'price': price,
    'quantity': quantity,
    'assignedMemberIds': assignedMemberIds,
    'hasWarning': hasWarning,
    'warningMessage': warningMessage,
  };

  factory BillItem.fromMap(Map<String, dynamic> map) => BillItem(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? '',
    price: (map['price'] as num?)?.toDouble() ?? 0.0,
    quantity: map['quantity'] as int? ?? 1,
    assignedMemberIds: (map['assignedMemberIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    hasWarning: map['hasWarning'] as bool? ?? false,
    warningMessage: map['warningMessage'] as String?,
  );

  BillItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    List<String>? assignedMemberIds,
    bool? hasWarning,
    String? warningMessage,
  }) {
    return BillItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      assignedMemberIds: assignedMemberIds ?? List.from(this.assignedMemberIds),
      hasWarning: hasWarning ?? this.hasWarning,
      warningMessage: warningMessage ?? this.warningMessage,
    );
  }
}

class Bill {
  String id;
  String title;
  String categoryEmoji;
  DateTime date;
  List<BillItem> items;
  double vatPercent; // e.g. 7.0
  double serviceChargePercent; // e.g. 10.0
  double discountAmount;
  String paidByMemberId;
  SplitMode splitMode;
  String groupName;
  bool isSettled;
  List<String> participantMemberIds;
  RoundingStrategy roundingStrategy;
  String? pennyPayerMemberId;

  Bill({
    required this.id,
    required this.title,
    required this.categoryEmoji,
    required this.date,
    required this.items,
    this.vatPercent = 7.0,
    this.serviceChargePercent = 10.0,
    this.discountAmount = 0.0,
    required this.paidByMemberId,
    this.splitMode = SplitMode.itemized,
    required this.groupName,
    this.isSettled = false,
    List<String>? participantMemberIds,
    this.roundingStrategy = RoundingStrategy.payerAbsorbs,
    this.pennyPayerMemberId,
  }) : participantMemberIds = participantMemberIds ?? [];

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get vatAmount => (subtotal - discountAmount > 0) ? (subtotal - discountAmount) * (vatPercent / 100.0) : 0.0;
  double get serviceChargeAmount => (subtotal > 0) ? subtotal * (serviceChargePercent / 100.0) : 0.0;
  double get grandTotal => (subtotal - discountAmount + vatAmount + serviceChargeAmount);

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'categoryEmoji': categoryEmoji,
    'date': date.toIso8601String(),
    'items': items.map((i) => i.toMap()).toList(),
    'vatPercent': vatPercent,
    'serviceChargePercent': serviceChargePercent,
    'discountAmount': discountAmount,
    'paidByMemberId': paidByMemberId,
    'splitMode': splitMode.name,
    'groupName': groupName,
    'isSettled': isSettled,
    'participantMemberIds': participantMemberIds,
    'roundingStrategy': roundingStrategy.name,
    'pennyPayerMemberId': pennyPayerMemberId,
  };

  factory Bill.fromMap(Map<String, dynamic> map) => Bill(
    id: map['id'] as String? ?? '',
    title: map['title'] as String? ?? '',
    categoryEmoji: map['categoryEmoji'] as String? ?? '🧾',
    date: map['date'] != null ? DateTime.tryParse(map['date'] as String) ?? DateTime.now() : DateTime.now(),
    items: (map['items'] as List<dynamic>?)
            ?.map((e) => BillItem.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
    vatPercent: (map['vatPercent'] as num?)?.toDouble() ?? 7.0,
    serviceChargePercent: (map['serviceChargePercent'] as num?)?.toDouble() ?? 10.0,
    discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
    paidByMemberId: map['paidByMemberId'] as String? ?? '',
    splitMode: SplitMode.values.firstWhere(
      (e) => e.name == map['splitMode'],
      orElse: () => SplitMode.itemized,
    ),
    groupName: map['groupName'] as String? ?? '',
    isSettled: map['isSettled'] as bool? ?? false,
    participantMemberIds: (map['participantMemberIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    roundingStrategy: RoundingStrategy.values.firstWhere(
      (e) => e.name == map['roundingStrategy'],
      orElse: () => RoundingStrategy.payerAbsorbs,
    ),
    pennyPayerMemberId: map['pennyPayerMemberId'] as String?,
  );

  Bill copyWith({
    String? id,
    String? title,
    String? categoryEmoji,
    DateTime? date,
    List<BillItem>? items,
    double? vatPercent,
    double? serviceChargePercent,
    double? discountAmount,
    String? paidByMemberId,
    SplitMode? splitMode,
    String? groupName,
    bool? isSettled,
    List<String>? participantMemberIds,
    RoundingStrategy? roundingStrategy,
    String? pennyPayerMemberId,
  }) {
    return Bill(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryEmoji: categoryEmoji ?? this.categoryEmoji,
      date: date ?? this.date,
      items: items ?? this.items,
      vatPercent: vatPercent ?? this.vatPercent,
      serviceChargePercent: serviceChargePercent ?? this.serviceChargePercent,
      discountAmount: discountAmount ?? this.discountAmount,
      paidByMemberId: paidByMemberId ?? this.paidByMemberId,
      splitMode: splitMode ?? this.splitMode,
      groupName: groupName ?? this.groupName,
      isSettled: isSettled ?? this.isSettled,
      participantMemberIds: participantMemberIds ?? List.from(this.participantMemberIds),
      roundingStrategy: roundingStrategy ?? this.roundingStrategy,
      pennyPayerMemberId: pennyPayerMemberId ?? this.pennyPayerMemberId,
    );
  }
}

class DebtRecord {
  final String id;
  final Member fromMember;
  final Member toMember;
  double amount;
  final String billTitle;
  final int daysOverdue;
  bool isSettled;
  final String? note;

  DebtRecord({
    required this.id,
    required this.fromMember,
    required this.toMember,
    required this.amount,
    required this.billTitle,
    required this.daysOverdue,
    this.isSettled = false,
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'fromMember': fromMember.toMap(),
    'toMember': toMember.toMap(),
    'amount': amount,
    'billTitle': billTitle,
    'daysOverdue': daysOverdue,
    'isSettled': isSettled,
    'note': note,
  };

  factory DebtRecord.fromMap(Map<String, dynamic> map) => DebtRecord(
    id: map['id'] as String? ?? '',
    fromMember: Member.fromMap(map['fromMember'] as Map<String, dynamic>? ?? {}),
    toMember: Member.fromMap(map['toMember'] as Map<String, dynamic>? ?? {}),
    amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    billTitle: map['billTitle'] as String? ?? '',
    daysOverdue: map['daysOverdue'] as int? ?? 0,
    isSettled: map['isSettled'] as bool? ?? false,
    note: map['note'] as String?,
  );
}

class GroupModel {
  final String id;
  final String name;
  final String category; // 'บ้าน', 'ทริป', 'กิน', 'งาน'
  final String emoji;
  final List<Member> members;
  final List<String> billIds;
  final double userBalance; // positive = to receive, negative = to pay, 0 = settled

  const GroupModel({
    required this.id,
    required this.name,
    required this.category,
    required this.emoji,
    required this.members,
    required this.billIds,
    required this.userBalance,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'emoji': emoji,
    'members': members.map((m) => m.toMap()).toList(),
    'billIds': billIds,
    'userBalance': userBalance,
  };

  factory GroupModel.fromMap(Map<String, dynamic> map) => GroupModel(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? '',
    category: map['category'] as String? ?? 'กิน',
    emoji: map['emoji'] as String? ?? '👥',
    members: (map['members'] as List<dynamic>?)
            ?.map((e) => Member.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
    billIds: (map['billIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    userBalance: (map['userBalance'] as num?)?.toDouble() ?? 0.0,
  );
}

enum EscalationLadder {
  gentle, // 🟢 สะกิดเบา ๆ
  normal, // 🟡 เตือนปกติ
  serious, // 🟠 จริงจัง
  sarcastic, // 🔴 โหมดประชด
}

class VoiceNudgeData {
  final String id;
  final Member targetMember;
  final double amount;
  final String billTitle;
  final int daysOverdue;
  final String mode; // 'self', 'ai', 'library'
  final String persona; // 'น้องนุ่ม', 'เพื่อนซี้', 'หุ่นยนต์', 'คุณยาย', 'ผู้ประกาศ'
  final String soundEffect; // 'ปกติ', 'ชิพมังก์', 'ทุ้มลึก', 'วิทยุเก่า', 'ห้องโถง'
  final String transcript;
  final int durationSeconds;
  final EscalationLadder ladder;
  final String? audioPath;
  bool isSent;

  VoiceNudgeData({
    required this.id,
    required this.targetMember,
    required this.amount,
    required this.billTitle,
    required this.daysOverdue,
    required this.mode,
    required this.persona,
    this.soundEffect = 'ปกติ',
    required this.transcript,
    this.durationSeconds = 9,
    this.ladder = EscalationLadder.gentle,
    this.audioPath,
    this.isSent = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'targetMember': targetMember.toMap(),
    'amount': amount,
    'billTitle': billTitle,
    'daysOverdue': daysOverdue,
    'mode': mode,
    'persona': persona,
    'soundEffect': soundEffect,
    'transcript': transcript,
    'durationSeconds': durationSeconds,
    'ladder': ladder.name,
    'audioPath': audioPath,
    'isSent': isSent,
  };

  factory VoiceNudgeData.fromMap(Map<String, dynamic> map) => VoiceNudgeData(
    id: map['id'] as String? ?? '',
    targetMember: Member.fromMap(map['targetMember'] as Map<String, dynamic>? ?? {}),
    amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    billTitle: map['billTitle'] as String? ?? '',
    daysOverdue: map['daysOverdue'] as int? ?? 0,
    mode: map['mode'] as String? ?? 'ai',
    persona: map['persona'] as String? ?? 'น้องนุ่ม',
    soundEffect: map['soundEffect'] as String? ?? 'ปกติ',
    transcript: map['transcript'] as String? ?? '',
    durationSeconds: map['durationSeconds'] as int? ?? 9,
    ladder: EscalationLadder.values.firstWhere(
      (e) => e.name == map['ladder'],
      orElse: () => EscalationLadder.gentle,
    ),
    audioPath: map['audioPath'] as String?,
    isSent: map['isSent'] as bool? ?? false,
  );
}

class RecentActivity {
  final String id;
  final String title;
  final String subtitle;
  final double? amount;
  final String emoji;
  final DateTime timestamp;

  const RecentActivity({
    required this.id,
    required this.title,
    required this.subtitle,
    this.amount,
    required this.emoji,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'amount': amount,
    'emoji': emoji,
    'timestamp': timestamp.toIso8601String(),
  };

  factory RecentActivity.fromMap(Map<String, dynamic> map) => RecentActivity(
    id: map['id'] as String? ?? '',
    title: map['title'] as String? ?? '',
    subtitle: map['subtitle'] as String? ?? '',
    amount: (map['amount'] as num?)?.toDouble(),
    emoji: map['emoji'] as String? ?? '🧾',
    timestamp: map['timestamp'] != null
        ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}

enum NotificationType {
  payment,
  overdue,
  newBill,
  system,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String emoji;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;
  final String? relatedAction; // e.g. 'nudge', 'pay', 'view_bill'

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.emoji,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.relatedAction,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'message': message,
    'emoji': emoji,
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'isRead': isRead,
    'relatedAction': relatedAction,
  };

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
    id: map['id'] as String? ?? '',
    title: map['title'] as String? ?? '',
    message: map['message'] as String? ?? '',
    emoji: map['emoji'] as String? ?? '🔔',
    timestamp: map['timestamp'] != null
        ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
        : DateTime.now(),
    type: NotificationType.values.firstWhere(
      (e) => e.name == map['type'],
      orElse: () => NotificationType.system,
    ),
    isRead: map['isRead'] as bool? ?? false,
    relatedAction: map['relatedAction'] as String?,
  );
}

class GroupBill {
  final String id;
  final String title;
  final double totalAmount;
  final String paidByName;
  final DateTime date;
  final int memberCount;

  const GroupBill({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.paidByName,
    required this.date,
    required this.memberCount,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'totalAmount': totalAmount,
    'paidByName': paidByName,
    'date': date.toIso8601String(),
    'memberCount': memberCount,
  };

  factory GroupBill.fromMap(Map<String, dynamic> map) => GroupBill(
    id: map['id'] as String? ?? '',
    title: map['title'] as String? ?? '',
    totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
    paidByName: map['paidByName'] as String? ?? '',
    date: map['date'] != null
        ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
        : DateTime.now(),
    memberCount: map['memberCount'] as int? ?? 1,
  );
}

class BankAccountItem {
  final String id;
  String bankName;
  String accountNumber;
  Color brandColor;
  bool isPrimary;

  BankAccountItem({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.brandColor,
    this.isPrimary = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'brandColor': brandColor.toARGB32(),
    'isPrimary': isPrimary,
  };

  factory BankAccountItem.fromMap(Map<String, dynamic> map) => BankAccountItem(
    id: map['id'] as String? ?? '',
    bankName: map['bankName'] as String? ?? '',
    accountNumber: map['accountNumber'] as String? ?? '',
    brandColor: Color(map['brandColor'] as int? ?? 0xFF138F2D),
    isPrimary: map['isPrimary'] as bool? ?? false,
  );
}
