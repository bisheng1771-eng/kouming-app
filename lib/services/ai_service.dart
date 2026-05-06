import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:kouming/shared/models/kouming_models.dart';

/// AI 服务 - 使用阿里云百炼 API（国内直连，无需VPN）
class AiService {
  // 阿里云百炼（国内直连）
  static const _dashscopeEndpoint =
      'https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation';

  // Gemini（备用，需要VPN）
  static const _geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  // 从安全配置读取 API Key
  static String? _apiKey;
  static String? _proxy;
  static String? _fallbackApiKey; // 备用API Key（阿里云百炼）

  static void configure({
    required String apiKey,
    String? proxy,
    String? fallbackApiKey,
  }) {
    _apiKey = apiKey;
    _proxy = proxy;
    _fallbackApiKey = fallbackApiKey;
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

  /// 64卦定义：卦名、卦象符号、核心含义
  static const _hexagrams = [
    {'name': '乾卦', 'symbol': '☰', 'meaning': '天行健，君子以自强不息', 'trigram': [true, true, true]},
    {'name': '坤卦', 'symbol': '☷', 'meaning': '地势坤，君子以厚德载物', 'trigram': [false, false, false]},
    {'name': '屯卦', 'symbol': '☳☵', 'meaning': '水雷屯，君子以经纶', 'trigram': [false, false, true, false, true, false]},
    {'name': '蒙卦', 'symbol': '☵☳', 'meaning': '山水蒙，君子以果行育德', 'trigram': [true, false, false, false, false, true]},
    {'name': '需卦', 'symbol': '☵☰', 'meaning': '水天需，君子以饮食宴乐', 'trigram': [true, true, true, true, false, false]},
    {'name': '讼卦', 'symbol': '☰☵', 'meaning': '天水讼，君子以作事谋始', 'trigram': [false, false, true, true, true, true]},
    {'name': '师卦', 'symbol': '☵☷', 'meaning': '地水师，君子以容民畜众', 'trigram': [false, false, false, true, false, false]},
    {'name': '比卦', 'symbol': '☷☵', 'meaning': '水地比，君子以建国亲诸侯', 'trigram': [false, false, true, false, false, false]},
    {'name': '小畜卦', 'symbol': '☴☰', 'meaning': '风天小畜，君子以懿文德', 'trigram': [true, true, true, false, true, false]},
    {'name': '履卦', 'symbol': '☰☱', 'meaning': '天泽履，君子以辨上下定民志', 'trigram': [false, true, true, true, true, true]},
    {'name': '泰卦', 'symbol': '☷☰', 'meaning': '天地泰，君子以财成天地之道', 'trigram': [true, true, true, false, false, false]},
    {'name': '否卦', 'symbol': '☰☷', 'meaning': '天地否，君子以俭德辟难', 'trigram': [false, false, false, true, true, true]},
    {'name': '同人卦', 'symbol': '☰☲', 'meaning': '天火同人，君子以类族辨物', 'trigram': [false, true, false, true, true, true]},
    {'name': '大有卦', 'symbol': '☲☰', 'meaning': '火天大有，君子以遏恶扬善', 'trigram': [true, true, true, false, true, false]},
    {'name': '谦卦', 'symbol': '☷☶', 'meaning': '地山谦，君子以裒多益寡', 'trigram': [true, false, false, false, false, false]},
    {'name': '豫卦', 'symbol': '☳☷', 'meaning': '雷地豫，君子以作乐崇德', 'trigram': [false, false, false, false, true, false]},
    {'name': '随卦', 'symbol': '☱☳', 'meaning': '泽雷随，君子以向晦入宴息', 'trigram': [false, true, false, false, true, true]},
    {'name': '蛊卦', 'symbol': '☶☴', 'meaning': '山风蛊，君子以振民育德', 'trigram': [false, true, false, true, false, false]},
    {'name': '临卦', 'symbol': '☷☱', 'meaning': '地泽临，君子以教思无穷', 'trigram': [false, true, true, false, false, false]},
    {'name': '观卦', 'symbol': '☴☷', 'meaning': '风地观，君子以省方观民设教', 'trigram': [false, false, false, false, true, false]},
    {'name': '噬嗑卦', 'symbol': '☲☳', 'meaning': '火雷噬嗑，君子以明罚敕法', 'trigram': [false, true, false, false, true, false]},
    {'name': '贲卦', 'symbol': '☶☲', 'meaning': '山火贲，君子以明庶政', 'trigram': [false, true, false, true, false, false]},
    {'name': '剥卦', 'symbol': '☶☷', 'meaning': '山地剥，君子以厚下安宅', 'trigram': [false, false, false, true, false, false]},
    {'name': '复卦', 'symbol': '☷☳', 'meaning': '地雷复，君子以闭关修省', 'trigram': [false, true, false, false, false, false]},
    {'name': '无妄卦', 'symbol': '☰☳', 'meaning': '天雷无妄，君子以茂对时育万物', 'trigram': [false, true, false, true, true, true]},
    {'name': '大畜卦', 'symbol': '☶☰', 'meaning': '山天大畜，君子以多识前言往行', 'trigram': [true, true, true, true, false, false]},
    {'name': '颐卦', 'symbol': '☶☳', 'meaning': '山雷颐，君子以慎言语节饮食', 'trigram': [false, true, false, true, false, false]},
    {'name': '大过卦', 'symbol': '☱☴', 'meaning': '泽风大过，君子以独立不惧遁世无闷', 'trigram': [false, true, false, false, true, true]},
    {'name': '坎卦', 'symbol': '☵', 'meaning': '水洊至，君子以常德行习教事', 'trigram': [false, true, false]},
    {'name': '离卦', 'symbol': '☲', 'meaning': '明两作，大人以继明照于四方', 'trigram': [true, false, true]},
    {'name': '咸卦', 'symbol': '☱☶', 'meaning': '山泽咸，君子以虚受人', 'trigram': [true, false, false, false, true, true]},
    {'name': '恒卦', 'symbol': '☴☳', 'meaning': '雷风恒，君子以立不易方', 'trigram': [false, true, false, false, true, false]},
    {'name': '遁卦', 'symbol': '☰☶', 'meaning': '天山遁，君子以远小人不恶而严', 'trigram': [true, false, false, true, true, true]},
    {'name': '大壮卦', 'symbol': '☳☰', 'meaning': '雷天大壮，君子以非礼弗履', 'trigram': [true, true, true, false, true, false]},
    {'name': '晋卦', 'symbol': '☲☷', 'meaning': '火地晋，君子以自昭明德', 'trigram': [false, false, false, false, true, false]},
    {'name': '明夷卦', 'symbol': '☷☲', 'meaning': '地火明夷，君子以莅众用晦而明', 'trigram': [false, true, false, false, false, false]},
    {'name': '家人卦', 'symbol': '☴☲', 'meaning': '风火家人，君子以言有物而行有恒', 'trigram': [false, true, false, false, true, false]},
    {'name': '睽卦', 'symbol': '☲☱', 'meaning': '火泽睽，君子以同而异', 'trigram': [false, true, true, false, true, false]},
    {'name': '蹇卦', 'symbol': '☵☶', 'meaning': '水山蹇，君子以反身修德', 'trigram': [true, false, false, true, false, false]},
    {'name': '解卦', 'symbol': '☳☵', 'meaning': '雷水解，君子以赦过宥罪', 'trigram': [false, false, true, false, true, false]},
    {'name': '损卦', 'symbol': '☶☱', 'meaning': '山泽损，君子以惩忿窒欲', 'trigram': [false, true, true, true, false, false]},
    {'name': '益卦', 'symbol': '☴☵', 'meaning': '风雷益，君子以见善则迁', 'trigram': [false, false, true, false, true, false]},
    {'name': '夬卦', 'symbol': '☱☰', 'meaning': '泽天夬，君子以施禄及下', 'trigram': [true, true, true, false, true, true]},
    {'name': '姤卦', 'symbol': '☰☴', 'meaning': '天风姤，君子以施命诰四方', 'trigram': [false, true, false, true, true, true]},
    {'name': '萃卦', 'symbol': '☱☷', 'meaning': '泽地萃，君子以除戎器戒不虞', 'trigram': [false, false, false, false, true, true]},
    {'name': '升卦', 'symbol': '☷☴', 'meaning': '地风升，君子以顺德积小以高大', 'trigram': [false, true, false, false, false, false]},
    {'name': '困卦', 'symbol': '☵☱', 'meaning': '泽水困，君子以致命遂志', 'trigram': [false, true, true, true, false, false]},
    {'name': '井卦', 'symbol': '☴☵', 'meaning': '水风井，君子以劳民劝相', 'trigram': [false, false, true, false, true, false]},
    {'name': '革卦', 'symbol': '☱☲', 'meaning': '泽火革，君子以治历明时', 'trigram': [false, true, false, false, true, true]},
    {'name': '鼎卦', 'symbol': '☲☱', 'meaning': '火风鼎，君子以正位凝命', 'trigram': [false, true, true, false, true, false]},
    {'name': '震卦', 'symbol': '☳', 'meaning': '洊雷震，君子以恐惧修省', 'trigram': [false, false, true]},
    {'name': '艮卦', 'symbol': '☶', 'meaning': '兼山艮，君子以思不出其位', 'trigram': [true, false, false]},
    {'name': '渐卦', 'symbol': '☴☶', 'meaning': '风山渐，君子以居贤德善俗', 'trigram': [true, false, false, false, true, false]},
    {'name': '归妹卦', 'symbol': '☱☳', 'meaning': '雷泽归妹，君子以永终知敝', 'trigram': [false, true, false, false, true, true]},
    {'name': '丰卦', 'symbol': '☲☳', 'meaning': '雷火丰，君子以折狱致刑', 'trigram': [false, true, false, false, true, false]},
    {'name': '旅卦', 'symbol': '☶☲', 'meaning': '火山旅，君子以明慎用刑', 'trigram': [false, true, false, true, false, false]},
    {'name': '巽卦', 'symbol': '☴', 'meaning': '随风巽，君子以申命行事', 'trigram': [false, true, false]},
    {'name': '兑卦', 'symbol': '☱', 'meaning': '丽泽兑，君子以朋友讲习', 'trigram': [false, true, true]},
    {'name': '涣卦', 'symbol': '☴☵', 'meaning': '风水涣，君子以享于上帝立庙', 'trigram': [false, false, true, false, true, false]},
    {'name': '节卦', 'symbol': '☵☱', 'meaning': '水泽节，君子以制数度议德行', 'trigram': [false, true, true, true, false, false]},
    {'name': '中孚卦', 'symbol': '☱☴', 'meaning': '风泽中孚，君子以议狱缓死', 'trigram': [false, true, false, false, true, true]},
    {'name': '小过卦', 'symbol': '☶☳', 'meaning': '雷山小过，君子以行过乎恭', 'trigram': [false, true, false, true, false, false]},
    {'name': '既济卦', 'symbol': '☵☲', 'meaning': '水火既济，君子以思患而豫防之', 'trigram': [false, true, false, true, false, false]},
    {'name': '未济卦', 'symbol': '☲☵', 'meaning': '火水未济，君子以慎辨物居方', 'trigram': [false, false, true, false, true, false]},
  ];

  /// 根据心愿内容选择最合适的卦象
  Map<String, dynamic> _selectHexagram(String wishText, String category) {
    // 根据心愿内容生成确定性哈希
    final hash = wishText.hashCode.abs();
    final rng = Random(hash);
    
    // 根据类别优先选择相关卦象
    List<int> candidates;
    switch (category) {
      case 'study':
        candidates = [0, 3, 4, 13, 25, 26, 46]; // 乾、蒙、需、大有、无妄、大畜、升
        break;
      case 'health':
        candidates = [1, 6, 26, 27, 28, 36, 52]; // 坤、师、大畜、颐、大过、明夷、艮
        break;
      case 'love':
        candidates = [30, 31, 36, 37, 53, 54]; // 咸、恒、明夷、家人、渐、归妹
        break;
      case 'money':
        candidates = [0, 13, 14, 15, 34, 44, 45]; // 乾、大有、谦、豫、大壮、姤、萃
        break;
      default:
        candidates = [0, 1, 10, 11, 18, 19, 23, 24]; // 通用卦象
    }
    
    final idx = candidates[rng.nextInt(candidates.length)];
    return _hexagrams[idx];
  }

  /// 生成命理解读 — 双重保障：有网络走 API，无网络自动降级
  Future<Reading> generateReading(String wishText, String category) async {
    // 先选择卦象（本地确定性的）
    final hexagram = _selectHexagram(wishText, category);
    
    // 第一关：API Key 没配置，直接本地
    if (_apiKey == null) {
      print('[AiService] API Key 未配置，使用本地兜底');
      return _generateLocalReading(wishText, category, hexagram);
    }

    // 第二关：快速网络检测，无网直接本地（避免等超时）
    final hasNetwork = await _isNetworkAvailable();
    if (!hasNetwork) {
      print('[AiService] 网络不可用，使用本地兜底');
      return _generateLocalReading(wishText, category, hexagram);
    }
    
    // 第三关：先尝试 Gemini API（需要VPN），失败再试阿里云百炼
    print('[AiService] 开始调用 Gemini API...');
    final geminiResult = await _callGemini(wishText, category, hexagram);
    if (geminiResult != null) return geminiResult;
    
    // Gemini 失败，尝试阿里云百炼（国内直连，无需VPN）
    if (_fallbackApiKey != null) {
      print('[AiService] Gemini 失败，尝试阿里云百炼...');
      final dashScopeResult = await _callDashScope(wishText, category, hexagram);
      if (dashScopeResult != null) return dashScopeResult;
    }

    return _generateLocalReading(wishText, category, hexagram);
  }

  /// 调用阿里云百炼 API（国内直连，无需VPN）
  Future<Reading?> _callDashScope(
      String wishText, String category, Map<String, dynamic> hexagram) async {
    HttpClient? client;
    try {
      final prompt = '''用户的心愿："$wishText"

请根据周易学说，为这个心愿选择一个最合适的卦象，并给出解读和建议。

要求：
1. 先明确说出你选择的卦象名称（如"乾卦"、"坤卦"等64卦之一）
2. 解读必须紧密结合用户的心愿内容和所选卦象，分析含义和发展趋势（80字以上）
3. 建议必须针对这个心愿给出具体可行的行动方向（30字以上）
4. 每次解读要有不同的角度和侧重点，避免重复相同的套话
5. 用温暖、有洞察力的大白话

格式：
卦象：[卦名]
解读：[内容]
建议：[内容]''';

      // 添加随机性：每次使用不同的温度参数
      final randomTemp = 0.7 + Random().nextDouble() * 0.3; // 0.7-1.0

      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final uri = Uri.parse(_dashscopeEndpoint);
      final request = await client.postUrl(uri)
          .timeout(const Duration(seconds: 10));
      request.headers.contentType = ContentType.json;
      request.headers.add('Authorization', 'Bearer $_fallbackApiKey');

      final body = jsonEncode({
        'model': 'qwen-turbo', // 使用通义千问 Turbo 模型（性价比高）
        'input': {
          'messages': [
            {
              'role': 'system',
              'content': '你是一位精通周易的命理大师，擅长用现代大白话解读卦象，给出温暖有洞察力的建议。'
            },
            {
              'role': 'user',
              'content': prompt
            }
          ]
        },
        'parameters': {
          'temperature': randomTemp,
          'max_tokens': 600,
          'result_format': 'message',
        }
      });

      request.write(body);
      final response = await request.close()
          .timeout(const Duration(seconds: 15));
      final responseBody = await response.transform(utf8.decoder).join()
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
        // 阿里云百炼返回格式：output.choices[0].message.content
        final text = json['output']?['choices']?[0]?['message']?['content'] as String?;
        if (text != null && text.isNotEmpty) {
          print('[AiService] 阿里云百炼调用成功，返回内容长度: ${text.length}');
          return _parseReading(text, category, hexagram);
        }
      }

      print('[AiService] 阿里云百炼返回非200或内容为空: ${response.statusCode}');
    } catch (e) {
      print('[AiService] 阿里云百炼调用异常: $e');
    } finally {
      client?.close();
    }
    return null;
  }

  /// 调用 Gemini API（需要VPN/代理）
  Future<Reading?> _callGemini(
      String wishText, String category, Map<String, dynamic> hexagram) async {
    HttpClient? client;
    try {
      final prompt = '''用户的心愿："$wishText"

请根据周易学说，为这个心愿选择一个最合适的卦象，并给出解读和建议。

要求：
1. 先明确说出你选择的卦象名称（如"乾卦"、"坤卦"等64卦之一）
2. 解读必须紧密结合用户的心愿内容和所选卦象，分析含义和发展趋势（80字以上）
3. 建议必须针对这个心愿给出具体可行的行动方向（30字以上）
4. 每次解读要有不同的角度和侧重点，避免重复相同的套话
5. 用温暖、有洞察力的大白话

格式：
卦象：[卦名]
解读：[内容]
建议：[内容]''';

      final randomTemp = 0.7 + Random().nextDouble() * 0.3;

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
          'temperature': randomTemp,
          'maxOutputTokens': 600,
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
        print('[AiService] Gemini 调用成功，返回内容长度: ${text.length}');
        return _parseReading(text, category, hexagram);
      }

      print('[AiService] Gemini 返回非200状态码: ${response.statusCode}');
    } catch (e) {
      print('[AiService] Gemini 调用异常: $e');
    } finally {
      client?.close();
    }
    return null;
  }

  /// 解析 AI 返回的解读文本
  Reading _parseReading(String text, String category, Map<String, dynamic> defaultHexagram) {
    String interpretation = '';
    String advice1 = '';
    String? aiHexagramName;
    
    // 多行解析：解读和建议可能跨多行
    final lines = text.split('\n');
    String currentSection = '';
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('卦象') || trimmed.startsWith('【卦象】')) {
        aiHexagramName = trimmed.replaceFirst(RegExp(r'卦象[：:\s【】]*'), '').trim();
        // 去掉"卦"字后缀统一匹配
        aiHexagramName = aiHexagramName?.replaceAll('卦', '').trim();
      } else if (trimmed.startsWith('解读') || trimmed.startsWith('【解读】')) {
        currentSection = 'interpretation';
        final content = trimmed.replaceFirst(RegExp(r'解读[：:\s【】]*'), '').trim();
        if (content.isNotEmpty) interpretation += content + '\n';
      } else if (trimmed.startsWith('建议') || trimmed.startsWith('【建议】')) {
        currentSection = 'advice';
        final content = trimmed.replaceFirst(RegExp(r'建议[：:\s【】]*'), '').trim();
        if (content.isNotEmpty) advice1 += content + '\n';
      } else if (currentSection == 'interpretation' && trimmed.isNotEmpty) {
        interpretation += trimmed + '\n';
      } else if (currentSection == 'advice' && trimmed.isNotEmpty) {
        advice1 += trimmed + '\n';
      }
    }
    
    interpretation = interpretation.trim();
    advice1 = advice1.trim();

    // 查找 AI 指定的卦象
    Map<String, dynamic> finalHexagram = defaultHexagram;
    if (aiHexagramName != null && aiHexagramName.isNotEmpty) {
      // 尝试匹配64卦
      for (final h in _hexagrams) {
        final name = (h['name'] as String).replaceAll('卦', '');
        if (name == aiHexagramName || (h['name'] as String) == '$aiHexagramName卦') {
          finalHexagram = h;
          print('[AiService] AI 选择卦象: ${h['name']}');
          break;
        }
      }
    }

    // 如果解析失败或太短，使用本地生成
    if (interpretation.length < 30) {
      interpretation = '此卦为${finalHexagram['name']}，${finalHexagram['meaning']}。你的心愿蕴含着独特的能量，卦象显示这是一个需要耐心与坚持的旅程。保持内心的平静与信念，顺势而为，终将得偿所愿。';
    }
    if (advice1.length < 15) {
      advice1 = '基于${finalHexagram['name']}的启示：保持初心，脚踏实地，每天为心愿做一件小事。相信时间的力量，最好的结果往往在不经意间到来。';
    }

    return Reading(
      hexagram: '${finalHexagram['name']} ${finalHexagram['symbol']}',
      interpretation: interpretation,
      advice1: advice1,
      similarCount: Random().nextInt(400) + 200,
      fulfilledCount: Random().nextInt(80) + 40,
    );
  }

  /// 生成本地完整解读（无网络时使用）
  Reading _generateLocalReading(String wishText, String category, Map<String, dynamic> hexagram) {
    final name = hexagram['name'];
    final meaning = hexagram['meaning'];
    
    return Reading(
      hexagram: '${hexagram['name']} ${hexagram['symbol']}',
      interpretation: '此卦为$name，$meaning。你的心愿蕴含着独特的能量，卦象显示这是一个需要耐心与坚持的旅程。正如周易所言，万物皆有定时，你的愿望正在积蓄力量，等待合适的时机绽放。保持内心的平静与信念，顺势而为，终将得偿所愿。',
      advice1: '基于$name的启示：第一，保持初心，不要被外界的纷扰动摇；第二，脚踏实地，每天为心愿做一件小事；第三，相信时间的力量，最好的结果往往在不经意间到来。记住，$meaning。',
      similarCount: Random().nextInt(400) + 200,
      fulfilledCount: Random().nextInt(80) + 40,
    );
  }

  /// 根据祈福签签名生成指引（用于天命签）
  /// [fortuneTitle] 如"以静制动"、"柳暗花明"等
  /// [wishText] 用户当前愿望
  Future<String> generateFortuneGuidance(String fortuneTitle, String? wishText) async {
    final prompt = '你是一位精通周易的命理大师。\n\n'
        '用户抽中的天命签签名是："$fortuneTitle"\n'
        '用户的心愿是："${wishText ?? '祈福求签'}"\n\n'
        '请根据这个签名，结合周易智慧，为用户写一段温暖、有洞察力的指引文字。\n'
        '要求：\n'
        '1. 紧扣签名"$fortuneTitle"的含义展开\n'
        '2. 结合用户的心愿给出具体的指引\n'
        '3. 字数在100-150字之间\n'
        '4. 用大白话，温暖有力量，避免套话\n'
        '5. 每次生成要有不同的角度和表达方式';

    // 先尝试 Gemini
    if (_apiKey != null) {
      final hasNetwork = await _isNetworkAvailable();
      if (hasNetwork) {
        final result = await _callGeminiForGuidance(prompt);
        if (result != null) return result;
      }
    }
    
    // Gemini 失败，尝试阿里云百炼
    if (_fallbackApiKey != null) {
      final result = await _callDashScopeForGuidance(prompt);
      if (result != null) return result;
    }
    
    // 本地兜底
    return _generateLocalGuidance(fortuneTitle, wishText);
  }

  /// 调用 Gemini 生成指引
  Future<String?> _callGeminiForGuidance(String prompt) async {
    HttpClient? client;
    try {
      final randomTemp = 0.8 + Random().nextDouble() * 0.2;

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
          'temperature': randomTemp,
          'maxOutputTokens': 400,
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
        print('[AiService] Gemini 指引生成成功，长度: ${text.length}');
        return text.trim();
      }
    } catch (e) {
      print('[AiService] Gemini 指引生成异常: $e');
    } finally {
      client?.close();
    }
    return null;
  }

  /// 调用阿里云百炼生成指引
  Future<String?> _callDashScopeForGuidance(String prompt) async {
    HttpClient? client;
    try {
      final randomTemp = 0.8 + Random().nextDouble() * 0.2;

      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final uri = Uri.parse(_dashscopeEndpoint);
      final request = await client.postUrl(uri)
          .timeout(const Duration(seconds: 10));
      request.headers.contentType = ContentType.json;
      request.headers.add('Authorization', 'Bearer $_fallbackApiKey');

      final body = jsonEncode({
        'model': 'qwen-turbo',
        'input': {
          'messages': [
            {
              'role': 'system',
              'content': '你是一位精通周易的命理大师，擅长用现代大白话给出温暖有洞察力的指引。'
            },
            {
              'role': 'user',
              'content': prompt
            }
          ]
        },
        'parameters': {
          'temperature': randomTemp,
          'max_tokens': 400,
          'result_format': 'message',
        }
      });

      request.write(body);
      final response = await request.close()
          .timeout(const Duration(seconds: 15));
      final responseBody = await response.transform(utf8.decoder).join()
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
        final text = json['output']?['choices']?[0]?['message']?['content'] as String?;
        if (text != null && text.isNotEmpty) {
          print('[AiService] 阿里云百炼指引生成成功，长度: ${text.length}');
          return text.trim();
        }
      }
    } catch (e) {
      print('[AiService] 阿里云百炼指引生成异常: $e');
    } finally {
      client?.close();
    }
    return null;
  }

  /// 本地兜底指引生成
  String _generateLocalGuidance(String fortuneTitle, String? wishText) {
    final templates = {
      '以静制动': '「以静制动」是周易中的大智慧。当前局势或许有些纷扰，但越是动荡，越需要内心的安定。你的愿望"${wishText ?? '祈福'}"需要时间来沉淀，不必急于行动。静观其变，待时机成熟，自然水到渠成。保持内心的平和，就是最好的力量。',
      '守中持平': '「守中持平」提醒你保持平衡与中庸。在追求"${wishText ?? '目标'}"的过程中，不要过于激进，也不要过于保守。找到那个恰到好处的平衡点，稳扎稳打，方能行稳致远。',
      '循序渐进': '「循序渐进」告诉你，万事皆有步骤，不可躐等。你的愿望"${wishText ?? '目标'}"需要一步一个脚印去实现。每天进步一点点，积累起来就是巨大的飞跃。耐心是这个阶段最重要的品质。',
      '柳暗花明': '「柳暗花明」意味着低谷已过，曙光在前。虽然"${wishText ?? '前路'}"曾有些迷茫，但转机已经出现。保持信心，继续前行，美好的结果就在不远处等待着你。',
      '贵人相助': '「贵人相助」预示着你将遇到愿意帮助你的人。在"${wishText ?? '人生'}"的旅途中，不要拒绝他人的善意，也不要吝啬自己的帮助。人与人之间的连接，往往能带来意想不到的转机。',
      '星光璀璨': '「星光璀璨」是最美好的征兆。你的愿望"${wishText ?? '梦想'}"正沐浴在幸运的光芒中。此刻正是最好的时机，勇敢地去追求，宇宙都在为你助力。',
    };
    
    return templates[fortuneTitle] ?? '「$fortuneTitle」蕴含着深刻的周易智慧。你的心愿"${wishText ?? '祈福'}"与这个签名的能量相呼应。保持正念，顺势而为，相信一切都是最好的安排。';
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

}
