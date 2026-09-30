import 'package:intl/intl.dart';

class DateFormatter {
  static const List<String> thaiMonthsShort = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
  ];

  static const List<String> thaiMonthsFull = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
  ];

  /// Formats a DateTime to Thai Buddhist Era short format, e.g. "9 ก.ย. 69"
  static String formatThaiDate(DateTime date, {bool includeTime = false}) {
    final thaiYearShort = (date.year + 543) % 100;
    final month = thaiMonthsShort[date.month - 1];
    final base = '${date.day} $month $thaiYearShort';
    if (includeTime) {
      final timeStr = DateFormat('HH:mm').format(date);
      return '$base ($timeStr น.)';
    }
    return base;
  }

  /// Formats a DateTime to full Thai Buddhist Era format, e.g. "9 กันยายน 2569"
  static String formatThaiDateFull(DateTime date) {
    final thaiYearFull = date.year + 543;
    final month = thaiMonthsFull[date.month - 1];
    return '${date.day} $month $thaiYearFull';
  }

  /// Formats currency with commas and 2 decimals e.g. "1,250.00"
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'th_TH');
    return formatter.format(amount);
  }
}
