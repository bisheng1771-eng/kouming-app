import os
BASE = r"C:\Users\85932\.qclaw\workspace\software-factory\projects\kouming\lib"

# fate_draw_flow.dart - use direct unicode chars
f3 = """import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';
import 'package:kouming/shared/models/kouming_models.dart';
import 'package:kouming/services/i18n_service.dart';

class FateDrawFlow extends StatefulWidget {
  final VoidCallback onDrawComplete;
  final VoidCallback onPaymentRequired;
  const FateDrawFlow({super.key, required this.onDrawComplete, required this.onPaymentRequired});
  static Future<void> show(BuildContext context, {required VoidCallback onDrawComplete, required VoidCallback onPaymentRequired}) {
    return showModalBottomSheet(context: context, isScrollControlled:true, backgroundColor:Colors.transparent,
      builder:(_)=>FateDrawFlow(onDrawComplete:onDrawComplete, onPaymentRequired:onPaymentRequired));
  }
  @override State<FateDrawFlow> createState() => _FateDrawFlowState();
}

class _FateDrawFlowState extends State<FateDrawFlow> with TickerProviderStateMixin {
  late AnimationController _shakeCtrl, _flyCtrl, _flipCtrl;
  _Phase _phase = _Phase.idle;
  FortuneSlip? _result;

  @override void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync:this, duration: const Duration(milliseconds:1500));
    _flyCtrl = AnimationController(vsync:this, duration: const Duration(milliseconds:800));
    _flipCtrl = AnimationController(vsync:this, duration: const Duration(milliseconds:800));
    _flyCtrl.addStatusListener((s){ if(s==AnimationStatus.completed){ setState(()=>_phase=_Phase.reveal); _flipCtrl.forward(); }});
  }
  @override void dispose() { _shakeCtrl.dispose(); _flyCtrl.dispose(); _flipCtrl.dispose(); super.dispose(); }

  FortuneSlip _drawFortune() {
    final rng = Random();
    final roll = rng.nextDouble();
    final level = roll<0.05?FortuneLevel.supreme:roll<0.25?FortuneLevel.great:roll<0.60?FortuneLevel.medium:roll<0.85?FortuneLevel.low:FortuneLevel.bad;
    return _fortunePool[level]![rng.nextInt(_fortunePool[level]!.length)];
  }

  void _startDraw() {
    _result = _drawFortune();
    setState(()=>_phase=_Phase.shaking);
    _shakeCtrl.forward().then((_){ setState(()=>_phase=_Phase.flying); _flyCtrl.forward(from:0); });
  }

  @override Widget build(BuildContext context) {
    return Container(height: MediaQuery.of(context).size.height*0.75,
      decoration: const BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[KouMingTheme.deep,KouMingTheme.mid]),
        borderRadius: BorderRadius.vertical(top:Radius.circular(24))),
      child: Column(children: [
        Center(child:Container(margin: const EdgeInsets.only(top:10), width:40, height:4,
          decoration: BoxDecoration(color:KouMingTheme.gold.withValues(alpha:0.3), borderRadius:BorderRadius.circular(2)))),
        const SizedBox(height:12),
        Text('🎴 ${I18n.t('fate_title')}', style: const TextStyle(fontSize:20, fontWeight:FontWeight.bold, color:KouMingTheme.gold, fontFamily:'MaShanZheng')),
        const SizedBox(height:20),
        Expanded(child:_buildContent()),
      ]));
  }

  Widget _buildContent() {
    switch(_phase){ case _Phase.idle: return _buildIdle(); case _Phase.shaking: return _buildShaking(); case _Phase.flying: return _buildFlying(); case _Phase.reveal: return _buildReveal(); }
  }

  Widget _buildIdle() {
    return Center(child: Column(mainAxisSize:MainAxisSize.min, children:[
      Container(width:120, height:160, decoration: BoxDecoration(gradient:const LinearGradient(colors:[KouMingTheme.warm,KouMingTheme.gold]),
        borderRadius:BorderRadius.circular(16), border:Border.all(color:KouMingTheme.gold,width:2),
        boxShadow:[BoxShadow(color:KouMingTheme.gold.withValues(alpha:0.2),blurRadius:20)]),
        child: const Center(child:Text('🎻',style:TextStyle(fontSize:48)))),
      const SizedBox(height:24),
      Text(I18n.t('fate_shake_hint'), style: const TextStyle(fontSize:13, color:KouMingTheme.dim)),
      const SizedBox(height:16),
      GestureDetector(onTap:_startDraw,
        child: Container(padding: const EdgeInsets.symmetric(horizontal:32,vertical:14),
          decoration: BoxDecoration(gradient:const LinearGradient(colors:[KouMingTheme.gold,KouMingTheme.warm]),
            borderRadius:BorderRadius.circular(24), boxShadow:[BoxShadow(color:KouMingTheme.gold.withValues(alpha:0.3),blurRadius:12)]),
          child: Text(I18n.t('fate_draw_btn'), style: const TextStyle(fontSize:15, fontWeight:FontWeight.bold, color:Color(0xFF1A1A2E))))),
    ]));
  }

  Widget _buildShaking() {
    return Center(child: AnimatedBuilder(animation:_shakeCtrl, builder:(ctx,child){
      final t = _shakeCtrl.value;
      final angle = sin(t*8*pi)*0.15*(1-t);
      final offsetX = sin(t*12*pi)*8*(1-t);
      return Transform.translate(offset:Offset(offsetX,0), child: Transform.rotate(angle:angle, child:child));
    }, child: Container(width:120, height:160, decoration: BoxDecoration(gradient:const LinearGradient(colors:[KouMingTheme.warm,KouMingTheme.gold]),
      borderRadius:BorderRadius.circular(16), border:Border.all(color:KouMingTheme.gold,width:2),
      boxShadow:[BoxShadow(color:KouMingTheme.gold.withValues(alpha:0.4),blurRadius:30)]),
      child: Stack(alignment:Alignment.center, children:[
        const Text('🎻',style:TextStyle(fontSize:48)),
        Positioned(top:8,left:30,child:Transform.rotate(angle:-0.2,child:const Text('\u3030',style:TextStyle(fontSize:20,color:KouMingTheme.gold,opacity:0.6))))),
        Positioned(top:12,right:28,child:Transform.rotate(angle:0.15,child:const Text('\u3030',style:TextStyle(fontSize:18,color:KouMingTheme.gold,opacity:0.5))))),
      ]))));
  }

  Widget _buildFlying() {
    return AnimatedBuilder(animation:_flyCtrl, builder:(ctx,_){
      final t = _flyCtrl.value;
      final y = 80 - Curves.easeOut.transform(t)*160;
      final scale = 0.6 + Curves.easeOut.transform(t)*0.4;
      final opacity = 0.5 + t*0.5;
      return Center(child: Transform.translate(offset:Offset(0,y),
        child: Transform.scale(scale:scale, child:Opacity(opacity:opacity, child:_buildStickCard(back:true))))));
    });
  }

  Widget _buildStickCard({required bool back}) {
    return Container(width:80, height:180, decoration: BoxDecoration(
      gradient: back ? const LinearGradient(colors:[Color(0xFF8B0000),Color(0xFFB22222)]) : LinearGradient(colors:[_levelColor(_result!.level).withValues(alpha:0.3), KouMingTheme.surface]),
      borderRadius:BorderRadius.circular(12), border:Border.all(color:back?KouMingTheme.lantern:_levelColor(_result!.level),width:2),
      boxShadow:[BoxShadow(color:(back?KouMingTheme.lantern:_levelColor(_result!.level)).withValues(alpha:0.4),blurRadius:20)]),
      child: back ? const Center(child:Text('\u0436',style:TextStyle(fontSize:36,color:KouMingTheme.gold,fontFamily:'MaShanZheng'))) : _buildFortuneContent());
  }

  Widget _buildFortuneContent() {
    if(_result==null) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.all(12), child: Column(mainAxisAlignment:MainAxisAlignment.center, children:[
      Text(_result!.emoji, style: const TextStyle(fontSize:28)),
      const SizedBox(height:6),
      Text(_result!.title, style:TextStyle(fontSize:14,fontWeight:FontWeight.bold,color:_levelColor(_result!.level),fontFamily:'MaShanZheng'), textAlign:TextAlign.center),
      const SizedBox(height:4),
      Text(_levelLabel(_result!.level), style:TextStyle(fontSize:11,color:_levelColor(_result!.level))),
    ]));
  }

  Widget _buildReveal() {
    if(_result==null) return const SizedBox.shrink();
    return AnimatedBuilder(animation:_flipCtrl, builder:(ctx,_){
      final t = _flipCtrl.value;
      final angle = t<0.5 ? t*pi : (t-1)*pi;
      final showFront = t>=0.5;
      return Center(child: Column(mainAxisSize:MainAxisSize.min, children:[
        Transform(alignment:Alignment.center, transform:Matrix4.identity()..setEntry(3,2,0.001)..rotateY(angle),
          child: showFront ? _buildFullResultCard() : _buildStickCard(back:true)),
      ]));
    });
  }

  Widget _buildFullResultCard() {
    final color = _levelColor(_result!.level);
    return Container(width:260, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient:LinearGradient(colors:[color.withValues(alpha:0.15),KouMingTheme.surface]),
        borderRadius:BorderRadius.circular(20), border:Border.all(color:color,width:2),
        boxShadow:[BoxShadow(color:color.withValues(alpha:0.3),blurRadius:24)]),
      child: Column(mainAxisSize:MainAxisSize.min, children:[
        Container(padding: const EdgeInsets.symmetric(horizontal:16,vertical:4),
          decoration: BoxDecoration(color:color.withValues(alpha:0.2), borderRadius:BorderRadius.circular(12), border:Border.all(color:color.withValues(alpha:0.5))),
          child: Text(_levelLabel(_result!.level), style:TextStyle(fontSize:13,fontWeight:FontWeight.bold,color:color))),
        const SizedBox(height:16),
        Text(_result!.emoji, style: const TextStyle(fontSize:40)),
        const SizedBox(height:12),
        Text(_result!.title, style:TextStyle(fontSize:22,fontWeight:FontWeight.bold,color:color,fontFamily:'MaShanZheng')),
        const SizedBox(height:8),
        Text(_result!.description, style: const TextStyle(fontSize:12,color:KouMingTheme.text,height:1.6), textAlign:TextAlign.center),
        const SizedBox(height:12),
        Row(mainAxisAlignment:MainAxisAlignment.center, children:[
          const Text('🔮 ', style:TextStyle(fontSize:12)),
          Text(I18n.t('fate_element') + _result!.element, style:TextStyle(fontSize:11,color:color.withValues(alpha:0.8))),
          const SizedBox(width:12),
          const Text('🛡 ', style:TextStyle(fontSize:12)),
          Text(I18n.t('fate_guardian') + _result!.guardian, style:TextStyle(fontSize:11,color:color.withValues(alpha:0.8))),
        ]),
        const SizedBox(height:20),
        GestureDetector(onTap:(){ widget.onDrawComplete(); Navigator.pop(context); },
          child: Container(padding: const EdgeInsets.symmetric(horizontal:24,vertical:10),
            decoration: BoxDecoration(gradient:LinearGradient(colors:[color,color.withValues(alpha:0.7)]), borderRadius:BorderRadius.circular(16)),
            child: Text(I18n.t('fate_accept'), style: const TextStyle(fontSize:13,fontWeight:FontWeight.bold,color:KouMingTheme.deep)))),
      ]));
  }

  static Color _levelColor(FortuneLevel level) {
    switch(level){ case FortuneLevel.supreme: return KouMingTheme.gold; case FortuneLevel.great: return KouMingTheme.lantern;
      case FortuneLevel.medium: return KouMingTheme.purple; case FortuneLevel.low: return KouMingTheme.water; case FortuneLevel.bad: return const Color(0xFF666688); }
  }

  String _levelLabel(FortuneLevel level) {
    switch(level){ case FortuneLevel.supreme: return I18n.t('fortune_supreme'); case FortuneLevel.great: return I18n.t('fortune_great');
      case FortuneLevel.medium: return I18n.t('fortune_medium'); case FortuneLevel.low: return I18n.t('fortune_low'); case FortuneLevel.bad: return I18n.t('fortune_bad'); }
  }

  static const Map<FortuneLevel,List<FortuneSlip>> _fortunePool = {
    FortuneLevel.supreme: [
      FortuneSlip(title:'天赐鸿运',description:'万事如意，心想事成。天时地利人和，此时正是最好的时机。',emoji:'⭐',level:FortuneLevel.supreme,element:'金',guardian:'白虎'),
      FortuneSlip(title:'紫气东来',description:'祥瑞降临，好运连连。贵人在侧，诸事顺遂。',emoji:'👑',level:FortuneLevel.supreme,element:'火',guardian:'朱雀'),
    ],
    FortuneLevel.great: [
      FortuneSlip(title:'否极泰来',description:'低谷已过，曙光初现。坚持本心，必有转机。',emoji:'🌅',level:FortuneLevel.great,element:'木',guardian:'青龙'),
      FortuneSlip(title:'贵人相助',description:'有人暗中助力，事半而功倍。保持开放心态，接纳帮助。',emoji:'🤝',level:FortuneLevel.great,element:'土',guardian:'麒麟'),
      FortuneSlip(title:'锦上添花',description:'好事之上更有好事，正逢顺水推舟之时。',emoji:'🌸',level:FortuneLevel.great,element:'水',guardian:'玄武'),
    ],
    FortuneLevel.medium: [
      FortuneSlip(title:'守中持平',description:'不急不躁，稳中求进。此时宜守不宜攻，静待时机。',emoji:'☯',level:FortuneLevel.medium,element:'土',guardian:'勾陈'),
      FortuneSlip(title:'循序渐进',description:'水到渠成，不必急于一时。一步一个脚印，终有所成。',emoji:'🚶',level:FortuneLevel.medium,element:'水',guardian:'玄武'),
      FortuneSlip(title:'以静制动',description:'外界纷扰，内心安定则无碍。沉稳面对，自见分明。',emoji:'🧘',level:FortuneLevel.medium,element:'金',guardian:'白虎'),
    ],
    FortuneLevel.low: [
      FortuneSlip(title:'阴云笼罩',description:'前路暂有阻碍，莫急躁。稍作休整，等待时机。',emoji:'☁',level:FortuneLevel.low,element:'土',guardian:'腾蛇'),
      FortuneSlip(title:'事需缓图',description:'时机未到，强求反累。先退一步，再谋后动。',emoji:'💨',level:FortuneLevel.low,element:'金',guardian:'白虎'),
      FortuneSlip(title:'静待花开',description:'好事尚需时日，耐心浇灌，静候花开。',emoji:'🌿',level:FortuneLevel.low,element:'木',guardian:'青龙'),
    ],
    FortuneLevel.bad: [
      FortuneSlip(title:'暗礁险滩',description:'前方有阻，慎防陷阱。低调行事，避开锋芒。',emoji:'🌙',level:FortuneLevel.bad,element:'水',guardian:'罗睺'),
      FortuneSlip(title:'山重水复',description:'看似无路，实则转机将至。咬牙坚持，方见光明。',emoji:'⛰',level:FortuneLevel.bad,element:'火',guardian:'计都'),
      FortuneSlip(title:'困顿之时',description:'黎明前最黑暗的时刻。保持信念，必有转机。',emoji:'🕯',level:FortuneLevel.bad,element:'木',guardian:'玄武'),
    ],
  };
}

enum _Phase { idle, shaking, flying, reveal }
"""

with open(os.path.join(BASE, "features","shop","fate_draw_flow.dart"), "w", encoding="utf-8") as f:
    f.write(f3)
print(f"fate_draw_flow.dart: {len(f3)} chars")
