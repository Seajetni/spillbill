import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/split_bill_provider.dart';
import '../theme/app_theme.dart';
import '../utils/promptpay_qr.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SplitBillProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('โปรไฟล์และการตั้งค่า'),
        actions: [
          IconButton(
            tooltip: 'QR รับเงินของฉัน',
            icon: const Icon(Icons.qr_code_2_rounded, color: AppColors.ink),
            onPressed: () => _showMyQrModal(context, provider),
          ),
          IconButton(
            tooltip: 'แก้ไขโปรไฟล์',
            icon: const Icon(Icons.edit_outlined, color: AppColors.ink),
            onPressed: () => _showEditProfileModal(context, provider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // 1. User Info Card
          _buildUserProfileCard(context, provider),
          const SizedBox(height: 16),

          // 2. Financial Summary Overview Cards
          _buildFinancialSummaryCards(provider),
          const SizedBox(height: 24),

          // 3. Section: Financial & Payments
          _buildSectionHeader('บัญชีและการรับเงิน'),
          const SizedBox(height: 10),
          _buildCardGroup([
            ListTile(
              leading: _buildLeadingIcon(Icons.account_balance_wallet_outlined, AppColors.primary),
              title: const Text('บัญชีธนาคารและพร้อมเพย์', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
              subtitle: Text(
                '${provider.bankAccounts.length} บัญชี • ${provider.userBank}',
                style: const TextStyle(fontSize: 12, color: AppColors.ink3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.ink3),
              onTap: () => _showBankAccountsModal(context, provider),
            ),
            const Divider(),
            ListTile(
              leading: _buildLeadingIcon(Icons.qr_code_2_rounded, AppColors.primary),
              title: const Text('QR Code รับเงินของฉัน', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
              subtitle: Text('พร้อมเพย์: ${provider.userPromptPay}', style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.ink3),
              onTap: () => _showMyQrModal(context, provider),
            ),
          ]),
          const SizedBox(height: 24),

          // 4. Section: Notifications & Voice
          _buildSectionHeader('การแจ้งเตือนและระบบเสียง'),
          const SizedBox(height: 10),
          _buildCardGroup([
            ListTile(
              leading: _buildLeadingIcon(Icons.notifications_outlined, AppColors.primary),
              title: const Text('ตั้งค่าการแจ้งเตือน & Push', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
              subtitle: Text(
                '${provider.pushEnabled ? "เปิดการแจ้งเตือน" : "ปิดการแจ้งเตือน"}'
                '${provider.billDueReminder ? " • เตือนครบกำหนด" : ""}',
                style: const TextStyle(fontSize: 12, color: AppColors.ink3),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.ink3),
              onTap: () => _showNotificationSettingsModal(context, provider),
            ),
            const Divider(),
            ListTile(
              leading: _buildLeadingIcon(Icons.mic_none_rounded, AppColors.primary),
              title: const Text('ตั้งค่าระบบเสียง (Voice Nudge)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
              subtitle: Text(
                'เสียง ${provider.defaultPersona} • เอฟเฟกต์ ${provider.defaultEffect} • '
                '${provider.quietHoursEnabled ? "โหมดเงียบ 22:00-08:00" : "ตลอด 24 ชม."}',
                style: const TextStyle(fontSize: 12, color: AppColors.ink3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.ink3),
              onTap: () => _showVoiceNudgeSettingsModal(context, provider),
            ),
          ]),
          const SizedBox(height: 24),

          // 5. Section: Preferences & Support
          _buildSectionHeader('การตั้งค่าทั่วไปและช่วยเหลือ'),
          const SizedBox(height: 10),
          _buildCardGroup([
            ListTile(
              leading: _buildLeadingIcon(Icons.language_rounded, AppColors.ink2),
              title: const Text('ภาษา / Language', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
              subtitle: Text(provider.appLanguage, style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.ink3),
              onTap: () => _showLanguageDialog(context, provider),
            ),
            const Divider(),
            ListTile(
              leading: _buildLeadingIcon(Icons.currency_exchange_rounded, AppColors.ink2),
              title: const Text('สกุลเงินเริ่มต้น', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
              subtitle: Text(provider.appCurrency, style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.ink3),
              onTap: () => _showCurrencyDialog(context, provider),
            ),
            const Divider(),
            ListTile(
              leading: _buildLeadingIcon(Icons.help_outline_rounded, AppColors.ink2),
              title: const Text('ช่วยเหลือ & คำถามที่พบบ่อย (FAQ)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
              subtitle: const Text('วิธีสแกนบิล, หักลดหนี้, พร้อมเพย์', style: TextStyle(fontSize: 12, color: AppColors.ink3)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.ink3),
              onTap: () => _showFaqModal(context),
            ),
            const Divider(),
            ListTile(
              leading: _buildLeadingIcon(Icons.info_outline_rounded, AppColors.ink2),
              title: const Text('เกี่ยวกับ SplitBill', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
              subtitle: const Text('เวอร์ชัน 1.2.0 (Build 42)', style: TextStyle(fontSize: 12, color: AppColors.ink3)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.ink3),
              onTap: () => _showAboutModal(context),
            ),
          ]),
          const SizedBox(height: 24),

          // 6. Danger Zone / Reset
          _buildCardGroup([
            ListTile(
              leading: _buildLeadingIcon(Icons.restore_rounded, AppColors.danger),
              title: const Text(
                'รีเซ็ตข้อมูลระบบเป็นค่าเริ่มต้น',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.danger),
              ),
              subtitle: const Text('คืนค่ารายการบิล หนี้ สมาชิก และการตั้งค่าทั้งหมด', style: TextStyle(fontSize: 12, color: AppColors.ink3)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.ink3),
              onTap: () => _confirmResetDialog(context, provider),
            ),
          ]),
          const SizedBox(height: 36),

          // Footer
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'SplitBill Mobile',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('v1.2.0', style: TextStyle(fontSize: 11, color: AppColors.ink3)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'แอปหารค่าใช้จ่ายอัจฉริยะ พร้อมเพย์ และสะกิดทวงด้วยเสียง',
                  style: TextStyle(fontSize: 11, color: AppColors.ink3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
    );
  }

  Widget _buildLeadingIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdBorder,
        side: const BorderSide(color: AppColors.line),
      ),
      child: Column(children: children),
    );
  }

  // 1. User Profile Card
  Widget _buildUserProfileCard(BuildContext context, SplitBillProvider provider) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.xlBorder,
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(provider.currentUser.avatarEmoji, style: const TextStyle(fontSize: 34)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () => _showEditProfileModal(context, provider),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            provider.currentUser.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ฉัน',
                            style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'พร้อมเพย์: ${provider.userPromptPay}',
                      style: const TextStyle(fontSize: 13, color: AppColors.ink2, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      provider.userBank,
                      style: const TextStyle(fontSize: 12, color: AppColors.ink3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.successSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 13, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'พร้อมเพย์ยืนยันแล้ว ✓',
                            style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditProfileModal(context, provider),
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text('แก้ไขโปรไฟล์'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.line),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showMyQrModal(context, provider),
                  icon: const Icon(Icons.qr_code_rounded, size: 18),
                  label: const Text('QR ของฉัน'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Financial Overview Stats
  Widget _buildFinancialSummaryCards(SplitBillProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: 'รอรับคืน',
            amount: '฿${provider.toReceiveAmount.toStringAsFixed(0)}',
            color: AppColors.success,
            bgColor: AppColors.successSoft,
            icon: Icons.call_received_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            title: 'รอจ่าย',
            amount: '฿${provider.toPayAmount.toStringAsFixed(0)}',
            color: AppColors.warn,
            bgColor: AppColors.warnSoft,
            icon: Icons.call_made_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            title: 'กลุ่มทั้งหมด',
            amount: '${provider.groups.length} กลุ่ม',
            color: AppColors.primary,
            bgColor: AppColors.primarySoft,
            icon: Icons.groups_rounded,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String amount,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: AppColors.ink3, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- Modals & Dialogs ---

  // 1. Edit Profile Modal
  void _showEditProfileModal(BuildContext context, SplitBillProvider provider) {
    final nameController = TextEditingController(text: provider.userName);
    final promptPayController = TextEditingController(text: provider.userPromptPay);
    String selectedEmoji = provider.userAvatarEmoji;

    final emojis = [
      '🔵', '🟢', '🟠', '🟣', '🩷', '🤠', '🐱', '🦊',
      '🐼', '🦁', '🥑', '🍕', '🚀', '💎', '😎', '🍣'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'แก้ไขข้อมูลโปรไฟล์',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Avatar Emoji Selector
                    const Text('เลือกไอคอนรูปโปรไฟล์', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: emojis.map((emoji) {
                        final isSelected = emoji == selectedEmoji;
                        return InkWell(
                          onTap: () => setModalState(() => selectedEmoji = emoji),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primarySoft : AppColors.bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.line,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(emoji, style: const TextStyle(fontSize: 22)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Name Field
                    const Text('ชื่อที่แสดงในระบบ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'กรอกชื่อของคุณ',
                        filled: true,
                        fillColor: AppColors.bg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.smBorder,
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PromptPay Number Field
                    const Text('เบอร์พร้อมเพย์ / เลขบัตรประชาชน', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: promptPayController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'เช่น 081-234-5678',
                        filled: true,
                        fillColor: AppColors.bg,
                        prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 20, color: AppColors.ink3),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.smBorder,
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
                        ),
                        onPressed: () {
                          final newName = nameController.text.trim();
                          final newPromptPay = promptPayController.text.trim();
                          if (newName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('กรุณาระบุชื่อ')),
                            );
                            return;
                          }
                          provider.updateProfile(
                            name: newName,
                            avatarEmoji: selectedEmoji,
                            promptPay: newPromptPay.isNotEmpty ? newPromptPay : null,
                          );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('บันทึกข้อมูลโปรไฟล์เรียบร้อยแล้ว ✓')),
                          );
                        },
                        child: const Text('บันทึกข้อมูล', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 2. My PromptPay QR Modal
  void _showMyQrModal(BuildContext context, SplitBillProvider provider) {
    double? customAmount;
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setQrState) {
            final qrData = PromptPayQR.generatePayload(provider.userPromptPay, amount: customAmount);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'QR Code รับเงินของฉัน',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // QR Card Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.lgBorder,
                        border: Border.all(color: AppColors.line),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // PromptPay Logo header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF003D79),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'พร้อมเพย์ PromptPay',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // QR Image
                          SizedBox(
                            width: 190,
                            height: 190,
                            child: QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: AppColors.ink,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            provider.userName,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.ink),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                provider.userPromptPay,
                                style: const TextStyle(fontSize: 14, color: AppColors.ink2, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: provider.userPromptPay));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('คัดลอกเบอร์พร้อมเพย์แล้ว ✓')),
                                  );
                                },
                                child: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                              ),
                            ],
                          ),
                          if (customAmount != null && customAmount! > 0) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ระบุยอด: ฿${customAmount!.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount input (optional)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: 'ระบุยอดเงิน (เว้นว่างได้)',
                              prefixText: '฿ ',
                              filled: true,
                              fillColor: AppColors.bg,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.smBorder,
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final parsed = double.tryParse(amountController.text.trim());
                            setQrState(() => customAmount = parsed);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primarySoft,
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
                          ),
                          child: const Text('อัปเดต'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Copy & Share buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: provider.userPromptPay));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('คัดลอกเบอร์พร้อมเพย์แล้ว ✓')),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('คัดลอกเบอร์'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.ink,
                              side: const BorderSide(color: AppColors.line),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('บันทึกรูปภาพ QR Code ลงเครื่องแล้ว ✓')),
                              );
                            },
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text('บันทึก QR'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 3. Bank Accounts & PromptPay Management Modal
  void _showBankAccountsModal(BuildContext context, SplitBillProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setBankState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'บัญชีธนาคารและพร้อมเพย์',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // PromptPay Linked Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: AppRadius.mdBorder,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('พร้อมเพย์หลัก (PromptPay ID)', style: TextStyle(fontSize: 11, color: AppColors.ink3, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(
                                  provider.userPromptPay,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showEditProfileModal(context, provider);
                            },
                            child: const Text('แก้ไข'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Bank Accounts List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'บัญชีรับเงินโอน',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        TextButton.icon(
                          onPressed: () => _showAddBankAccountDialog(context, provider),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('เพิ่มบัญชี'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Bank Account Cards
                    ...provider.bankAccounts.map((acc) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppRadius.mdBorder,
                          border: Border.all(
                            color: acc.isPrimary ? AppColors.primary : AppColors.line,
                            width: acc.isPrimary ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: acc.brandColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.account_balance_rounded, color: acc.brandColor, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          acc.bankName,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (acc.isPrimary) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.successSoft,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'บัญชีหลัก',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    acc.accountNumber,
                                    style: const TextStyle(fontSize: 13, color: AppColors.ink2),
                                  ),
                                ],
                              ),
                            ),
                            if (!acc.isPrimary)
                              IconButton(
                                tooltip: 'ตั้งเป็นบัญชีหลัก',
                                icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.ink3, size: 20),
                                onPressed: () {
                                  provider.setPrimaryBankAccount(acc.id);
                                  setBankState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('ตั้ง ${acc.bankName} เป็นบัญชีหลักแล้ว ✓')),
                                  );
                                },
                              ),
                            if (provider.bankAccounts.length > 1)
                              IconButton(
                                tooltip: 'ลบบัญชี',
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                                onPressed: () {
                                  provider.removeBankAccount(acc.id);
                                  setBankState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('ลบบัญชีเรียบร้อยแล้ว')),
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddBankAccountDialog(BuildContext context, SplitBillProvider provider) {
    final banks = [
      {'name': 'ธนาคารกสิกรไทย (KBank)', 'color': const Color(0xFF138F2D)},
      {'name': 'ธนาคารไทยพาณิชย์ (SCB)', 'color': const Color(0xFF4E2E80)},
      {'name': 'ธนาคารทหารไทยธนชาต (ttb)', 'color': const Color(0xFF0056B3)},
      {'name': 'ธนาคารกรุงเทพ (BBL)', 'color': const Color(0xFF1E3A8A)},
      {'name': 'ธนาคารกรุงไทย (KTB)', 'color': const Color(0xFF00A3E0)},
      {'name': 'ธนาคารกรุงศรีอยุธยา (BAY)', 'color': const Color(0xFFFECB00)},
      {'name': 'ธนาคารออมสิน (GSB)', 'color': const Color(0xFFEB1985)},
    ];

    var selectedBank = banks.first;
    final accNoController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
              title: const Text('เพิ่มบัญชีธนาคารใหม่', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('เลือกธนาคาร', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink3)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Map<String, Object>>(
                    initialValue: selectedBank,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.bg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.smBorder,
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: banks.map((b) {
                      return DropdownMenuItem<Map<String, Object>>(
                        value: b,
                        child: Text(
                          b['name'] as String,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedBank = val);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('เลขที่บัญชีธนาคาร', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink3)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: accNoController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'เช่น 123-4-56789-0',
                      filled: true,
                      fillColor: AppColors.bg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.smBorder,
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('ยกเลิก', style: TextStyle(color: AppColors.ink3)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final accNo = accNoController.text.trim();
                    if (accNo.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('กรุณาระบุเลขที่บัญชี')),
                      );
                      return;
                    }
                    provider.addBankAccount(
                      selectedBank['name'] as String,
                      accNo,
                      selectedBank['color'] as Color,
                    );
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('เพิ่มบัญชีธนาคารเรียบร้อยแล้ว ✓')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('เพิ่มบัญชี'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 4. Notification Settings Modal
  void _showNotificationSettingsModal(BuildContext context, SplitBillProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setNotifState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ตั้งค่าการแจ้งเตือน & Push',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('การแจ้งเตือนแบบพุช (Push Notification)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('รับแจ้งเตือนเมื่อมีบิลใหม่ หรือมีคนชำระเงิน', style: TextStyle(fontSize: 12, color: AppColors.ink3)),
                    activeThumbColor: AppColors.primary,
                    value: provider.pushEnabled,
                    onChanged: (val) {
                      provider.updateNotificationSettings(push: val);
                      setNotifState(() {});
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('เตือนเมื่อครบกำหนดชำระ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('เตือนล่วงหน้า 1 วัน ก่อนยอดค้างชำระครบกำหนด', style: TextStyle(fontSize: 12, color: AppColors.ink3)),
                    activeThumbColor: AppColors.primary,
                    value: provider.billDueReminder,
                    onChanged: (val) {
                      provider.updateNotificationSettings(due: val);
                      setNotifState(() {});
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('สรุปยอดหนี้ประจำสัปดาห์', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('สรุปยอดหนี้คงค้างและยอดที่ต้องรับ ทุกวันอาทิตย์', style: TextStyle(fontSize: 12, color: AppColors.ink3)),
                    activeThumbColor: AppColors.primary,
                    value: provider.weeklySummary,
                    onChanged: (val) {
                      provider.updateNotificationSettings(weekly: val);
                      setNotifState(() {});
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('เสียงและการสั่นเตือน', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('เล่นเสียงเอฟเฟกต์เมื่อได้รับการแจ้งเตือน', style: TextStyle(fontSize: 12, color: AppColors.ink3)),
                    activeThumbColor: AppColors.primary,
                    value: provider.soundAndVibration,
                    onChanged: (val) {
                      provider.updateNotificationSettings(sound: val);
                      setNotifState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        provider.simulateIncomingNotification();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('จำลองการส่งแจ้งเตือนสำเร็จ! ดูได้ที่กระดิ่งหน้าแรก')),
                        );
                      },
                      icon: const Icon(Icons.notifications_active_outlined, size: 18),
                      label: const Text('ทดสอบส่งการแจ้งเตือนจำลอง'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 5. Voice Nudge Settings Modal
  void _showVoiceNudgeSettingsModal(BuildContext context, SplitBillProvider provider) {
    final effects = ['ปกติ', 'ชิพมังก์', 'ทุ้มลึก', 'วิทยุเก่า', 'ห้องโถง'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setVoiceState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ตั้งค่าระบบเสียงสะกิดทวง',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('เปิดใช้งานระบบเสียงทวงหนี้ (Voice Nudge)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('อนุญาตให้อัดเสียงสะกิดทวงเพื่อน', style: TextStyle(fontSize: 12, color: AppColors.ink3)),
                      activeThumbColor: AppColors.primary,
                      value: provider.allowVoiceNudge,
                      onChanged: (val) {
                        provider.updateVoiceSettings(allow: val);
                        setVoiceState(() {});
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('โหมดห้ามรบกวน (22:00 - 08:00 น.)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('งดส่งเสียงเตือนอัตโนมัติในช่วงเวลานอนหลับ', style: TextStyle(fontSize: 12, color: AppColors.ink3)),
                      activeThumbColor: AppColors.primary,
                      value: provider.quietHoursEnabled,
                      onChanged: (val) {
                        provider.updateVoiceSettings(quiet: val);
                        setVoiceState(() {});
                      },
                    ),
                    const SizedBox(height: 14),

                    // Default Effect
                    const Text('เอฟเฟกต์เสียงเริ่มต้น (Sound Effect)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: effects.map((e) {
                        final isSel = e == provider.defaultEffect;
                        return ChoiceChip(
                          label: Text(e),
                          selected: isSel,
                          selectedColor: AppColors.primarySoft,
                          labelStyle: TextStyle(
                            color: isSel ? AppColors.primary : AppColors.ink,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              provider.updateVoiceSettings(effect: e);
                              setVoiceState(() {});
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Preview Voice Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('กำลังเล่นตัวอย่างเสียง (เอฟเฟกต์: ${provider.defaultEffect}) 🔊'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.volume_up_rounded, size: 18),
                        label: const Text('ทดลองฟังเสียงตัวอย่าง'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 6. Language Dialog
  void _showLanguageDialog(BuildContext context, SplitBillProvider provider) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
          title: const Text('เลือกภาษา / Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _languageOption(dialogCtx, provider, 'ไทย', 'ภาษาไทย (Thai)'),
              const Divider(),
              _languageOption(dialogCtx, provider, 'English', 'English (อังกฤษ)'),
            ],
          ),
        );
      },
    );
  }

  Widget _languageOption(BuildContext ctx, SplitBillProvider provider, String langKey, String label) {
    final isSelected = provider.appLanguage == langKey;
    return ListTile(
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
      onTap: () {
        provider.setLanguage(langKey);
        Navigator.pop(ctx);
      },
    );
  }

  // 7. Currency Dialog
  void _showCurrencyDialog(BuildContext context, SplitBillProvider provider) {
    final currencies = ['THB (฿)', 'USD (\$)', 'JPY (¥)', 'EUR (€)', 'SGD (S\$)'];
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
          title: const Text('เลือกสกุลเงินเริ่มต้น'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: currencies.map((curr) {
              final isSelected = provider.appCurrency == curr;
              return ListTile(
                title: Text(curr, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                onTap: () {
                  provider.setCurrency(curr);
                  Navigator.pop(dialogCtx);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // 8. Help & FAQ Modal
  void _showFaqModal(BuildContext context) {
    final faqs = [
      {
        'q': 'วิธีสแกนใบเสร็จด้วย AI OCR ทำอย่างไร?',
        'a': 'กดปุ่ม "+" ตรงกลางแถบเมนูด้านล่าง แล้วเลือก "สแกนใบเสร็จ (AI OCR)" ถ่ายรูปใบเสร็จให้ชัดเจน ระบบจะตรวจจับรายการอาหาร ราคา ภาษี และส่วนลดให้อัตโนมัติ'
      },
      {
        'q': 'หารเท่ากัน (Equal) กับ หารตามจริง (Itemized) ต่างกันอย่างไร?',
        'a': 'หารเท่ากัน: คำนวณยอดรวมทั้งหมดหารเฉลี่ยตามจำนวนคน\nหารตามจริง: ติ๊กเลือกเฉพาะรายการที่แต่ละคนทาน ระบบจะคำนวณ Service Charge และ VAT ตามสัดส่วนของแต่ละคนให้อย่างเป็นธรรม'
      },
      {
        'q': 'Debt Simplification (ระบบหักกลบลบหนี้) ทำงานอย่างไร?',
        'a': 'เมื่อมีคนสร้างบิลหลายครั้งในกลุ่ม ระบบจะคำนวณหักลบหนี้ที่ค้างกันระหว่างสมาชิกอัตโนมัติ เพื่อให้เหลือจำนวนครั้งในการโอนเงินน้อยที่สุด ไม่ต้องโอนเงินสวนทางกัน'
      },
      {
        'q': 'Voice Nudge สะกิดทวงด้วยเสียงคืออะไร?',
        'a': 'เป็นฟีเจอร์ช่วยทวงเงินอย่างเป็นกันเอง คุณสามารถอัดเสียงตัวเอง ใส่เอฟเฟกต์น่ารัก ๆ หรือใช้ AI เปลี่ยนเสียงเป็นตัวละครต่าง ๆ เพื่อลดความอึดอัดในการทวงเงินเพื่อน'
      },
      {
        'q': 'เพื่อนไม่มีแอป SplitBill สามารถจ่ายเงินได้ไหม?',
        'a': 'จ่ายได้ทันที! คุณสามารถแชร์ลิงก์ Zero-Install เว็บเพจ ให้เพื่อนเปิดในเบราว์เซอร์เพื่อนดูยอดเงิน สแกน QR พร้อมเพย์ และแนบสลิปได้โดยไม่ต้องติดตั้งแอป'
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'คำถามที่พบบ่อย (FAQ)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...faqs.map((faq) {
                  return ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      faq['q']!,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          faq['a']!,
                          style: const TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.5),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // 9. About Modal
  void _showAboutModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('เกี่ยวกับ SplitBill', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SplitBill Application', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink)),
              SizedBox(height: 4),
              Text('เวอร์ชัน 1.2.0 (Build 42)', style: TextStyle(fontSize: 12, color: AppColors.ink3)),
              SizedBox(height: 12),
              Text(
                'แอปพลิเคชันช่วยหารค่าอาหารและบิลค่าใช้จ่ายอัจฉริยะ พร้อมระบบสแกนใบเสร็จ OCR แยกรายบุคคล คำนวณภาษีและเซอร์วิสชาร์จ รองรับ QR พร้อมเพย์ และสะกิดเตือนด้วยเสียง Voice Nudge',
                style: TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.4),
              ),
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 8),
              Text('ลิขสิทธิ์ © 2026 SplitBill Inc. สงวนลิขสิทธิ์ทุกประการ', style: TextStyle(fontSize: 11, color: AppColors.ink3)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  // 10. Confirm Reset Dialog
  void _confirmResetDialog(BuildContext context, SplitBillProvider provider) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.danger),
              SizedBox(width: 8),
              Text('ยืนยันรีเซ็ตข้อมูล', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'คุณต้องการรีเซ็ตข้อมูลทั้งหมดกลับสู่ค่าเริ่มต้นใช่หรือไม่? รายการบิลใหม่ หนี้ และการแก้ไขโปรไฟล์จะถูกคืนค่าทั้งหมด',
            style: TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('ยกเลิก', style: TextStyle(color: AppColors.ink3)),
            ),
            ElevatedButton(
              onPressed: () {
                provider.resetDemoData();
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('รีเซ็ตข้อมูลระบบเป็นค่าเริ่มต้นเรียบร้อยแล้ว ✓')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('รีเซ็ตข้อมูล'),
            ),
          ],
        );
      },
    );
  }
}
