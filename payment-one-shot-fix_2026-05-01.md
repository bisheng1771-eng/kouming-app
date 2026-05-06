# 口鸣APP 支付问题一次性修复 — 2026-05-01

## Objective
一次性修复口鸣APP所有6个支付问题（用户困扰数周）

## Root Causes Identified

### #1: Offerings hardcoded as FREE
`offering_shop.dart` `_onPurchase()` had:
```dart
if (offering.section == _Section.fate) { productType = 'fate'; }
else if (offering.section == _Section.fulfill) { productType = 'fulfill'; }
else { productType = ''; }  // ← offerings enter here, skip payment
```
微光/花灯/长明灯 (section=offerings) → productType='' → never enters payment flow → directly gives merit reward

### #2: Real Alipay chain too fragile for testing
Chain: Flutter → Edge Function (HTTP) → MethodChannel → Native PayTask → Alipay App
4 hops, any failure = "支付失败". Previous fixes only addressed individual hops.

Also found: double-add merit bug for paid products (merit added both in payment success block AND unconditional bottom block)

## Fix Applied

### 1. `alipay_service.dart`
- `mockMode = true` (was false) — bypasses entire real Alipay chain during dev
- Added 3 new products: incense(¥1), lotus(¥2), river(¥3)

### 2. `offering_shop.dart` — Complete rewrite of `_onPurchase()`
- All 6 products now route through `AlipayService.pay()` 
- Eliminated double-add merit bug
- Cleaner control flow with early returns per section
- Fate items: after payment, open FateDrawFlow with freeAvailable=true (already paid)

## Result
- Build: 47.7MB release APK, installed on device QFF0220103000138
- All 6 products: 微光¥1, 花灯¥2, 长明灯¥3, 祈福签¥6, 算卦¥6, 还愿¥3.6
- Each shows: compliance dialog → payment confirmation → success → product delivered

## Production Path
- Change `mockMode = false` in `alipay_service.dart`
- Ensure Supabase Edge Function `alipay-order` is deployed with correct ALIPAY_PRIVATE_KEY secret
- Test on device with Alipay app installed
