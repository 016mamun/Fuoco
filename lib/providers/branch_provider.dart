import 'package:flutter_riverpod/flutter_riverpod.dart';

class Branch {
  final String name;
  final String address;
  final String phone;
  final String openingTime; // "HH:mm" 24h format
  final String closingTime; // "HH:mm" 24h format

  Branch({
    required this.name,
    required this.address,
    required this.phone,
    required this.openingTime,
    required this.closingTime,
  });

  bool get isOpen {
    final now = DateTime.now();
    final openParts = openingTime.split(':');
    final closeParts = closingTime.split(':');
    if (openParts.length != 2 || closeParts.length != 2) return true;
    
    final openHour = int.tryParse(openParts[0]) ?? 0;
    final openMinute = int.tryParse(openParts[1]) ?? 0;
    final closeHour = int.tryParse(closeParts[0]) ?? 0;
    final closeMinute = int.tryParse(closeParts[1]) ?? 0;

    final currentMinutes = now.hour * 60 + now.minute;
    final openMinutes = openHour * 60 + openMinute;
    final closeMinutes = closeHour * 60 + closeMinute;

    if (closeMinutes > openMinutes) {
      return currentMinutes >= openMinutes && currentMinutes < closeMinutes;
    } else {
      // Overnight hours (e.g. 11:00 AM to 2:00 AM next day)
      return currentMinutes >= openMinutes || currentMinutes < closeMinutes;
    }
  }

  String get formattedHours {
    // Converts "11:00" to "11:00 AM" and "23:00" to "11:00 PM"
    String formatTime(String timeStr) {
      final parts = timeStr.split(':');
      if (parts.length != 2) return timeStr;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = parts[1];
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$displayHour:$minute $ampm';
    }
    return '${formatTime(openingTime)} - ${formatTime(closingTime)}';
  }
}

final branchesList = [
  Branch(
    name: 'Fuoco Mirpur',
    address: '88, Mirpur-1 Zoo Road, Eidgah math, Ma Super Market 2nd Floor',
    phone: '01328185258',
    openingTime: '11:00',
    closingTime: '23:00',
  ),
  Branch(
    name: 'Fuoco Uttara',
    address: 'House- 24, Road- 10/B, Gorib e Neyaz Avenue, Sector- 11, Uttara, Dhaka',
    phone: '01580929087',
    openingTime: '11:00',
    closingTime: '23:30',
  ),
  Branch(
    name: 'Fuoco Khilgaon',
    address: '381/B Shahid Baki, Road, Taltola, Khilgaon, Dhaka',
    phone: '01315940072',
    openingTime: '10:00',
    closingTime: '23:00',
  ),
  Branch(
    name: 'Fuoco Banasree',
    address: 'K-5, South Banasree Main Road, Khilgaon, 1219, Dhaka, Bangladesh',
    phone: '01739603751',
    openingTime: '11:00',
    closingTime: '22:30',
  ),
  Branch(
    name: 'Fuoco Lalbagh',
    address: '1/2 Lalbagh Road, Lalbagh, Dhaka',
    phone: '01638604848',
    openingTime: '12:00',
    closingTime: '23:00',
  ),
  Branch(
    name: 'Fuoco Bashundhara',
    address: 'Plot-1317, Road-30,31, Sonia Sobhan 5th Avenue Block-I, Dhaka 1229',
    phone: '01791443998',
    openingTime: '11:00',
    closingTime: '23:59',
  ),
  Branch(
    name: 'Fuoco Cumilla',
    address: 'Silver Holi Palace, 1 st Floor, Opposite to New Hostel, Tomsom Bridge Road',
    phone: '01601313915',
    openingTime: '11:00',
    closingTime: '22:00',
  ),
  Branch(
    name: 'Fuoco Dhanmondi',
    address: 'Crescent Tower H#60, Satmasjid Road, Road: 2/A, Dhanmondi, Dhaka -1209',
    phone: '01805033288',
    openingTime: '11:00',
    closingTime: '23:30',
  ),
];

class SelectedBranchNotifier extends Notifier<Branch> {
  @override
  Branch build() {
    return branchesList[0]; // Default is Mirpur
  }

  void selectBranch(Branch branch) {
    state = branch;
  }
}

final selectedBranchProvider = NotifierProvider<SelectedBranchNotifier, Branch>(() {
  return SelectedBranchNotifier();
});
