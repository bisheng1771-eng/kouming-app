import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

/// 支付宝 APP 支付服务
/// 
/// 流程：
/// 1. Flutter 调 Supabase Edge Function 获取签名订单
/// 2. 返回的 orderStr 通过 MethodChannel 传给原生 Android SDK 调起支付
/// 3. 支付结果回调返回 Flutter
class AlipayService {
  static const String _orderUrl = 
      'https://ibffrwevphkkbcfgaift.supabase.co/functions/v1/alipay-order';

  static const String _anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImliZmZyd2V2cGhra2JjZmdhaWZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxMDI3MTEsImV4cCI6MjA5MjY3ODcxMX0.hWJw5bnMTYfnox2BAk4_0DFDmMi-b2H4mTemZSwWwEA';

  static const MethodChannel _channel = 
      MethodChannel('com.kouming/alipay');

  /// 产品类型
  static const Map<String, Map<String, dynamic>> products = {
    'oracle': {'name': '算卦解读', 'price': 6.00},
    'fate':   {'name': '天命签',   'price': 6.00},
    'fulfill':{'name': '还愿仪式', 'price': 3.60},
  };

  /// 调起支付宝支付
  /// 
  /// [product] - 产品类型: 'oracle' | 'fate' | 'fulfill'
  /// [userId] - 用户 ID
  /// 返回: 'success' | 'failed' | 'canceled'
  static Future<String> pay({
    required String product,
    required String userId,
  }) async {
    try {
      // 第一步：调 Edge Function 获取签名订单
      final response = await _fetchOrder(product: product, userId: userId);
      
      if (response == null || response['orderStr'] == null) {
        print('[AlipayService] No orderStr returned');
        return 'failed';
      }

      final orderStr = response['orderStr'] as String;
      final outTradeNo = response['outTradeNo'] as String;
      
      print('[AlipayService] Order created: $outTradeNo');

      // 第二步：通过 MethodChannel 调起原生支付宝 SDK
      final result = await _callAlipaySdk(orderStr);
      
      print('[AlipayService] SDK result: $result');

      // 解析 resultStatus
      if (result != null && result['resultStatus'] != null) {
        switch (result['resultStatus']) {
          case '9000': return 'success';
          case '6001': return 'canceled';
          default: return 'failed';
        }
      }
      
      return 'failed';
    } catch (e) {
      print('[AlipayService] Error: $e');
      return 'failed';
    }
  }

  /// 调 Supabase Edge Function 获取签名订单
  static Future<Map<String, dynamic>?> _fetchOrder({
    required String product,
    required String userId,
  }) async {
    try {
      print('[AlipayService] Fetching order for product=$product, userId=$userId');
      
      final response = await http.post(
        Uri.parse(_orderUrl),
        headers: {
          'Content-Type': 'application/json',
          'apikey': _anonKey,
        },
        body: jsonEncode({
          'product': product,
          'userId': userId,
        }),
      );

      print('[AlipayService] Response status: ${response.statusCode}');
      print('[AlipayService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[AlipayService] Parsed data: $data');
        return data;
      } else {
        print('[AlipayService] Non-200 status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('[AlipayService] Fetch error: $e');
      print('[AlipayService] Stack trace: $stackTrace');
    }
    return null;
  }

  /// 通过 MethodChannel 调起原生支付宝 SDK
  static Future<Map<String, dynamic>?> _callAlipaySdk(String orderStr) async {
    try {
      print('[AlipayService] Calling Alipay SDK with orderStr length: ${orderStr.length}');
      
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('pay', {
        'orderStr': orderStr,
      });
      
      print('[AlipayService] SDK raw result: $result');
      
      if (result != null) {
        final typedResult = Map<String, dynamic>.from(result);
        print('[AlipayService] SDK typed result: $typedResult');
        return typedResult;
      } else {
        print('[AlipayService] SDK returned null');
      }
    } on PlatformException catch (e) {
      print('[AlipayService] PlatformException: code=${e.code}, message=${e.message}, details=${e.details}');
    } on MissingPluginException catch (e) {
      print('[AlipayService] MissingPluginException: $e');
    } catch (e) {
      print('[AlipayService] Unexpected error calling SDK: $e');
    }
    return null;
  }

  /// 获取产品价格
  static double getPrice(String product) {
    return products[product]?['price'] ?? 0.0;
  }

  /// 获取产品名称
  static String getName(String product) {
    return products[product]?['name'] ?? '';
  }
}

/// 支付结果状态码
class AlipayResultCode {
  static const String success  = '9000'; // 支付成功
  static const String canceled  = '6001'; // 用户取消
  static const String failed   = '4000'; // 支付失败
  static const String pending  = '8000'; // 支付结果确认中
}