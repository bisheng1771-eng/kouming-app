import 'package:flutter/material.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';
import 'package:kouming/shared/models/kouming_models.dart';

/// 愿望胶囊页面
class CapsulePage extends StatelessWidget {
  final List<Wish> myWishes;
  final VoidCallback? onCreateCapsule;

  const CapsulePage({super.key, required this.myWishes, this.onCreateCapsule});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("⏳ 愿望胶囊", style: TextStyle(fontSize:18, fontWeight:FontWeight.bold, color:KouMingTheme.gold)),
          const SizedBox(height:4),
          const Text("把愿望封存起来，待未来的自己来开启", style: TextStyle(fontSize:11, color:KouMingTheme.dim)),
          const SizedBox(height:16),
          GestureDetector(
            onTap: () => _showCreateDialog(context),
            child: Container(
              width:double.infinity, padding:const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors:[KouMingTheme.water.withValues(alpha:0.12), KouMingTheme.purple.withValues(alpha:0.08)]),
                border: Border.all(color:KouMingTheme.water.withValues(alpha:0.18)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children:[
                  Text("🌊", style:TextStyle(fontSize:36)),
                  SizedBox(height:8),
                  Text("封存一个新胶囊", style:TextStyle(fontSize:13, color:KouMingTheme.water)),
                  SizedBox(height:4),
                  Text("选择未来的日期，等待命运开启", style:TextStyle(fontSize:10, color:KouMingTheme.dim)),
                ],
              ),
            ),
          ),
          const SizedBox(height:20),
          const Text("⏰ 待开启", style:TextStyle(fontSize:12, color:KouMingTheme.dim, letterSpacing:1)),
          const SizedBox(height:8),
          _CapsuleCard(emoji:"🌊", title:"2024年考研上岸", createdAt:"2024-01-15", openAt:"2025-02-01", status:"pending"),
          _CapsuleCard(emoji:"💰", title:"存款突破50万", createdAt:"2024-06-01", openAt:"2025-06-01", status:"pending"),
          const SizedBox(height:12),
          const Text("✨ 已开启", style:TextStyle(fontSize:12, color:KouMingTheme.dim, letterSpacing:1)),
          const SizedBox(height:8),
          _CapsuleCard(emoji:"🎓", title:"雅思7分上岸", createdAt:"2023-09-01", openAt:"2024-09-01", status:"opened", wasFulfilled:true),
          _CapsuleCard(emoji:"🏥", title:"爸爸手术顺利", createdAt:"2023-03-01", openAt:"2024-03-01", status:"opened", wasFulfilled:false),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: KouMingTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top:Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            const Text("⏳ 封存愿望胶囊", style:TextStyle(fontSize:16, fontWeight:FontWeight.bold, color:KouMingTheme.gold)),
            const SizedBox(height:16),
            const Text("选择一个未来的日期，深渊会在那天提醒你打开它。", style:TextStyle(fontSize:12, color:KouMingTheme.dim)),
            const SizedBox(height:16),
            SizedBox(width:double.infinity,
              child: ElevatedButton(
                onPressed:()=>Navigator.pop(ctx),
                style:ElevatedButton.styleFrom(backgroundColor:KouMingTheme.water, foregroundColor:Colors.white, padding:const EdgeInsets.all(14), shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14))),
                child:const Text("选择开启日期 📅"),
              ),
            ),
            Center(child:TextButton(onPressed:()=>Navigator.pop(ctx), child:const Text("暂不封存", style:TextStyle(fontSize:12, color:KouMingTheme.dim)))),
          ],
        ),
      ),
    );
  }
}

class _CapsuleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String createdAt;
  final String openAt;
  final String status;
  final bool? wasFulfilled;

  const _CapsuleCard({required this.emoji, required this.title, required this.createdAt, required this.openAt, required this.status, this.wasFulfilled});

  @override
  Widget build(BuildContext context) {
    final isOpen = status == "opened";
    return Container(
      margin:const EdgeInsets.only(bottom:8), padding:const EdgeInsets.all(12),
      decoration:BoxDecoration(
        color:KouMingTheme.surface,
        border:Border.all(color: isOpen ? KouMingTheme.dim.withValues(alpha:0.1) : KouMingTheme.water.withValues(alpha:0.12)),
        borderRadius:BorderRadius.circular(12),
      ),
      child:Row(children:[
        Text(emoji, style:const TextStyle(fontSize:20)),
        const SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
          Text(title, style:TextStyle(fontSize:12, color:isOpen ? KouMingTheme.dim : KouMingTheme.text, decoration:isOpen ? TextDecoration.lineThrough : null)),
          const SizedBox(height:2),
          Text(isOpen ? "已于 $openAt 开启" : "封存于 $createdAt · 等待 $openAt", style:const TextStyle(fontSize:9, color:KouMingTheme.dim)),
        ])),
        if (isOpen && wasFulfilled != null)
          Text(wasFulfilled! ? "✅ 实现" : "🌊 继续努力", style:TextStyle(fontSize:10, color:wasFulfilled! ? Colors.green : KouMingTheme.water))
        else if (!isOpen)
          Container(padding:const EdgeInsets.symmetric(horizontal:7, vertical:2), decoration:BoxDecoration(color:KouMingTheme.water.withValues(alpha:0.1), borderRadius:BorderRadius.circular(8)), child:const Text("待开启", style:TextStyle(fontSize:9, color:KouMingTheme.water))),
      ]),
    );
  }
}