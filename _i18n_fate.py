import os
BASE = r"C:\Users\85932\.qclaw\workspace\software-factory\projects\kouming\lib"

f3 = r"""import 'dart:math';
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
        Text('\u{1F3B4} ${I18n.t('fate_title')}', style: const TextStyle(fontSize:20, fontWeight:FontWeight.bold, color:KouMingTheme.gold, fontFamily:'MaShanZheng')),
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
        child: const Center(child:Text('\u{1F38B}',style:TextStyle(fontSize:48)))),
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
        const Text('\u{1F38B}',style:TextStyle(fontSize:48)),
        Positioned(top:8,left:30,child:Transform.rotate(angle:-0.2,child:Text('\u3030',style:TextStyle(fontSize:20,color:KouMingTheme.gold.withValues(alpha:0.6)))))),
        Positioned(top:12,right:28,child:Transform.rotate(angle:0.15,child:Text('\u3030',style:TextStyle(fontSize:18,color:KouMingTheme.gold.withValues(alpha:0.5)))))),
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
      child: back ? const Center(child:Text('\u{435}',style:TextStyle(fontSize:36,color:KouMingTheme.gold,fontFamily:'MaShanZheng'))) : _buildFortuneContent());
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
          const Text('\u{1F52E} ', style:TextStyle(fontSize:12)),
          Text('${I18n.t('fate_element')}${_result!.element}', style:TextStyle(fontSize:11,color:color.withValues(alpha:0.8))),
          const SizedBox(width:12),
          const Text('\u{1F6E1} ', style:TextStyle(fontSize:12)),
          Text('${I18n.t('fate_guardian')}${_result!.guardian}', style:TextStyle(fontSize:11,color:color.withValues(alpha:0.8))),
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
      FortuneSlip(title:'天赐鸿运',description:'万事如意，心想事成。天时地利人和，此时正是最好的时机。',emoji:'\u{1F31F}',level:FortuneLevel.supreme,element:'金',guardian:'白虎'),
      FortuneSlip(title:'紫气东来',description:'祥瑞降临，好运连连。贵人在侧，诸事顺遂。',emoji:'\u{1F451}',level:FortuneLevel.supreme,element:'火',guardian:'朱雀'),
    ],
    FortuneLevel.great: [
      FortuneSlip(title:'否极泰来',description:'低谷已过，曙光初现。坚持本心，必有转机。',emoji:'\u{1F305}',level:FortuneLevel.great,element:'木',guardian:'青龙'),
      FortuneSlip(title:'贵人相助',description:'有人暗中助力，事半而功倍。保持开放心态，接纳帮助。',emoji:'\u{1F91D}',level:FortuneLevel.great,element:'土',guardian:'麒麟'),
      FortuneSlip(title:'锦上添花',description:'好事之上更有好事，正逢顺水推舟之时。',emoji:'\u{1F338}',level:FortuneLevel.great,element:'水',guardian:'玄武'),
    ],
    FortuneLevel.medium: [
      FortuneSlip(title:'守中持平',description:'不急不躁，稳中求进。此时宜守不宜攻，静待时机。',emoji:'\u{262F}',level:FortuneLevel.medium,element:'土',guardian:'勾陈'),
      FortuneSlip(title:'循序渐进',description:'水到渠成，不必急于一时。一步一个脚印，终有所成。',emoji:'\u{1F6B6}',level:FortuneLevel.medium,element:'水',guardian:'玄武'),
      FortuneSlip(title:'以静制动',description:'外界纷扰，内心安定则无碍。沉稳面对，自见分明。',emoji:'\u{1F9D8}',level:FortuneLevel.medium,element:'金',guardian:'白虎'),
    ],
    FortuneLevel.low: [
      FortuneSlip(title:'阴云笼罩',description:'前路暂有阻碍，莫急躁。稍作休整，等待时机。',emoji:'\u{2601}',level:FortuneLevel.low,element:'土',guardian:'腾蛇'),
      FortuneSlip(title:'事需缓图',description:'时机未到，强求反累。先退一步，再谋后动。',emoji:'\u{1F4A8}',level:FortuneLevel.low,element:'金',guardian:'白虎'),
      FortuneSlip(title:'静待花开',description:'好事尚需时日，耐心浇灌，静候花开。',emoji:'\u{1F33F}',level:FortuneLevel.low,element:'木',guardian:'青龙'),
    ],
    FortuneLevel.bad: [
      FortuneSlip(title:'暗礁险滩',description:'前方有阻，慎防陷阱。低调行事，避开锋芒。',emoji:'\u{1F319}',level:FortuneLevel.bad,element:'水',guardian:'罗睺'),
      FortuneSlip(title:'山重水复',description:'看似无路，实则转机将至。咬牙坚持，方见光明。',emoji:'\u{26F0}',level:FortuneLevel.bad,element:'火',guardian:'计都'),
      FortuneSlip(title:'困顿之时',description:'黎明前最黑暗的时刻。保持信念，必有转机。',emoji:'\u{1F56F}',level:FortuneLevel.bad,element:'木',guardian:'玄武'),
    ],
  };
}

enum _Phase { idle, shaking, flying, reveal }
"""

with open(os.path.join(BASE, "features","shop","fate_draw_flow.dart"), "w", encoding="utf-8") as f:
    f.write(f3)
print("3. fate_draw_flow.dart OK")

f4 = r"""import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';
import 'package:kouming/shared/models/kouming_models.dart';
import 'package:kouming/services/i18n_service.dart';

class FulfillCeremony extends StatefulWidget {
  final WishCapsule capsule;
  final VoidCallback onCeremonyComplete;
  const FulfillCeremony({super.key, required this.capsule, required this.onCeremonyComplete});
  static Future<void> show(BuildContext context, {required WishCapsule capsule, required VoidCallback onCeremonyComplete}) {
    return showModalBottomSheet(context:context, isScrollControlled:true, backgroundColor:Colors.transparent,
      builder:(_)=>FulfillCeremony(capsule:capsule, onCeremonyComplete:onCeremonyComplete));
  }
  @override State<FulfillCeremony> createState() => _FulfillCeremonyState();
}

class _FulfillCeremonyState extends State<FulfillCeremony> with TickerProviderStateMixin {
  late AnimationController _glowCtrl, _fireworkCtrl;
  bool _showFireworks = false;

  @override void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync:this, duration: const Duration(milliseconds:2000));
    _fireworkCtrl = AnimationController(vsync:this, duration: const Duration(milliseconds:3000));
  }
  @override void dispose() { _glowCtrl.dispose(); _fireworkCtrl.dispose(); super.dispose(); }

  void _startCeremony() {
    _glowCtrl.forward().then((_){ setState(()=>_showFireworks=true); _fireworkCtrl.forward(); });
  }

  static const Map<String,String> _catLabelKeys = {
    'study':'fulfill_cat_study','health':'fulfill_cat_health','love':'fulfill_cat_love','money':'fulfill_cat_money',
  };

  @override Widget build(BuildContext context) {
    return Container(height:MediaQuery.of(context).size.height*0.8,
      decoration: const BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[KouMingTheme.deep,KouMingTheme.mid]),
        borderRadius: BorderRadius.vertical(top:Radius.circular(24))),
      child: Stack(children:[
        Column(children:[
          Center(child:Container(margin: const EdgeInsets.only(top:10), width:40, height:4,
            decoration: BoxDecoration(color:KouMingTheme.gold.withValues(alpha:0.3), borderRadius:BorderRadius.circular(2)))),
          const SizedBox(height:16),
          Text('\u{1F386} ${I18n.t('fulfill_title')}', style: const TextStyle(fontSize:20,fontWeight:FontWeight.bold,color:KouMingTheme.gold,fontFamily:'MaShanZheng')),
          const SizedBox(height:20),
          Expanded(child:_buildContent()),
        ]),
        if(_showFireworks) Positioned.fill(child:IgnorePointer(child:_FireworksCanvas(animation:_fireworkCtrl))),
      ]));
  }

  Widget _buildContent() {
    return AnimatedBuilder(animation:_glowCtrl, builder:(ctx,_){
      final t = _glowCtrl.value;
      final glowAlpha = t*0.5;
      final scale = 1.0 + t*0.1;
      return Center(child: Column(mainAxisSize:MainAxisSize.min, children:[
        Transform.scale(scale:scale, child:Container(width:120,height:120, decoration:BoxDecoration(shape:BoxShape.circle,
          gradient:RadialGradient(colors:[KouMingTheme.gold.withValues(alpha:glowAlpha+0.2),KouMingTheme.lantern.withValues(alpha:glowAlpha),KouMingTheme.purple.withValues(alpha:glowAlpha*0.5)]),
          boxShadow:[BoxShadow(color:KouMingTheme.gold.withValues(alpha:glowAlpha),blurRadius:40),BoxShadow(color:KouMingTheme.lantern.withValues(alpha:glowAlpha*0.5),blurRadius:60)]),
          child:Center(child:Text('\u{1F52E}',style:TextStyle(fontSize:40+t*8)))))),
        const SizedBox(height:24),
        Container(padding: const EdgeInsets.symmetric(horizontal:24,vertical:12),
          decoration:BoxDecoration(color:KouMingTheme.surface.withValues(alpha:0.5), borderRadius:BorderRadius.circular(12),
            border:Border.all(color:KouMingTheme.gold.withValues(alpha:0.2))),
          child:Text('\u201C${widget.capsule.wishText}\u201D', style:const TextStyle(fontSize:14,fontStyle:FontStyle.italic,color:KouMingTheme.text,fontFamily:'MaShanZheng'), textAlign:TextAlign.center)),
        const SizedBox(height:8),
        Text(_getCategoryLabel(widget.capsule.category), style: const TextStyle(fontSize:13,color:KouMingTheme.dim)),
        const SizedBox(height:20),
        if(!_showFireworks)...[
          Text(I18n.t('fulfill_prompt'), style: const TextStyle(fontSize:12,color:KouMingTheme.dim)),
          const SizedBox(height:16),
          GestureDetector(onTap:_startCeremony,
            child:Container(padding: const EdgeInsets.symmetric(horizontal:28,vertical:14),
              decoration:BoxDecoration(gradient:const LinearGradient(colors:[KouMingTheme.lantern,KouMingTheme.gold]),
                borderRadius:BorderRadius.circular(24), boxShadow:[BoxShadow(color:KouMingTheme.lantern.withValues(alpha:0.3),blurRadius:12)]),
              child:Text(I18n.t('fulfill_btn'), style:const TextStyle(fontSize:15,fontWeight:FontWeight.bold,color:Color(0xFF1A1A2E))))),
        ]else...[
          const SizedBox(height:8),
          Text(I18n.t('fulfill_done'), style: const TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:KouMingTheme.gold,fontFamily:'MaShanZheng')),
          const SizedBox(height:4),
          Text(I18n.t('fulfill_merit'), style: const TextStyle(fontSize:13,color:KouMingTheme.purple)),
          const SizedBox(height:16),
          GestureDetector(onTap:(){ widget.onCeremonyComplete(); Navigator.pop(context); },
            child:Container(padding: const EdgeInsets.symmetric(horizontal:24,vertical:10),
              decoration:BoxDecoration(gradient:const LinearGradient(colors:[KouMingTheme.gold,KouMingTheme.warm]), borderRadius:BorderRadius.circular(16)),
              child:Text(I18n.t('fulfill_close'), style:const TextStyle(fontSize:13,fontWeight:FontWeight.bold,color:Color(0xFF1A1A2E))))),
        ],
      ]));
    });
  }

  String _getCategoryLabel(String cat) => I18n.t(_catLabelKeys[cat] ?? 'fulfill_cat_other');
}

class _FireworksCanvas extends StatelessWidget {
  final Animation<double> animation;
  const _FireworksCanvas({required this.animation});
  @override Widget build(BuildContext context) {
    return AnimatedBuilder(animation:animation, builder:(ctx,_)=>CustomPaint(painter:_FireworksPainter(animation.value), size:Size.infinite));
  }
}

class _FireworksPainter extends CustomPainter {
  final double t;
  static final _rng = Random(42);
  _FireworksPainter(this.t);
  static final List<_Burst> _bursts = [
    _Burst(0.25,0.25,KouMingTheme.gold,20,0.0), _Burst(0.75,0.20,KouMingTheme.lantern,18,0.15),
    _Burst(0.5,0.35,KouMingTheme.purple,22,0.3), _Burst(0.3,0.45,Colors.pink,16,0.45), _Burst(0.7,0.40,KouMingTheme.warm,18,0.55),
  ];
  @override void paint(Canvas c, Size s) { for(final b in _bursts) _drawBurst(c,s,b); }
  void _drawBurst(Canvas c, Size s, _Burst b) {
    if(t<b.startT) return;
    final lt = ((t-b.startT)/(1.0-b.startT)).clamp(0.0,1.0);
    final cx = s.width*b.x, cy = s.height*b.y, maxR = s.width*0.18;
    for(int i=0;i<b.count;i++){
      final angle = (i/b.count)*2*pi+_rng.nextDouble()*0.3;
      final speed = 0.5+_rng.nextDouble()*0.5;
      final pt = (lt*1.5-0.2*speed).clamp(0.0,1.0);
      if(pt<=0) continue;
      final r = maxR*pt*speed;
      final fade = pt>0.6 ? 1.0-(pt-0.6)/0.4 : 1.0;
      c.drawCircle(Offset(cx+cos(angle)*r, cy+sin(angle)*r-pt*20), 2.5*(1-pt*0.5), Paint()..color=b.color.withValues(alpha:fade*0.9));
    }
  }
  @override bool shouldRepaint(_FireworksPainter old) => t!=old.t;
}
class _Burst { final double x,y; final Color color; final int count; final double startT; _Burst(this.x,this.y,this.color,this.count,this.startT); }
"""

with open(os.path.join(BASE, "features","shop","fulfill_ceremony.dart"), "w", encoding="utf-8") as f:
    f.write(f4)
print("4. fulfill_ceremony.dart OK")
print("ALL 4 DONE")
