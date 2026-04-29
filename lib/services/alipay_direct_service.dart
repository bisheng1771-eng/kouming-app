import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:rsa_pkcs/rsa_pkcs.dart' as rsa_pkcs;

/// 支付宝直接支付服务（Flutter端生成签名）
/// 
/// ⚠️ 安全警告：此方案将私钥存储在客户端，仅用于测试阶段
/// 生产环境应使用服务器端签名（Edge Function/云函数）
class AlipayDirectService {
  static const MethodChannel _channel = 
      MethodChannel('com.kouming/alipay');

  // 支付宝配置
  static const String _appId = '2021006149691180';
  static const String _gateway = 'https://openapi.alipay.com/gateway.do';
  static const String _notifyUrl = 
      'https://ibffrwevphkkbcfgaift.supabase.co/functions/v1/alipay-notify';

  // 产品配置
  static const Map<String, Map<String, dynamic>> products = {
    'oracle': {'name': '算卦解读', 'price': 6.00},
    'fate':   {'name': '天命签',   'price': 6.00},
    'fulfill':{'name': '还愿仪式', 'price': 3.60},
  };

  /// 调起支付宝支付
  static Future<String> pay({
    required String product,
    required String userId,
  }) async {
    try {
      // 生成订单
      final orderData = await _createOrder(product: product, userId: userId);
      
      if (orderData == null) {
        print('[AlipayDirect] Failed to create order');
        return 'failed';
      }

      final orderStr = orderData['orderStr'] as String;
      
      print('[AlipayDirect] Order created, calling SDK...');

      // 调起支付宝 SDK
      final result = await _channel.invokeMethod('payV2', {'orderInfo': orderStr});
      
      print('[AlipayDirect] SDK result: $result');

      if (result != null && result['resultStatus'] != null) {
        switch (result['resultStatus']) {
          case '9000': return 'success';
          case '6001': return 'canceled';
          default: return 'failed';
        }
      }
      
      return 'failed';
    } catch (e) {
      print('[AlipayDirect] Error: $e');
      return 'failed';
    }
  }

  /// 创建订单并生成签名
  static Future<Map<String, dynamic>?> _createOrder({
    required String product,
    required String userId,
  }) async {
    try {
      final productInfo = products[product];
      if (productInfo == null) return null;

      final outTradeNo = _generateTradeNo();
      final timestamp = _formatDateTime(DateTime.now());

      // 构建请求参数
      final bizContent = jsonEncode({
        'out_trade_no': outTradeNo,
        'total_amount': productInfo['price'].toString(),
        'subject': productInfo['name'],
        'product_code': 'QUICK_MSECURITY_PAY',
      });

      final params = {
        'app_id': _appId,
        'method': 'alipay.trade.app.pay',
        'charset': 'utf-8',
        'sign_type': 'RSA2',
        'timestamp': timestamp,
        'version': '1.0',
        'notify_url': _notifyUrl,
        'biz_content': bizContent,
      };

      // 生成签名
      final sign = await _generateSignature(params);
      if (sign == null) {
        print('[AlipayDirect] Failed to generate signature');
        return null;
      }

      params['sign'] = sign;

      // 构建 orderStr
      final orderStr = _buildOrderString(params);

      return {
        'orderStr': orderStr,
        'outTradeNo': outTradeNo,
        'amount': productInfo['price'],
      };
    } catch (e) {
      print('[AlipayDirect] Create order error: $e');
      return null;
    }
  }

  /// 生成签名
  static Future<String?> _generateSignature(Map<String, String> params) async {
    try {
      // 排序并拼接参数
      final sortedKeys = params.keys.toList()..sort();
      final content = sortedKeys
          .map((k) => '$k=${params[k]}')
          .join('&');

      print('[AlipayDirect] Sign content: $content');

      // TODO: 使用私钥签名
      // 这里需要实现 RSA 签名，或者使用平台通道调用原生代码签名
      // 暂时返回 null，需要后续实现
      
      return null;
    } catch (e) {
      print('[AlipayDirect] Sign error: $e');
      return null;
    }
  }

  /// 构建订单字符串
  static String _buildOrderString(Map<String, String> params) {
    final sortedKeys = params.keys.toList()..sort();
    return sortedKeys
        .map((k) => '$k=${Uri.encodeComponent(params[k]!)}')
        .join('&');
  }

  /// 生成商户订单号
  static String _generateTradeNo() {
    final now = DateTime.now();
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'KM${now.millisecondsSinceEpoch}$random';
  }

  /// 格式化时间
  static String _formatDateTime(DateTime dt) {
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
        '${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
