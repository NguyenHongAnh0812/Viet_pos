import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_payment_setting.dart';

class AppPaymentSettingService {
  final _doc = FirebaseFirestore.instance.collection('app_settings').doc('payment');

  Future<AppPaymentSetting?> getSetting() async {
    final snap = await _doc.get();
    if (!snap.exists) return null;
    return AppPaymentSetting.fromFirestore(snap.data()!);
  }

  Future<void> updateSetting(AppPaymentSetting setting) async {
    await _doc.set(setting.toMap());
  }
} 