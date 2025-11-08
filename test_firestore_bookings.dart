import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;

  // This is a test/debug script - print statements are acceptable here
  // ignore: avoid_print
  print('🔍 Fetching bookings for apartman-1...\n');

  final snapshot = await firestore
      .collection('bookings')
      .where('unit_id', isEqualTo: 'apartman-1')
      .where('status', whereIn: ['pending', 'confirmed', 'in_progress'])
      .limit(5)
      .get();

  // ignore: avoid_print
  print('Found ${snapshot.docs.length} bookings:\n');

  for (final doc in snapshot.docs) {
    final data = doc.data();
    // ignore: avoid_print
    print('Booking ID: ${doc.id}');
    // ignore: avoid_print
    print('  CheckIn: ${data['check_in']}');
    // ignore: avoid_print
    print('  CheckOut: ${data['check_out']}');
    // ignore: avoid_print
    print('  Status: ${data['status']}');
    // ignore: avoid_print
    print('  Guest: ${data['guest_name']}');
    // ignore: avoid_print
    print('');
  }
}
