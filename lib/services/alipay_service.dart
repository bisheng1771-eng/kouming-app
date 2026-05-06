import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart';

/// 支付宝 APP 支付服务
/// 
/// 流程：
/// 1. Flutter 调 Supabase Edge Function 获取订单数据（不含签名）
/// 2. 本地用私钥做 RSA2 签名
/// 3. 组装完整 orderStr 调起原生支付宝 SDK
class AlipayService {
  static const String _orderUrl = 
      'https://ibffrwevphkkbcfgaift.supabase.co/functions/v1/alipay-order';

  static const String _anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImliZmZyd2V2cGhra2JjZmdhaWZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxMDI3MTEsImV4cCI6MjA5MjY3ODcxMX0.hWJw5bnMTYfnox2BAk4_0DFDmMi-b2H4mTemZSwWwEA';

  static const MethodChannel _channel = 
      MethodChannel('com.kouming/alipay');

  /// 产品类型
  static const Map<String, Map<String, dynamic>> products = {
    'oracle':   {'name': '算卦解读', 'price': 6.00},
    'fate':     {'name': '天命签',   'price': 6.00},
    'fulfill':  {'name': '还愿仪式', 'price': 3.60},
    'incense':  {'name': '微光',     'price': 1.00},
    'lotus':    {'name': '花灯',     'price': 2.00},
    'river':    {'name': '长明灯',   'price': 3.00},
  };

  /// 是否使用模拟支付模式（用于测试，无需真实支付宝环境）
  /// true=测试模式(弹窗确认后直接成功) | false=真实支付宝链路
  static bool mockMode = false;

  /// 调起支付宝支付
  /// 
  /// [product] - 产品类型: 'oracle' | 'fate' | 'fulfill' | 'incense' | 'lotus' | 'river'
  /// [userId] - 用户 ID
  /// 返回: 'success' | 'failed' | 'canceled'
  static Future<String> pay({
    required String product,
    required String userId,
  }) async {
    try {
      // 模拟模式：直接返回成功，用于测试
      if (mockMode) {
        print('[AlipayService] MOCK MODE: Simulating payment for $product');
        await Future.delayed(const Duration(seconds: 1));
        print('[AlipayService] MOCK MODE: Payment success');
        return 'success';
      }

      // 第一步：调 Edge Function 获取订单数据（不含签名）
      print('[AlipayService] Step 1: Fetching order data from Edge Function...');
      final response = await _fetchOrder(product: product, userId: userId);
      
      print('[AlipayService] Step 1 complete: $response');
      
      if (response == null || response['orderData'] == null) {
        print('[AlipayService] ERROR: orderData is null');
        return 'failed';
      }

      final orderData = Map<String, dynamic>.from(response['orderData'] as Map);
      final outTradeNo = response['outTradeNo'] as String;
      
      print('[AlipayService] Order created: $outTradeNo');

      // 第二步：本地 RSA2 签名
      print('[AlipayService] Step 2: RSA2 signing...');
      final sign = await _rsa2Sign(orderData);
      
      if (sign == null) {
        print('[AlipayService] ERROR: RSA2 signing failed');
        return 'failed';
      }
      
      orderData['sign'] = sign;

      // 第三步：组装 orderStr
      final orderStr = _encodeOrderData(orderData);
      print('[AlipayService] Step 3: orderStr ready, length=${orderStr.length}');

      // 第四步：调起支付宝 SDK
      final result = await _callAlipaySdk(orderStr);
      print('[AlipayService] Step 4: SDK result: $result');

      if (result != null && result['resultStatus'] != null) {
        switch (result['resultStatus'].toString()) {
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

  /// RSA2 签名：使用硬编码的 RSA 私钥参数，SHA256withRSA
  static Future<String?> _rsa2Sign(Map<String, dynamic> orderData) async {
    try {
      // 新 RSA 私钥参数（2026-05-06 重新生成的一对密钥）
      // 2026-05-06 新私钥 PKCS#1 提取，n/e/d/p/q/dp/dq/qi
      final n = BigInt.parse(
          "0xe91a72bb0e52bf97bfddce5f3a24211a36a68d4fd6e9cd300c975837b22bb09f107d087d3dfd51a7eaaf70d4f41c7cb46815894bc2f6539cff0ba875e13b16a0aeb66662a1d97f6f00ad0eb6505699cbc1c083e4f33c34fac5b97d9246e66bda729852762ba08b78b4b23cce0366a0139ab36836deca7d26db5e6d5bdecf217cfbe0ebecd590decf1573799cb769365e70574ed9d898e4309472e583ed469b08eac58f70641b1e8957fc5cda7eacb47d9bde4453bbfe63de1359ef9b777767def2d50a8c8c7bf69a9bce8ac7846d33689ed32a991c42ce171831cb4d0d672fc5e03a0c99cbb16f0e666e9672f2829c52e75472ae6a75a932dfadc7c835442a9f",
          radix: 16);
      final e = BigInt.parse("0x10001", radix: 16);
      final d = BigInt.parse(
          "0x7c0fd78036df539930449cd191e028be0ad819dda4444b30878305309f63215d8729049ba3a26f132f94b038a6b382ab81b9f4989deafc1552a8a1c01b5f976b6d91266cd83729dbaa4070d4176dffecb1f20440963434fe42bdb65763e4bf02447b4d6817501aeae340f99babb3b2febc17401ff3f351289d18649bc0b9fcd7c3f53bf3d5d235d51c0a3b48ac70c0f425ac58d8e657008e2d1dbc81c1d94de0e83a04f6a76f23b8abef33fa477e542d385304ced403a5a2d1524efdba2272007e46156a91152489d761f85c80fad433ac2c313c365f299b7ca47f05a2c293a5591ab16edabb196b4fe5ddac13156a27b51a958d69a816cdf35de6b10f884801",
          radix: 16);
      final p = BigInt.parse(
          "0xfeb6c390f46295ffbee6fceec701ca59c92af739c5bfb9d374ed73b00156f4b8905e5abd35ae6f97d39380c9a7bc02bd3b8838d8c750829d4cc73184501df45942a9fed56f98ab3095ab3e828e63ce2768a65f5ce138edf73a03656c557f8b75e924508427e5f58be5bc4122f5613916222543285ed184a8f711b02c199fa68f",
          radix: 16);
      final q = BigInt.parse(
          "0xea47c03f90d0410177ab515375daa41d43d2a2be2458a528a6028e3ff86b8aa481a9933a22dfaf1ef73313a8980d24fbf08a34915204d359448a0ce2f2810dce24245339e22ca5d7f831be6c77826dd694d354916e09a409fad5a6dc3e2f9484b733b841b465a19fcac97c2afe0f16b18096726694687bfb09a36aa42a40c2f1",
          radix: 16);
      final dp = BigInt.parse(
          "0x72ac53957200e469144827fd54090151b4d8ac1f0d6148c6e37077d1f8786e8a9d2c6d8b9b9c61cf27c8d385760795f01dda31459f4e26cfac9e4d33b56216fd0c9f3e04574e935bb73636594ec3ae2f5dd4f13ffe81c3d8b6fc8a6fe07a208e401d42468d33e17d4f3b96d3a747530d1ce84bb8e41f4dab48386569254c140f",
          radix: 16);
      final dq = BigInt.parse(
          "0x1aa2bbb5be661eede6c8207fe7a74aff54c5aee1054adac42b53a10e9ed4c3377ed263bdb9574b16af2e2c6eff928700e9d11cb6e4e74d8c19a1c4634d04e527e9ae0394522597595d8b7245ecb4747e6fff32df31ee80aaedccbaa2d1a32134918b9cc843954671df6156efa060e0c89f80fb52b44ec8c1bacfcc810b98bf51",
          radix: 16);
      final qi = BigInt.parse(
          "0xad7ba933fac9460c03400f2ebaa377f2a6ed1119412852e8fe251ded383ea6897e89fe51af6a4b4c2a8b91e3b734d64f6d3d27a90c2060271524fa2a7d17a06d5bbfe75c0051a59056f722dc0ae5cacf85cb785c6c2131489cb5a78062af46a77bca29854141ab38971b0b366cb065bc0f2b429a0205169ae58d07b78dd6e06c",
          radix: 16);

      final privateKey = RSAPrivateKey(n, e, d, p, q);
      print('[AlipayService] RSA key constructed: bits=${privateKey.modulus!.bitLength}');

      // 构建待签名串：按 key 排序，拼接成 key=value&key=value
      final toSign = _buildSignString(orderData);
      print('[AlipayService] String to sign: $toSign');

      // SHA256 with RSA 签名
      final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
      signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
      final sigBytes = signer.generateSignature(Uint8List.fromList(toSign.codeUnits)) as Uint8List;
      
      final signBase64 = base64Encode(sigBytes);
      print('[AlipayService] Sign: ${signBase64.substring(0, 20)}...');
      return signBase64;
      
    } catch (e, st) {
      print('[AlipayService] RSA2 sign error: $e');
      print('[AlipayService] Stack: $st');
      return null;
    }
  }

  /// 构建待签名字符串（按 ASCII 排序，key=value&key=value，value 不编码）
  /// 支付宝签名规范：所有请求参数（不含sign和sign_type）按key排序拼接
  static String _buildSignString(Map<String, dynamic> data) {
    final sortedKeys = data.keys
        .where((k) => k != 'sign' && k != 'sign_type')
        .toList()..sort();
    return sortedKeys.map((k) => '$k=${data[k]}').join('&');
  }

  /// 编码为支付宝 orderStr
  /// 支付宝 APP 支付 orderStr 格式：
  /// biz_content 需 URL 编码，其他字段值不编码
  /// sign 需 URL 编码
  static String _encodeOrderData(Map<String, dynamic> data) {
    final sortedKeys = data.keys.toList()..sort();
    return sortedKeys.map((k) {
      final v = data[k];
      if (v == null) return null;
      final vStr = v.toString();
      // biz_content 和 sign 的值需要 URL 编码
      if (k == 'biz_content' || k == 'sign') {
        return '$k=${Uri.encodeComponent(vStr)}';
      }
      return '$k=$vStr';
    }).whereType<String>().join('&');
  }

  /// 调 Edge Function 获取订单数据
  static Future<Map<String, dynamic>?> _fetchOrder({
    required String product,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_orderUrl),
        headers: {
          'Content-Type': 'application/json',
          'apikey': _anonKey,
        },
        body: jsonEncode({'product': product, 'userId': userId}),
      );
      print('[AlipayService] Edge response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('[AlipayService] Fetch error: $e');
    }
    return null;
  }

  /// 调原生支付宝 SDK
  static Future<Map<String, dynamic>?> _callAlipaySdk(String orderStr) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('pay', {
        'orderStr': orderStr,
      });
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } on PlatformException catch (e) {
      print('[AlipayService] PlatformException: ${e.code} ${e.message}');
    } on MissingPluginException catch (e) {
      print('[AlipayService] MissingPluginException: $e');
    } catch (e) {
      print('[AlipayService] SDK error: $e');
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
