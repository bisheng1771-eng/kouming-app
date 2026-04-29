import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:kouming/shared/models/kouming_models.dart';

/// AI 服务 - 使用 Gemini API 免费额度
class AiService {
  static const _geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  // 从安全配置读取 API Key
  static String? _apiKey;
  static String? _proxy;

  static void configure({required String apiKey, String? proxy}) {
    _apiKey = apiKey;
    _proxy = proxy;
  }

  /// 快速检测网络是否可用
  Future<bool> _isNetworkAvailable() async {
    try {
      final result = await InternetAddress.lookup('generativelanguage.googleapis.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// 生成命理解读 — 双重保障：有网络走 API，无网络自动降级
  Future<Reading> generateReading(String wishText, String category) async {
    // 第一关：API Key 没配置，直接本地
    if (_apiKey == null) {
      return _fallbackReading(wishText, category);
    }

    // 第二关：快速网络检测，无网直接本地（避免等超时）
    final hasNetwork = await _isNetworkAvailable();
    if (!hasNetwork) {
      return _fallbackReading(wishText, category);
    }

    // 第三关：调 API，超时10秒，失败自动降级
    HttpClient? client;
    try {
      // 根据愿望内容生成独特的seed，确保不同愿望有不同解读
      final seed = wishText.hashCode.abs() % 10000;
      
      final prompt = '''你是一个智慧的心灵导师，有人写下了这个心愿："$wishText"。

请根据心愿内容生成独特的心灵指引，格式严格如下（不要加任何其他文字）：
卦象：[根据心愿内容生成一个富有诗意的标题]——[标题含义]
五行：[分析这个心愿背后的核心特质，如坚持、勇气、智慧等]
解读：[100-150字的个性化解读，要温暖有洞察力，针对"$wishText"给出具体共鸣]
建议：[一句具体可操作的建议]
相似：[随机数字300-800]个同路心愿，[随机数字50-200]个已实现

注意：
1. 解读必须针对"$wishText"这个具体心愿，不能是通用模板
2. 每次回复都要不同，seed=$seed
3. 用中文回复''';

      client = HttpClient();
      if (_proxy != null) {
        client.findProxy = (uri) => 'PROXY $_proxy';
      }
      client.connectionTimeout = const Duration(seconds: 10);

      final uri = Uri.parse('$_geminiEndpoint?key=$_apiKey');
      final request = await client.postUrl(uri)
          .timeout(const Duration(seconds: 10));
      request.headers.contentType = ContentType.json;

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.9,
          'maxOutputTokens': 500,
        }
      });

      request.write(body);
      final response = await request.close()
          .timeout(const Duration(seconds: 15));
      final responseBody = await response.transform(utf8.decoder).join()
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
        final text = json['candidates'][0]['content']['parts'][0]['text'] as String;
        return _parseReading(text, category);
      }

      // 非200状态码，降级
    } catch (e) {
      // 网络错误/超时/解析失败，降级到本地规则
    } finally {
      client?.close();
    }

    return _fallbackReading(wishText, category);
  }

  /// 解析 AI 返回的解读文本
  Reading _parseReading(String text, String category) {
    String hexagram = '';
    String element = '';
    String body = '';
    String advice = '';
    int similar = 100;
    int fulfilled = 30;

    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('卦象：') || trimmed.startsWith('卦象:')) {
        hexagram = trimmed.replaceFirst(RegExp(r'卦象[：:]'), '').trim();
      } else if (trimmed.startsWith('五行：') || trimmed.startsWith('五行:')) {
        element = trimmed.replaceFirst(RegExp(r'五行[：:]'), '').trim();
      } else if (trimmed.startsWith('解读：') || trimmed.startsWith('解读:')) {
        body = trimmed.replaceFirst(RegExp(r'解读[：:]'), '').trim();
      } else if (trimmed.startsWith('建议：') || trimmed.startsWith('建议:')) {
        advice = trimmed.replaceFirst(RegExp(r'建议[：:]'), '').trim();
      } else if (trimmed.startsWith('相似：') || trimmed.startsWith('相似:')) {
        final s = trimmed.replaceFirst(RegExp(r'相似[：:]'), '').trim();
        final match = RegExp(r'(\d+).*?(\d+)').firstMatch(s);
        if (match != null) {
          similar = int.parse(match.group(1)!);
          fulfilled = int.parse(match.group(2)!);
        }
      }
    }

    // 如果解析不完整，降级
    if (hexagram.isEmpty || body.isEmpty) {
      return _fallbackReading('', category);
    }

    return Reading(
      hexagram: hexagram,
      element: element,
      body: body,
      advice: advice,
      similarCount: similar,
      fulfilledCount: fulfilled,
    );
  }

  /// AI-powered semantic wish matching
  /// Returns the index of the most similar wish in the pool, or null if unavailable
  Future<int?> findSimilarWishIndex(
      String userWishText, List<String> poolTexts) async {
    if (_apiKey == null || poolTexts.isEmpty) return null;

    final hasNetwork = await _isNetworkAvailable();
    if (!hasNetwork) return null;

    HttpClient? client;
    try {
      final poolList = poolTexts.asMap().entries.map((e) => '${e.key}: "${e.value}"').join('\n');

      final prompt =
          'A user wished: "$userWishText"\n\nBelow is a list of wishes from the pool:\n$poolList\n\nWhich wish is most semantically similar to the user\'s wish? Reply with ONLY the index number (0-${poolTexts.length - 1}), nothing else.';

      client = HttpClient();
      if (_proxy != null) {
        client.findProxy = (uri) => 'PROXY $_proxy';
      }
      client.connectionTimeout = const Duration(seconds: 10);

      final uri = Uri.parse('$_geminiEndpoint?key=$_apiKey');
      final request =
          await client.postUrl(uri).timeout(const Duration(seconds: 10));
      request.headers.contentType = ContentType.json;

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens': 10,
        }
      });

      request.write(body);
      final response = await request
          .close()
          .timeout(const Duration(seconds: 10));
      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
        final text =
            json['candidates'][0]['content']['parts'][0]['text'] as String;
        final index = int.tryParse(text.trim());
        if (index != null && index >= 0 && index < poolTexts.length) {
          return index;
        }
      }
    } catch (_) {
      // Network error / timeout / parse failure
    } finally {
      client?.close();
    }

    return null;
  }

  /// 本地规则引擎降级方案
  Reading _fallbackReading(String wishText, String category) {
    // 根据愿望内容生成不同的本地降级解读
    final fallbackReadings = _generatePersonalizedFallback(wishText, category);
    
    final readings = {
      'study': fallbackReadings,
      'health': fallbackReadings,
      'love': fallbackReadings,
      'money': fallbackReadings,
      'default': fallbackReadings,
    };

    return readings[category] ?? fallbackReadings;
  }

  /// 生成个性化的本地降级解读
  Reading _generatePersonalizedFallback(String wishText, String category) {
    // 根据愿望内容生成不同的数字
    final seed = wishText.hashCode.abs();
    final rng = Random(seed);
    final similarCount = 200 + rng.nextInt(600);
    final fulfilledCount = 30 + rng.nextInt(170);
    
    // 根据类别选择不同的解读模板
    final templates = {
      'study': {
        'titles': ['渐卦——循序渐进', '蒙卦——启蒙', '需卦——等待时机'],
        'elements': ['水旺，需木疏', '火明，需土承', '金锐，需火炼'],
        'bodies': [
          '你的心愿里藏着一种焦灼——你很清楚自己要去哪里，但路途让你不安。\n\n池中有$similarCount个相似的心愿，其中$fulfilledCount个已经实现。他们上岸的方式各不相同，但都有一个共同点：在某个瞬间停止了焦虑，开始只做眼前的事。',
          '学习之路从来不是一蹴而就。你的心愿像一颗种子，需要时间和耐心才能发芽。\n\n池中有$similarCount个求学的心愿，$fulfilledCount个已经开花结果。记住，每一步都算数。',
        ],
        'advices': [
          '今天做一件具体的小事，比想一百遍未来有用。',
          '把大目标拆成每天可完成的小步骤，你会发现进步在不知不觉中发生。',
        ],
      },
      'health': {
        'titles': ['师卦——众志成城', '颐卦——养身', '复卦——复苏'],
        'elements': ['土厚，需水润', '木生，需土培', '水柔，需金导'],
        'bodies': [
          '关于"健康"的心愿，是池中最温暖的。每个人都有一位想要守护的人，包括自己。\n\n你许的这个心愿，让我看到了你的柔软。记住，健康不仅是身体，也是心灵的平和。',
          '身体是心灵的容器。你的心愿提醒我们，在追逐梦想的同时，别忘了照顾这个承载一切的容器。',
        ],
        'advices': [
          '照顾好自己，才是最好的祝愿。',
          '每天给自己10分钟的静心时间，身体和心灵都会感谢你。',
        ],
      },
      'love': {
        'titles': ['咸卦——感应', '恒卦——持久', '晋卦——进步'],
        'elements': ['火旺，需水济', '木柔，需金修', '土温，需火生'],
        'bodies': [
          '你在期待一个回应，但也许最好的爱情不是追来的，而是你在自己的路上走着，忽然发现旁边也有一个人在走同一条路。\n\n池中有$similarCount个关于爱的心愿，$fulfilledCount个已经找到了归属。',
          '爱不是等待被选择，而是先成为值得被选择的人。你的心愿像一盏灯，会吸引同样发光的人。',
        ],
        'advices': [
          '不要等待被选择，先选择自己。',
          '先爱自己，才有能力爱别人。',
        ],
      },
      'money': {
        'titles': ['丰卦——丰盛', '大有卦——拥有', '损卦——取舍'],
        'elements': ['金旺，需火炼', '水聚，需土堤', '火明，需木薪'],
        'bodies': [
          '你的愿望很直接，没有修饰。丰盛的前提是格局。你现在想要的不是钱本身，是钱能带来的东西——安全感、自由、选择权。\n\n池中有$similarCount个关于财富的心愿，$fulfilledCount个已经实现了财务自由。',
          '财富是工具，不是目的。你的心愿背后，是对更好生活的向往。这本身就很美好。',
        ],
        'advices': [
          '与其许愿发财，不如想想：你真正想要的那件东西，有没有不花钱的路？',
          '开源节流，先从小额储蓄开始，积少成多。',
        ],
      },
      'default': {
        'titles': ['临卦——亲临', '观卦——观察', '中孚卦——诚信'],
        'elements': ['五行调和', '阴阳相济', '动静相宜'],
        'bodies': [
          '许愿这件事本身就需要勇气——你得承认自己有所求，还得相信有什么东西在听。\n\n池中有$similarCount个相似的心愿，$fulfilledCount个已经实现。你的心愿现在沉在池底最安静的地方，它在等一个合适的时机浮上来。',
          '每一个心愿都是一颗星星，即使现在看不到，它也在发光。你的愿望已经被听见。',
        ],
        'advices': [
          '不要反复查看愿望有没有实现。最好的结果都发生在你忘了期待的时候。',
          '相信过程，享受当下，结果会自然到来。',
        ],
      },
    };

    final catTemplates = templates[category] ?? templates['default']!;
    final titleIdx = rng.nextInt(catTemplates['titles']!.length);
    final bodyIdx = rng.nextInt(catTemplates['bodies']!.length);
    final adviceIdx = rng.nextInt(catTemplates['advices']!.length);

    return Reading(
      hexagram: catTemplates['titles']![titleIdx],
      element: catTemplates['elements']![titleIdx],
      body: catTemplates['bodies']![bodyIdx],
      advice: catTemplates['advices']![adviceIdx],
      similarCount: similarCount,
      fulfilledCount: fulfilledCount,
    );
  }
}
