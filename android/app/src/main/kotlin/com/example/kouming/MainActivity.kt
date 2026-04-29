package com.example.kouming

import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.alipay.sdk.app.PayTask

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.kouming/alipay"
    private var pendingResult: MethodChannel.Result? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pay" -> {
                    val orderStr = call.argument<String>("orderStr")
                    if (orderStr == null) {
                        Log.e("AlipayPlugin", "orderStr is null!")
                        result.error("INVALID_PARAM", "orderStr is null", null)
                        return@setMethodCallHandler
                    }
                    pendingResult = result
                    pay(orderStr)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun pay(orderStr: String) {
        Log.d("AlipayPlugin", "pay() called with orderStr length: ${orderStr.length}")
        Thread {
            try {
                val payTask = PayTask(this)
                val resultMap = payTask.payV2(orderStr, true)

                Log.d("AlipayPlugin", "payV2 result: $resultMap")

                handler.post {
                    // 直接把完整的 resultMap 回调给 Flutter，不走 intent 解析
                    val resultToFlutter = mapOf(
                        "resultStatus" to (resultMap["resultStatus"] ?: ""),
                        "result" to (resultMap["result"] ?: ""),
                        "memo" to (resultMap["memo"] ?: ""),
                        // 调试用：打印完整原始 map
                        "_rawResultStatus" to resultMap["resultStatus"].toString()
                    )
                    Log.d("AlipayPlugin", "Sending to Flutter: $resultToFlutter")
                    pendingResult?.success(resultToFlutter)
                    pendingResult = null
                }
            } catch (e: Exception) {
                Log.e("AlipayPlugin", "payV2 error: ${e.message}", e)
                handler.post {
                    pendingResult?.error("PAY_ERROR", e.message, null)
                    pendingResult = null
                }
            }
        }.start()
    }

    // 支付宝返回时，如果设置了 result，会通过 intent 回调
    // 但 payV2 已经通过 pendingResult 直接返回了，这个只做备用
    override fun onResume() {
        super.onResume()
        val resultStr = intent.getStringExtra("payResult")
        if (resultStr != null && pendingResult != null) {
            Log.d("AlipayPlugin", "onResume got payResult from intent: $resultStr")
            try {
                val resultMap = resultStr.split("&").associate {
                    val parts = it.split("=")
                    parts[0] to (parts.getOrElse(1) { "" })
                }
                pendingResult?.success(mapOf(
                    "resultStatus" to resultMap["resultStatus"],
                    "result" to resultStr,
                    "memo" to resultMap["memo"]
                ))
            } catch (e: Exception) {
                Log.e("AlipayPlugin", "onResume parse error: ${e.message}", e)
                pendingResult?.error("PARSE_ERROR", e.message, null)
            }
            pendingResult = null
            intent.removeExtra("payResult")
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        this.intent = intent
    }
}
