/// Standard PromptPay QR code EMVCo payload generator
class PromptPayQR {
  static String generatePayload(String targetId, {double? amount}) {
    // Sanitize targetId (phone number: 08XXXXXXXX -> 00668XXXXXXXX or 13-digit ID)
    String sanitizedId = targetId.replaceAll(RegExp(r'[^0-9]'), '');
    String formattedTarget;
    String targetType;

    if (sanitizedId.length == 10 && sanitizedId.startsWith('0')) {
      // Mobile phone number: 08XXXXXXXX -> 00668XXXXXXXX
      formattedTarget = '0066${sanitizedId.substring(1)}';
      targetType = '01'; // Phone
    } else if (sanitizedId.length == 13) {
      // National ID
      formattedTarget = sanitizedId;
      targetType = '02'; // National ID
    } else {
      // Default to phone format if unrecognized
      formattedTarget = sanitizedId;
      targetType = '01';
    }

    // Sub-tags for Tag 29 (PromptPay Merchant Info)
    final aid = _formatTag('00', 'A000000677010111');
    final recipient = _formatTag(targetType, formattedTarget);
    final tag29 = _formatTag('29', aid + recipient);

    // Payload components
    final tag00 = _formatTag('00', '01'); // Version
    final tag01 = _formatTag('01', amount != null ? '12' : '11'); // 12 = Dynamic, 11 = Static
    final tag53 = _formatTag('53', '764'); // THB Currency
    final tag54 = amount != null ? _formatTag('54', amount.toStringAsFixed(2)) : '';
    final tag58 = _formatTag('58', 'TH'); // Country Code
    final tag62 = _formatTag('62', _formatTag('07', 'SplitBill')); // Reference

    final rawData = '$tag00$tag01$tag29$tag53$tag54$tag58${tag62}6304';
    final checksum = _crc16(rawData);

    return '$rawData$checksum';
  }

  static String _formatTag(String id, String value) {
    final length = value.length.toString().padLeft(2, '0');
    return '$id$length$value';
  }

  static String _crc16(String data) {
    int crc = 0xFFFF;
    for (int i = 0; i < data.length; i++) {
      crc ^= (data.codeUnitAt(i) << 8);
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
