// M8 模拟支付服务 - 实际集成时替换为微信/支付宝/Stripe
import 'package:flutter/foundation.dart';

enum PurchaseItem {
  fortuneReading('fortune_reading', '命理解读', 6),
  fateSlip('fate_slip', '天命签', 6),
  incense('incense', '线香', 1),
  lotusLamp('lotus_lamp', '莲花灯', 2),
  riverLamp('river_lamp', '河灯', 3),
  fulfillment('fulfillment', '还愿仪式', 3);
  final String id; final String label; final int priceYuan;
  const PurchaseItem(this.id, this.label, this.priceYuan);
}

enum PaymentStatus { pending, success, cancelled, failed }

class PaymentResult {
  final bool success; final String message; final PaymentStatus status; final PurchaseItem item;
  const PaymentResult({required this.success, required this.message, required this.status, required this.item});
}

class PaymentService {
  Future<PaymentResult> purchase(PurchaseItem item) async {
    debugPrint('[Payment] purchase:  ¥');
    await Future.delayed(const Duration(milliseconds: 800));
    return PaymentResult(success: true, message: '供奉成功', status: PaymentStatus.success, item: item);
  }

  Future<PaymentResult> mockPurchase(PurchaseItem item) async {
    debugPrint('[Payment] mock: ');
    await Future.delayed(const Duration(milliseconds: 300));
    return PaymentResult(success: true, message: '【模拟】供奉成功', status: PaymentStatus.success, item: item);
  }
}
