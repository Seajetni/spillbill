import 'package:flutter/material.dart';
import '../models/models.dart';

class SplitBillProvider extends ChangeNotifier {
  // Current logged in user profile fields
  String userName = 'ป๊อป';
  String userAvatarEmoji = '🔵';
  String userPromptPay = '081-234-5678';
  String userBank = 'ธนาคารกสิกรไทย (KBank)';
  String userBankAccountNumber = '123-4-56789-0';

  Member get currentUser => Member(
    id: 'm_pop',
    name: userName,
    avatarEmoji: userAvatarEmoji,
    avatarColor: const Color(0xFF2D6BFF),
    isCurrentUser: true,
    promptPayNumber: userPromptPay,
    bankName: userBank,
  );

  // Bank accounts
  List<BankAccountItem> bankAccounts = [];

  // Notification settings
  bool pushEnabled = true;
  bool billDueReminder = true;
  bool weeklySummary = true;
  bool soundAndVibration = true;

  // Voice Nudge settings
  bool allowVoiceNudge = true;
  bool quietHoursEnabled = true;
  String defaultPersona = 'น้องนุ่ม';
  String defaultEffect = 'ปกติ';

  // General app preferences
  String appLanguage = 'ไทย';
  String appCurrency = 'THB (฿)';

  // Group members
  late List<Member> allMembers;

  // Active debts
  List<DebtRecord> debts = [];

  // Groups
  List<GroupModel> groups = [];

  // Group Bills mapping (groupId -> List<GroupBill>)
  Map<String, List<GroupBill>> groupBills = {};

  // Notifications
  List<AppNotification> notifications = [];

  int get unreadNotificationsCount => notifications.where((n) => !n.isRead).length;

  // Recent activities
  List<RecentActivity> activities = [];

  // Active Voice Nudges
  List<VoiceNudgeData> voiceNudges = [];

  // Draft Bill being edited or created
  Bill? currentDraftBill;

  // Saved bills history
  List<Bill> savedBills = [];

  // OCR Processing Simulation State
  bool isOcrProcessing = false;
  int ocrProgressCurrent = 0;
  int ocrProgressTotal = 7;

  // Active filter on Home Screen
  String homeFilter = 'all'; // 'all', 'receive', 'pay'

  // Selected Group Category filter
  String groupCategoryFilter = 'ทั้งหมด';

  SplitBillProvider() {
    _initData();
  }

  void _initData() {
    bankAccounts = [
      BankAccountItem(
        id: 'ba_kbank',
        bankName: 'ธนาคารกสิกรไทย (KBank)',
        accountNumber: '123-4-56789-0',
        brandColor: const Color(0xFF138F2D),
        isPrimary: true,
      ),
      BankAccountItem(
        id: 'ba_scb',
        bankName: 'ธนาคารไทยพาณิชย์ (SCB)',
        accountNumber: '987-6-54321-0',
        brandColor: const Color(0xFF4E2E80),
        isPrimary: false,
      ),
      BankAccountItem(
        id: 'ba_ttb',
        bankName: 'ธนาคารทหารไทยธนชาต (ttb)',
        accountNumber: '456-7-89012-3',
        brandColor: const Color(0xFF0056B3),
        isPrimary: false,
      ),
    ];

    allMembers = [
      currentUser,
      const Member(
        id: 'm_beer',
        name: 'เบียร์',
        avatarEmoji: '🟢',
        avatarColor: Color(0xFF0FBF7F),
        promptPayNumber: '0891112233',
        bankName: 'ธนาคารกสิกรไทย',
      ),
      const Member(
        id: 'm_nut',
        name: 'นัท',
        avatarEmoji: '🟠',
        avatarColor: Color(0xFFFF8A3D),
        promptPayNumber: '0864445566',
        bankName: 'ธนาคารไทยพาณิชย์',
      ),
      const Member(
        id: 'm_mint',
        name: 'มิ้นท์',
        avatarEmoji: '🟣',
        avatarColor: Color(0xFFA855F7),
        promptPayNumber: '0857778899',
        bankName: 'ธนาคารกรุงเทพ',
      ),
      const Member(
        id: 'm_tae',
        name: 'เต้',
        avatarEmoji: '🩷',
        avatarColor: Color(0xFFEC4899),
        promptPayNumber: '0823334455',
        bankName: 'ธนาคารทหารไทยธนชาต',
      ),
    ];

    debts = [
      DebtRecord(
        id: 'd_1',
        fromMember: allMembers[2], // นัท
        toMember: currentUser,
        amount: 450.0,
        billTitle: '🍜 ทริปเชียงใหม่',
        daysOverdue: 4,
        note: 'ค่าที่พักและก๋วยเตี๋ยว',
      ),
      DebtRecord(
        id: 'd_2',
        fromMember: currentUser,
        toMember: allMembers[3], // มิ้นท์
        amount: 310.0,
        billTitle: '🏠 ค่าเน็ตคอนโด',
        daysOverdue: 0,
        note: 'ครบกำหนดพรุ่งนี้',
      ),
      DebtRecord(
        id: 'd_3',
        fromMember: allMembers[1], // เบียร์
        toMember: currentUser,
        amount: 241.30,
        billTitle: '🍜 หมูกระทะ ศุกร์',
        daysOverdue: 1,
      ),
      DebtRecord(
        id: 'd_4',
        fromMember: allMembers[2], // นัท
        toMember: currentUser,
        amount: 200.30,
        billTitle: '🍜 หมูกระทะ ศุกร์',
        daysOverdue: 1,
        note: 'ปรับลดหนี้อัตโนมัติ ฿45 จากบิลก่อน (เดิม ฿245.30)',
      ),
      DebtRecord(
        id: 'd_5',
        fromMember: allMembers[3], // มิ้นท์
        toMember: currentUser,
        amount: 88.0,
        billTitle: '🍜 หมูกระทะ ศุกร์',
        daysOverdue: 1,
      ),
    ];

    groups = [
      GroupModel(
        id: 'g_trip',
        name: 'ทริปเชียงใหม่',
        category: 'ทริป',
        emoji: '✈️',
        members: [allMembers[0], allMembers[1], allMembers[2], allMembers[3], allMembers[4]],
        billIds: ['b_1', 'b_2', 'b_3', 'b_4', 'b_5', 'b_6', 'b_7', 'b_8'],
        userBalance: 450.0,
      ),
      GroupModel(
        id: 'g_condo',
        name: 'คอนโดอารีย์',
        category: 'บ้าน',
        emoji: '🏠',
        members: [allMembers[0], allMembers[3]],
        billIds: ['b_net'],
        userBalance: -310.0,
      ),
      GroupModel(
        id: 'g_lunch',
        name: 'ก๊วนกินข้าวเที่ยง',
        category: 'กิน',
        emoji: '🍽',
        members: [allMembers[0], allMembers[1], allMembers[2], allMembers[4]],
        billIds: ['b_l1', 'b_l2'],
        userBalance: 0.0, // เคลียร์แล้ว
      ),
      GroupModel(
        id: 'g_work',
        name: 'กองกลางทีมโปรเจกต์',
        category: 'งาน',
        emoji: '💼',
        members: [allMembers[0], allMembers[2], allMembers[3]],
        billIds: ['b_w1'],
        userBalance: 1100.0,
      ),
    ];

    activities = [
      RecentActivity(
        id: 'a_1',
        title: 'เบียร์ จ่ายแล้ว',
        subtitle: 'โอนผ่าน PromptPay ยืนยันสลิปแล้ว',
        amount: 245.0,
        emoji: '🟢',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      RecentActivity(
        id: 'a_2',
        title: 'มิ้นท์ เพิ่มบิลใหม่',
        subtitle: 'ค่าเน็ตคอนโด เดือนกันยายน',
        amount: -180.0,
        emoji: '🟣',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      RecentActivity(
        id: 'a_3',
        title: 'นัท เข้าร่วมกลุ่ม',
        subtitle: 'ทริปเชียงใหม่',
        emoji: '🟠',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    notifications = [
      AppNotification(
        id: 'notif_1',
        title: 'เบียร์ ชำระเงินแล้ว 💸',
        message: 'โอนค่า 🍜 หมูกระทะ ศุกร์ ฿241.30 เข้าพร้อมเพย์ของคุณแล้ว แตะเพื่อดูสลิป',
        emoji: '🟢',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        type: NotificationType.payment,
        isRead: false,
        relatedAction: 'view_payment',
      ),
      AppNotification(
        id: 'notif_2',
        title: 'ยอดค้างชำระเกินกำหนด ⚠️',
        message: 'นัท ยังไม่ได้ชำระ 🍜 ทริปเชียงใหม่ ฿450.00 (ค้างมา 4 วันแล้ว) แตะเพื่อส่งเสียงทวง',
        emoji: '🟠',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        type: NotificationType.overdue,
        isRead: false,
        relatedAction: 'nudge',
      ),
      AppNotification(
        id: 'notif_3',
        title: 'มิ้นท์ เพิ่มบิลใหม่ 🧾',
        message: '🏠 ค่าเน็ตคอนโด เดือนกันยายน ยอดรวม ฿620.00 (ส่วนของคุณ ฿310.00 ครบกำหนดพรุ่งนี้)',
        emoji: '🟣',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        type: NotificationType.newBill,
        isRead: false,
        relatedAction: 'pay',
      ),
    ];

    groupBills = {
      'g_trip': [
        GroupBill(
          id: 'gb_1',
          title: '🏡 ค่าที่พักม่อนแจ่ม 2 คืน',
          totalAmount: 3200.0,
          paidByName: 'ป๊อป',
          date: DateTime.now().subtract(const Duration(days: 4)),
          memberCount: 5,
        ),
        GroupBill(
          id: 'gb_2',
          title: '🍜 ค่าก๋วยเตี๋ยวเรือมื้อเที่ยง',
          totalAmount: 480.0,
          paidByName: 'เบียร์',
          date: DateTime.now().subtract(const Duration(days: 3)),
          memberCount: 5,
        ),
        GroupBill(
          id: 'gb_3',
          title: '🚐 ค่าน้ำมันรถตู้เชียงใหม่',
          totalAmount: 1500.0,
          paidByName: 'ป๊อป',
          date: DateTime.now().subtract(const Duration(days: 2)),
          memberCount: 5,
        ),
        GroupBill(
          id: 'gb_4',
          title: 'หมูกระทะ ศุกร์',
          totalAmount: 745.60,
          paidByName: 'ป๊อป',
          date: DateTime.now().subtract(const Duration(days: 1)),
          memberCount: 4,
        ),
      ],
      'g_condo': [
        GroupBill(
          id: 'gb_c1',
          title: '🌐 ค่าเน็ตคอนโด เดือนกันยายน',
          totalAmount: 620.0,
          paidByName: 'มิ้นท์',
          date: DateTime.now().subtract(const Duration(days: 1)),
          memberCount: 2,
        ),
        GroupBill(
          id: 'gb_c2',
          title: '💧 ค่าน้ำประปาและส่วนกลาง',
          totalAmount: 450.0,
          paidByName: 'ป๊อป',
          date: DateTime.now().subtract(const Duration(days: 10)),
          memberCount: 2,
        ),
      ],
      'g_lunch': [
        GroupBill(
          id: 'gb_l1',
          title: '🍛 ข้าวแกงกะหรี่ วันพุธ',
          totalAmount: 640.0,
          paidByName: 'ป๊อป',
          date: DateTime.now().subtract(const Duration(days: 7)),
          memberCount: 4,
        ),
      ],
      'g_work': [
        GroupBill(
          id: 'gb_w1',
          title: '☁️ ค่า Server Cloud & Domain',
          totalAmount: 1650.0,
          paidByName: 'ป๊อป',
          date: DateTime.now().subtract(const Duration(days: 5)),
          memberCount: 3,
        ),
      ],
    };

    // Seed default draft bill from sample receipt
    initDraftBillFromOcr();
    if (currentDraftBill != null) {
      savedBills.add(currentDraftBill!.copyWith());
    }
  }

  // Summary Calculations
  double get toReceiveAmount {
    return debts
        .where((d) => !d.isSettled && d.toMember.id == currentUser.id)
        .fold(0.0, (sum, d) => sum + d.amount);
  }

  double get toPayAmount {
    return debts
        .where((d) => !d.isSettled && d.fromMember.id == currentUser.id)
        .fold(0.0, (sum, d) => sum + d.amount);
  }

  double get netBalance => toReceiveAmount - toPayAmount;

  List<DebtRecord> get filteredDebts {
    if (homeFilter == 'receive') {
      return debts.where((d) => !d.isSettled && d.toMember.id == currentUser.id).toList();
    } else if (homeFilter == 'pay') {
      return debts.where((d) => !d.isSettled && d.fromMember.id == currentUser.id).toList();
    }
    return debts.where((d) => !d.isSettled).toList();
  }

  List<GroupModel> get filteredGroups {
    if (groupCategoryFilter == 'ทั้งหมด') {
      return groups;
    }
    return groups.where((g) => g.category == groupCategoryFilter).toList();
  }

  void setHomeFilter(String filter) {
    homeFilter = filter;
    notifyListeners();
  }

  void setGroupCategoryFilter(String category) {
    groupCategoryFilter = category;
    notifyListeners();
  }

  void markDebtSettled(String debtId) {
    final index = debts.indexWhere((d) => d.id == debtId);
    if (index != -1) {
      final settledDebt = debts[index];
      settledDebt.isSettled = true;
      activities.insert(
        0,
        RecentActivity(
          id: 'act_${DateTime.now().millisecondsSinceEpoch}',
          title: '${settledDebt.fromMember.name} จ่ายแล้ว',
          subtitle: settledDebt.billTitle,
          amount: settledDebt.amount,
          emoji: '🎉',
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  void initDraftBillFromOcr() {
    currentDraftBill = Bill(
      id: 'b_sample_ocr',
      title: 'หมูกระทะ ศุกร์',
      categoryEmoji: '🍜',
      date: DateTime.now(),
      vatPercent: 7.0,
      serviceChargePercent: 10.0,
      discountAmount: 50.0,
      paidByMemberId: currentUser.id,
      groupName: 'ทริปเชียงใหม่',
      participantMemberIds: [currentUser.id, 'm_beer', 'm_nut', 'm_mint'],
      items: [
        BillItem(
          id: 'item_1',
          name: 'ต้มยำกุ้งน้ำข้น',
          price: 280.0,
          quantity: 1,
          assignedMemberIds: [currentUser.id, 'm_beer'], // ป๊อป, เบียร์
        ),
        BillItem(
          id: 'item_2',
          name: 'ข้าวผัดปู',
          price: 180.0,
          quantity: 1,
          assignedMemberIds: ['m_nut'], // นัท
        ),
        BillItem(
          id: 'item_3',
          name: 'ส้มตำไทย',
          price: 120.0,
          quantity: 1,
          hasWarning: true,
          warningMessage: 'ตัวเลขไม่ชัดเจน กรุณาแตะตรวจสอบ',
          assignedMemberIds: ['m_beer', 'm_mint'], // เบียร์, มิ้นท์
        ),
        BillItem(
          id: 'item_4',
          name: 'ข้าวสวย',
          price: 10.0,
          quantity: 4,
          assignedMemberIds: [currentUser.id, 'm_beer', 'm_nut', 'm_mint'], // ทุกคน
        ),
        BillItem(
          id: 'item_5',
          name: 'น้ำเปล่า',
          price: 15.0,
          quantity: 4,
          hasWarning: true,
          warningMessage: 'ยอดเงินมีเครื่องหมายทับ',
          assignedMemberIds: [currentUser.id, 'm_beer', 'm_nut', 'm_mint'], // ทุกคน
        ),
      ],
    );
    notifyListeners();
  }

  void createBlankBill({String? groupName, String? title, String? categoryEmoji}) {
    final selectedGroupName = groupName ?? (groups.isNotEmpty ? groups.first.name : 'ทริปเชียงใหม่');
    final selectedGroup = groups.where((g) => g.name == selectedGroupName).firstOrNull;
    final initialParticipants = selectedGroup != null
        ? selectedGroup.members.map((m) => m.id).toList()
        : allMembers.map((m) => m.id).toList();

    currentDraftBill = Bill(
      id: 'b_${DateTime.now().millisecondsSinceEpoch}',
      title: title ?? '',
      categoryEmoji: categoryEmoji ?? '🍜',
      date: DateTime.now(),
      items: [],
      vatPercent: 7.0,
      serviceChargePercent: 0.0,
      discountAmount: 0.0,
      paidByMemberId: currentUser.id,
      groupName: selectedGroupName,
      splitMode: SplitMode.itemized,
      participantMemberIds: initialParticipants,
    );
    notifyListeners();
  }

  void duplicateBill(Bill sourceBill) {
    currentDraftBill = Bill(
      id: 'b_${DateTime.now().millisecondsSinceEpoch}',
      title: '${sourceBill.title} (ทำซ้ำ)',
      categoryEmoji: sourceBill.categoryEmoji,
      date: DateTime.now(),
      vatPercent: sourceBill.vatPercent,
      serviceChargePercent: sourceBill.serviceChargePercent,
      discountAmount: sourceBill.discountAmount,
      paidByMemberId: sourceBill.paidByMemberId,
      groupName: sourceBill.groupName,
      splitMode: sourceBill.splitMode,
      participantMemberIds: List.from(sourceBill.participantMemberIds),
      items: sourceBill.items
          .map(
            (it) => BillItem(
              id: 'item_${DateTime.now().millisecondsSinceEpoch}_${it.id}',
              name: it.name,
              price: it.price,
              quantity: it.quantity,
              assignedMemberIds: List.from(it.assignedMemberIds),
              hasWarning: false,
            ),
          )
          .toList(),
    );
    notifyListeners();
  }

  void duplicateLatestBill() {
    if (savedBills.isNotEmpty) {
      duplicateBill(savedBills.first);
    } else if (currentDraftBill != null) {
      duplicateBill(currentDraftBill!);
    } else {
      initDraftBillFromOcr();
    }
  }

  Member addNewMember({
    required String name,
    String avatarEmoji = '👤',
    Color avatarColor = const Color(0xFF6366F1),
    String? promptPayNumber,
    String? bankName,
  }) {
    final newMember = Member(
      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      avatarEmoji: avatarEmoji,
      avatarColor: avatarColor,
      promptPayNumber: promptPayNumber,
      bankName: bankName,
    );
    allMembers.add(newMember);
    if (currentDraftBill != null) {
      if (!currentDraftBill!.participantMemberIds.contains(newMember.id)) {
        currentDraftBill!.participantMemberIds.add(newMember.id);
      }
    }
    notifyListeners();
    return newMember;
  }

  Member? getMemberById(String id) {
    try {
      return allMembers.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Member> getDraftBillParticipants() {
    if (currentDraftBill == null) return allMembers;
    final bill = currentDraftBill!;
    if (bill.participantMemberIds.isEmpty) {
      final group = groups.where((g) => g.name == bill.groupName).firstOrNull;
      if (group != null && group.members.isNotEmpty) {
        return group.members;
      }
      return allMembers;
    }
    return allMembers.where((m) => bill.participantMemberIds.contains(m.id)).toList();
  }

  void toggleDraftBillParticipant(String memberId) {
    if (currentDraftBill == null) return;
    if (currentDraftBill!.participantMemberIds.isEmpty) {
      currentDraftBill!.participantMemberIds = getDraftBillParticipants().map((m) => m.id).toList();
    }
    if (currentDraftBill!.participantMemberIds.contains(memberId)) {
      if (currentDraftBill!.participantMemberIds.length > 1) {
        currentDraftBill!.participantMemberIds.remove(memberId);
        // Also remove member from any assigned items
        for (var item in currentDraftBill!.items) {
          item.assignedMemberIds.remove(memberId);
        }
      }
    } else {
      currentDraftBill!.participantMemberIds.add(memberId);
    }
    notifyListeners();
  }

  void setDraftBillParticipants(List<String> memberIds) {
    if (currentDraftBill == null) return;
    currentDraftBill!.participantMemberIds = List.from(memberIds);
    notifyListeners();
  }

  void updateDraftBillInfo({
    String? title,
    String? categoryEmoji,
    DateTime? date,
    double? vatPercent,
    double? serviceChargePercent,
    double? discountAmount,
    String? paidByMemberId,
    String? groupName,
    RoundingStrategy? roundingStrategy,
    String? pennyPayerMemberId,
  }) {
    if (currentDraftBill == null) return;
    if (title != null) currentDraftBill!.title = title;
    if (categoryEmoji != null) currentDraftBill!.categoryEmoji = categoryEmoji;
    if (date != null) currentDraftBill!.date = date;
    if (vatPercent != null) currentDraftBill!.vatPercent = vatPercent;
    if (serviceChargePercent != null) currentDraftBill!.serviceChargePercent = serviceChargePercent;
    if (discountAmount != null) currentDraftBill!.discountAmount = discountAmount;
    if (paidByMemberId != null) currentDraftBill!.paidByMemberId = paidByMemberId;
    if (roundingStrategy != null) currentDraftBill!.roundingStrategy = roundingStrategy;
    if (pennyPayerMemberId != null) currentDraftBill!.pennyPayerMemberId = pennyPayerMemberId;
    if (groupName != null) {
      currentDraftBill!.groupName = groupName;
      final group = groups.where((g) => g.name == groupName).firstOrNull;
      if (group != null) {
        currentDraftBill!.participantMemberIds = group.members.map((m) => m.id).toList();
      }
    }
    notifyListeners();
  }

  void updateBillItem(String itemId, {String? name, double? price, int? quantity}) {
    if (currentDraftBill == null) return;
    final index = currentDraftBill!.items.indexWhere((it) => it.id == itemId);
    if (index != -1) {
      if (name != null) currentDraftBill!.items[index].name = name;
      if (price != null) currentDraftBill!.items[index].price = price;
      if (quantity != null) currentDraftBill!.items[index].quantity = quantity;
      currentDraftBill!.items[index].hasWarning = false;
      notifyListeners();
    }
  }

  void removeBillItem(String itemId) {
    if (currentDraftBill == null) return;
    currentDraftBill!.items.removeWhere((it) => it.id == itemId);
    notifyListeners();
  }

  void addBillItem(String name, double price, int quantity) {
    if (currentDraftBill == null) return;
    currentDraftBill!.items.add(
      BillItem(
        id: 'item_${DateTime.now().microsecondsSinceEpoch}_${currentDraftBill!.items.length}',
        name: name,
        price: price,
        quantity: quantity,
      ),
    );
    notifyListeners();
  }

  void toggleMemberAssignment(String itemId, String memberId) {
    if (currentDraftBill == null) return;
    final item = currentDraftBill!.items.firstWhere((it) => it.id == itemId);
    if (item.assignedMemberIds.contains(memberId)) {
      item.assignedMemberIds.remove(memberId);
    } else {
      item.assignedMemberIds.add(memberId);
    }
    notifyListeners();
  }

  void assignAllMembersToItem(String itemId) {
    if (currentDraftBill == null) return;
    final item = currentDraftBill!.items.firstWhere((it) => it.id == itemId);
    final participants = getDraftBillParticipants();
    item.assignedMemberIds = participants.map((m) => m.id).toList();
    notifyListeners();
  }

  void setItemAssignedMembers(String itemId, List<String> memberIds) {
    if (currentDraftBill == null) return;
    final item = currentDraftBill!.items.firstWhere((it) => it.id == itemId);
    item.assignedMemberIds = List.from(memberIds);
    notifyListeners();
  }

  void clearAllAssignments() {
    if (currentDraftBill == null) return;
    for (var it in currentDraftBill!.items) {
      it.assignedMemberIds.clear();
    }
    notifyListeners();
  }

  void setSplitMode(SplitMode mode) {
    if (currentDraftBill == null) return;
    currentDraftBill = currentDraftBill!.copyWith(splitMode: mode);
    notifyListeners();
  }

  void setRoundingStrategy(RoundingStrategy strategy) {
    if (currentDraftBill == null) return;
    currentDraftBill = currentDraftBill!.copyWith(roundingStrategy: strategy);
    notifyListeners();
  }

  void setPennyPayerMember(String memberId) {
    if (currentDraftBill == null) return;
    currentDraftBill = currentDraftBill!.copyWith(pennyPayerMemberId: memberId);
    notifyListeners();
  }

  // Calculate breakdown per member with Penny Rounding Strategy
  Map<String, double> calculateMemberShares() {
    if (currentDraftBill == null) return {};
    final bill = currentDraftBill!;
    final participants = getDraftBillParticipants();
    if (participants.isEmpty) return {};

    final Map<String, double> shares = {};
    for (var m in participants) {
      shares[m.id] = 0.0;
    }

    final int n = participants.length;
    // Designated member to adjust difference or satangs
    final adjustMemberId = (bill.pennyPayerMemberId != null && participants.any((p) => p.id == bill.pennyPayerMemberId))
        ? bill.pennyPayerMemberId!
        : (participants.any((p) => p.id == bill.paidByMemberId) ? bill.paidByMemberId : participants.first.id);

    final strategy = bill.roundingStrategy;

    // Strategy 1: Round to whole Baht
    if (strategy == RoundingStrategy.roundToBaht) {
      final int targetBaht = bill.grandTotal.round();

      if (bill.splitMode == SplitMode.equal) {
        final int baseBaht = targetBaht ~/ n;
        final int remainderBaht = targetBaht % n;

        for (int i = 0; i < n; i++) {
          final m = participants[i];
          if (m.id == adjustMemberId) {
            shares[m.id] = (baseBaht + remainderBaht).toDouble();
          } else {
            shares[m.id] = baseBaht.toDouble();
          }
        }
        return shares;
      } else {
        // itemized with roundToBaht
        double totalDirectItems = 0.0;
        final Map<String, double> memberItemTotals = {};
        for (var m in participants) {
          memberItemTotals[m.id] = 0.0;
        }
        for (var item in bill.items) {
          if (item.assignedMemberIds.isNotEmpty) {
            final validAssigned = item.assignedMemberIds.where((id) => participants.any((p) => p.id == id)).toList();
            if (validAssigned.isNotEmpty) {
              final share = item.totalPrice / validAssigned.length;
              for (var mId in validAssigned) {
                memberItemTotals[mId] = (memberItemTotals[mId] ?? 0.0) + share;
              }
              totalDirectItems += item.totalPrice;
            }
          }
        }
        if (totalDirectItems <= 0) {
          final int baseBaht = targetBaht ~/ n;
          final int remainderBaht = targetBaht % n;
          for (var m in participants) {
            shares[m.id] = (m.id == adjustMemberId ? (baseBaht + remainderBaht) : baseBaht).toDouble();
          }
          return shares;
        }

        final double factor = bill.grandTotal / totalDirectItems;
        int allocatedBaht = 0;
        final Map<String, int> memberBahtMap = {};
        for (var m in participants) {
          final rawAmount = (memberItemTotals[m.id] ?? 0.0) * factor;
          final rounded = rawAmount.round();
          memberBahtMap[m.id] = rounded;
          allocatedBaht += rounded;
        }
        final int diffBaht = targetBaht - allocatedBaht;
        memberBahtMap[adjustMemberId] = (memberBahtMap[adjustMemberId] ?? 0) + diffBaht;

        for (var m in participants) {
          shares[m.id] = (memberBahtMap[m.id] ?? 0).toDouble();
        }
        return shares;
      }
    }

    // Cent / Satang calculations:
    final int totalTargetSatang = (bill.grandTotal * 100).round();

    if (bill.splitMode == SplitMode.equal) {
      final int baseSatang = totalTargetSatang ~/ n;
      final int remainderSatang = totalTargetSatang % n;

      if (strategy == RoundingStrategy.payerAbsorbs) {
        for (var m in participants) {
          if (m.id == adjustMemberId) {
            shares[m.id] = (baseSatang + remainderSatang) / 100.0;
          } else {
            shares[m.id] = baseSatang / 100.0;
          }
        }
      } else {
        // RoundingStrategy.distributeEvenly
        for (int i = 0; i < n; i++) {
          final m = participants[i];
          final int memberSatang = baseSatang + (i < remainderSatang ? 1 : 0);
          shares[m.id] = memberSatang / 100.0;
        }
      }
      return shares;
    }

    // SplitMode.itemized
    double totalDirectItems = 0.0;
    final Map<String, double> memberItemTotals = {};
    for (var m in participants) {
      memberItemTotals[m.id] = 0.0;
    }

    for (var item in bill.items) {
      if (item.assignedMemberIds.isNotEmpty) {
        final validAssigned = item.assignedMemberIds.where((id) => participants.any((p) => p.id == id)).toList();
        if (validAssigned.isNotEmpty) {
          final share = item.totalPrice / validAssigned.length;
          for (var mId in validAssigned) {
            memberItemTotals[mId] = (memberItemTotals[mId] ?? 0.0) + share;
          }
          totalDirectItems += item.totalPrice;
        }
      }
    }

    if (totalDirectItems <= 0) {
      final int baseSatang = totalTargetSatang ~/ n;
      final int remainderSatang = totalTargetSatang % n;
      if (strategy == RoundingStrategy.payerAbsorbs) {
        for (var m in participants) {
          shares[m.id] = (m.id == adjustMemberId ? (baseSatang + remainderSatang) : baseSatang) / 100.0;
        }
      } else {
        for (int i = 0; i < n; i++) {
          final m = participants[i];
          shares[m.id] = (baseSatang + (i < remainderSatang ? 1 : 0)) / 100.0;
        }
      }
      return shares;
    }

    final double factor = bill.grandTotal / totalDirectItems;
    int allocatedSatang = 0;
    final Map<String, int> memberSatangMap = {};

    for (var m in participants) {
      final double rawAmount = (memberItemTotals[m.id] ?? 0.0) * factor;
      final int satang = (rawAmount * 100).round();
      memberSatangMap[m.id] = satang;
      allocatedSatang += satang;
    }

    final int diffSatang = totalTargetSatang - allocatedSatang;
    if (diffSatang != 0) {
      if (strategy == RoundingStrategy.payerAbsorbs) {
        memberSatangMap[adjustMemberId] = (memberSatangMap[adjustMemberId] ?? 0) + diffSatang;
      } else {
        // distributeEvenly
        final sortedKeys = memberSatangMap.keys.toList()
          ..sort((a, b) => (memberSatangMap[b] ?? 0).compareTo(memberSatangMap[a] ?? 0));
        int remainingDiff = diffSatang;
        int step = diffSatang > 0 ? 1 : -1;
        int idx = 0;
        while (remainingDiff != 0 && sortedKeys.isNotEmpty) {
          final key = sortedKeys[idx % sortedKeys.length];
          memberSatangMap[key] = (memberSatangMap[key] ?? 0) + step;
          remainingDiff -= step;
          idx++;
        }
      }
    }

    for (var m in participants) {
      shares[m.id] = (memberSatangMap[m.id] ?? 0) / 100.0;
    }

    return shares;
  }

  void saveCurrentBill() {
    if (currentDraftBill == null) return;
    final bill = currentDraftBill!;
    final shares = calculateMemberShares();
    final payer = allMembers.firstWhere((m) => m.id == bill.paidByMemberId, orElse: () => currentUser);

    // Save to historical bills
    savedBills.insert(0, bill.copyWith());

    // Create debts for members who owe the payer
    for (var entry in shares.entries) {
      if (entry.key != bill.paidByMemberId && entry.value > 0) {
        final member = allMembers.firstWhere((m) => m.id == entry.key);
        debts.add(
          DebtRecord(
            id: 'd_${DateTime.now().millisecondsSinceEpoch}_${entry.key}',
            fromMember: member,
            toMember: payer,
            amount: entry.value,
            billTitle: '${bill.categoryEmoji} ${bill.title}',
            daysOverdue: 0,
          ),
        );
      }
    }

    // Also add to group bills if group exists
    final matchedGroup = groups.where((g) => g.name == bill.groupName).firstOrNull;
    if (matchedGroup != null) {
      addBillToGroup(
        matchedGroup.id,
        '${bill.categoryEmoji} ${bill.title}',
        bill.grandTotal,
        payer.name,
        getDraftBillParticipants().length,
      );
    }

    activities.insert(
      0,
      RecentActivity(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: '${payer.isCurrentUser ? "คุณ" : payer.name}สร้างบิลใหม่',
        subtitle: '${bill.categoryEmoji} ${bill.title} ยอด ฿${bill.grandTotal.toStringAsFixed(2)}',
        amount: bill.grandTotal,
        emoji: '🧾',
        timestamp: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  void addNewGroup(String name, String category, String emoji) {
    final newId = 'g_${DateTime.now().millisecondsSinceEpoch}';
    groups.add(
      GroupModel(
        id: newId,
        name: name,
        category: category,
        emoji: emoji,
        members: [allMembers[0], allMembers[1], allMembers[2]],
        billIds: [],
        userBalance: 0.0,
      ),
    );
    groupBills[newId] = [];
    notifyListeners();
  }

  void deleteGroup(String groupId) {
    final index = groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final removed = groups.removeAt(index);
      groupBills.remove(groupId);
      activities.insert(
        0,
        RecentActivity(
          id: 'act_${DateTime.now().millisecondsSinceEpoch}',
          title: 'ลบกลุ่ม ${removed.name}',
          subtitle: 'หมวดหมู่ ${removed.category}',
          emoji: '🗑️',
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  List<GroupBill> getGroupBills(String groupId) {
    return groupBills[groupId] ?? [];
  }

  void addBillToGroup(String groupId, String title, double amount, String paidByName, int memberCount) {
    if (!groupBills.containsKey(groupId)) {
      groupBills[groupId] = [];
    }
    groupBills[groupId]!.insert(
      0,
      GroupBill(
        id: 'gb_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        totalAmount: amount,
        paidByName: paidByName,
        date: DateTime.now(),
        memberCount: memberCount,
      ),
    );
    notifyListeners();
  }

  // Notification Management
  void markNotificationAsRead(String id) {
    final notif = notifications.firstWhere((n) => n.id == id, orElse: () => notifications.first);
    notif.isRead = true;
    notifyListeners();
  }

  void markAllNotificationsAsRead() {
    for (var n in notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void clearNotification(String id) {
    notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void simulateIncomingNotification() {
    final newNotif = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: 'มิ้นท์ ยืนยันการโอนเงิน 🎉',
      message: 'มิ้นท์ แนบสลิปค่าเน็ตคอนโด ฿310.00 ยอดหนี้ปรับเป็น 0 แล้ว',
      emoji: '🟣',
      timestamp: DateTime.now(),
      type: NotificationType.payment,
      isRead: false,
      relatedAction: 'view_payment',
    );
    notifications.insert(0, newNotif);
    notifyListeners();
  }

  // Profile & Bank Management
  void updateProfile({
    String? name,
    String? avatarEmoji,
    String? promptPay,
    String? bank,
    String? accNo,
  }) {
    if (name != null) userName = name;
    if (avatarEmoji != null) userAvatarEmoji = avatarEmoji;
    if (promptPay != null) userPromptPay = promptPay;
    if (bank != null) userBank = bank;
    if (accNo != null) userBankAccountNumber = accNo;
    allMembers[0] = currentUser;
    notifyListeners();
  }

  void setPrimaryBankAccount(String id) {
    for (var acc in bankAccounts) {
      acc.isPrimary = (acc.id == id);
      if (acc.isPrimary) {
        userBank = acc.bankName;
        userBankAccountNumber = acc.accountNumber;
      }
    }
    notifyListeners();
  }

  void addBankAccount(String bankName, String accNumber, Color color) {
    bankAccounts.add(
      BankAccountItem(
        id: 'ba_${DateTime.now().millisecondsSinceEpoch}',
        bankName: bankName,
        accountNumber: accNumber,
        brandColor: color,
        isPrimary: bankAccounts.isEmpty,
      ),
    );
    notifyListeners();
  }

  void removeBankAccount(String id) {
    bankAccounts.removeWhere((acc) => acc.id == id);
    if (bankAccounts.isNotEmpty && !bankAccounts.any((a) => a.isPrimary)) {
      bankAccounts.first.isPrimary = true;
      userBank = bankAccounts.first.bankName;
      userBankAccountNumber = bankAccounts.first.accountNumber;
    }
    notifyListeners();
  }

  void updateNotificationSettings({
    bool? push,
    bool? due,
    bool? weekly,
    bool? sound,
  }) {
    if (push != null) pushEnabled = push;
    if (due != null) billDueReminder = due;
    if (weekly != null) weeklySummary = weekly;
    if (sound != null) soundAndVibration = sound;
    notifyListeners();
  }

  void updateVoiceSettings({
    bool? allow,
    bool? quiet,
    String? persona,
    String? effect,
  }) {
    if (allow != null) allowVoiceNudge = allow;
    if (quiet != null) quietHoursEnabled = quiet;
    if (persona != null) defaultPersona = persona;
    if (effect != null) defaultEffect = effect;
    notifyListeners();
  }

  void addVoiceNudge(VoiceNudgeData nudge) {
    voiceNudges.insert(0, nudge);
    activities.insert(
      0,
      RecentActivity(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'ส่งเสียงทวง ${nudge.targetMember.name}',
        subtitle: '${nudge.billTitle} (฿${nudge.amount.toStringAsFixed(0)})',
        amount: nudge.amount,
        emoji: '🎙️',
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void setLanguage(String lang) {
    appLanguage = lang;
    notifyListeners();
  }

  void setCurrency(String curr) {
    appCurrency = curr;
    notifyListeners();
  }

  void resetDemoData() {
    userName = 'ป๊อป';
    userAvatarEmoji = '🔵';
    userPromptPay = '081-234-5678';
    userBank = 'ธนาคารกสิกรไทย (KBank)';
    userBankAccountNumber = '123-4-56789-0';
    appLanguage = 'ไทย';
    appCurrency = 'THB (฿)';
    pushEnabled = true;
    billDueReminder = true;
    weeklySummary = true;
    soundAndVibration = true;
    allowVoiceNudge = true;
    quietHoursEnabled = true;
    defaultPersona = 'น้องนุ่ม';
    defaultEffect = 'ปกติ';
    _initData();
    notifyListeners();
  }
}


