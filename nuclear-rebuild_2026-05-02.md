# 叩命 App - 核弹级重建 + 祈福签自动抽签 (02:28)

## 问题
用户反馈 APK 始终显示旧版，三处修复均未生效：
1. Lv10 不显示「化境」
2. 还愿动画仍是旧版
3. 祈福签出现两次付款（offer_shop 付一次 + FateDrawFlow 又显示 ¥6 按钮）

## 根因
- Gradle 增量编译未检测到源文件变更，即使 flutter clean 后仍有缓存残留
- FateDrawFlow 按钮文案 "🎲 祈福（¥6）" 让已付款用户误以为需要再付

## 修复

### 1. 核弹级清理
- 杀掉所有 Java 进程（Gradle Daemon）
- 删除 `build/`、`.dart_tool/`、`android/.gradle/`
- 删除 `~/.gradle/caches/transforms-*`、`build-cache-*`
- `flutter clean` + 完整重建

### 2. 祈福签自动抽签
- `fate_draw_flow.dart` initState：当 `freeAvailable: true`，在首帧后自动调用 `_startDraw()`
- 不再显示祈福按钮，避免已付款用户看到 ¥6 按钮

### 3. pubspec.yaml 修复
- description 和 publish_to 行被 PowerShell GBK 编码压缩合并，手动分割恢复

## 构建结果
- APK: 47.9MB, versionCode=5
- 设备: QFF0220103000138, 已卸载旧版 → 安装新版

## 待用户确认
1. Lv10 显示「化境」？
2. 还愿动画是新版（灯笼+烟花+闪光）？
3. 祈福签买完后自动抽签，不显示 ¥6 按钮？
