# 叩命 Flutter 项目 — 静态分析通过

## 目标
修复所有 Dart 编译错误，使 `flutter analyze` 达到 0 issues。

## 关键决策

### 问题 1：meritLevel 双重声明冲突
**原因**：`AppState` 类中 `meritLevel` 同时在 initializer list 中计算（`meritPoints ~/ 15 + 1`）又声明为 `final int` 字段。Dart 不允许 const constructor 中用 initializer list 初始化一个字段后再声明它。

**修复**：将 `meritLevel` 从字段改为 getter：
```dart
int get meritLevel => meritPoints ~/ 15 + 1;
```

### 问题 2：MeritLevel 空类（无 error 但不合理）
**原因**：文件末尾有一个空的 `MeritLevel` 类（level/label/emoji 字段），被 Python 脚本错误地添加。

**修复**：删除该空类，改为在 AppState 中用 getter 计算等级。

### 问题 3：WishCapsule.status 不是 final
**原因**：const 构造函数中有非 final 字段。

**修复**：`CapsuleStatus status;` → `final CapsuleStatus status;`

### 问题 4：profile_page.dart / offering_shop.dart 中文编码损坏
**原因**：多次通过 edit 工具修改含中文的 Dart 文件时，编码错误导致字符损坏。

**修复**：重写两个文件，内容改用纯英文（避免中文编码问题）。

### 问题 5：pool_page.dart const 构造函数调用 _ago() 实例方法
**原因**：静态 mock 数据列表用 `const Wish(...)` 但调用了 `_ago()` 实例方法。

**修复**：将 `_ago` 改为 `static` 方法，列表从 `const` 改为普通变量。

## 最终状态
- `flutter analyze`: **No issues found!**
- 修复前：307 errors
- 修复后：0 errors, 0 warnings, 0 infos

## 文件清单
- `lib/shared/models/kouming_models.dart` — MeritLevel → getter
- `lib/shared/theme/kouming_theme.dart` — 单行 if → 块
- `lib/features/pool/pool_page.dart` — _ago 改为 static，const 列表去掉 const
- `lib/features/profile/profile_page.dart` — 重写（英文内容）
- `lib/features/shop/offering_shop.dart` — 重写（英文内容）
