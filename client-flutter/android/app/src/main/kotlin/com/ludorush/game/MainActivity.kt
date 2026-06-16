package com.ludorush.game

import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val handler = Handler(Looper.getMainLooper())
    private var toneGenerator: ToneGenerator? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ludo_rush/sound")
            .setMethodCallHandler { call, result ->
                if (call.method != "play") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                playEffect(call.arguments as? String ?: "tap")
                result.success(null)
            }
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        toneGenerator?.release()
        toneGenerator = null
        super.onDestroy()
    }

    private fun playEffect(effect: String) {
        when (effect) {
            "roll" -> {
                tone(ToneGenerator.TONE_PROP_BEEP2, 55, 0)
                tone(ToneGenerator.TONE_DTMF_5, 55, 70)
                tone(ToneGenerator.TONE_DTMF_8, 70, 145)
            }
            "move" -> tone(ToneGenerator.TONE_DTMF_A, 95, 0)
            "success" -> {
                tone(ToneGenerator.TONE_DTMF_3, 80, 0)
                tone(ToneGenerator.TONE_DTMF_6, 90, 95)
                tone(ToneGenerator.TONE_DTMF_9, 130, 205)
            }
            "warning" -> tone(ToneGenerator.TONE_PROP_NACK, 180, 0)
            else -> tone(ToneGenerator.TONE_PROP_BEEP, 35, 0)
        }
    }

    private fun tone(toneType: Int, durationMs: Int, delayMs: Long) {
        handler.postDelayed({
            try {
                if (toneGenerator == null) {
                    toneGenerator = ToneGenerator(AudioManager.STREAM_MUSIC, 85)
                }
                toneGenerator?.startTone(toneType, durationMs)
            } catch (_: RuntimeException) {
                toneGenerator?.release()
                toneGenerator = null
            }
        }, delayMs)
    }
}
