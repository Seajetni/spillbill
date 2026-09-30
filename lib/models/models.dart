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
}


