package com.ludorush.game

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread
import kotlin.math.PI
import kotlin.math.exp
import kotlin.math.sin

class MainActivity : FlutterActivity() {
    private val handler = Handler(Looper.getMainLooper())
    private val sampleRate = 22050
    private val activeTracks = mutableSetOf<AudioTrack>()

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
        synchronized(activeTracks) {
            activeTracks.forEach { track ->
                try {
                    track.stop()
                } catch (_: IllegalStateException) {
                }
                track.release()
            }
            activeTracks.clear()
        }
        super.onDestroy()
    }

    private fun playEffect(effect: String) {
        thread(name = "LudoSound-$effect") {
            val samples = when (effect) {
                "roll" -> diceRollSound()
                "move" -> pieceMoveSound()
                "success" -> winSound()
                "warning" -> warningSound()
                else -> tapSound()
            }
            playSamples(samples)
        }
    }

    private fun playSamples(samples: ShortArray) {
        if (samples.isEmpty()) return
        val track = try {
            AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_GAME)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(sampleRate)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build()
                )
                .setTransferMode(AudioTrack.MODE_STATIC)
                .setBufferSizeInBytes(samples.size * 2)
                .build()
        } catch (_: RuntimeException) {
            return
        }

        synchronized(activeTracks) {
            activeTracks.add(track)
        }
        try {
            track.write(samples, 0, samples.size)
            track.play()
        } catch (_: RuntimeException) {
            synchronized(activeTracks) {
                activeTracks.remove(track)
            }
            track.release()
            return
        }

        val releaseDelayMs = samples.size * 1000L / sampleRate + 260L
        handler.postDelayed({
            synchronized(activeTracks) {
                activeTracks.remove(track)
            }
            try {
                track.stop()
            } catch (_: IllegalStateException) {
            }
            track.release()
        }, releaseDelayMs)
    }

    private fun tapSound(): ShortArray = buildSound(95) { buffer ->
        addSine(buffer, 0, 56, 920.0, 0.46, 4.0)
        addSine(buffer, 14, 45, 1380.0, 0.16, 5.5)
    }

    private fun diceRollSound(): ShortArray = buildSound(430) { buffer ->
        for (i in 0 until 7) {
            val start = i * 45
            val volume = 0.42 - i * 0.035
            addNoise(buffer, start, 30, volume, 9001 + i * 73)
            addSine(buffer, start, 42, 150.0 + i * 28.0, 0.12, 3.2)
        }
        addSine(buffer, 322, 90, 210.0, 0.20, 4.0)
        addNoise(buffer, 335, 26, 0.20, 14431)
    }

    private fun pieceMoveSound(): ShortArray = buildSound(210) { buffer ->
        addNoise(buffer, 0, 24, 0.34, 811)
        addSine(buffer, 0, 150, 118.0, 0.55, 5.0)
        addSine(buffer, 32, 115, 246.0, 0.23, 4.8)
    }

    private fun winSound(): ShortArray = buildSound(540) { buffer ->
        addSine(buffer, 0, 185, 523.25, 0.36, 2.0)
        addSine(buffer, 92, 205, 659.25, 0.34, 2.0)
        addSine(buffer, 188, 260, 783.99, 0.38, 2.2)
        addSine(buffer, 285, 180, 1174.66, 0.14, 3.2)
        addNoise(buffer, 250, 72, 0.09, 4207)
    }

    private fun warningSound(): ShortArray = buildSound(360) { buffer ->
        addSine(buffer, 0, 170, 176.0, 0.48, 2.4)
        addSine(buffer, 150, 180, 132.0, 0.42, 2.5)
        addNoise(buffer, 0, 36, 0.10, 6161)
    }

    private inline fun buildSound(
        durationMs: Int,
        block: (FloatArray) -> Unit
    ): ShortArray {
        val buffer = FloatArray(sampleRate * durationMs / 1000)
        block(buffer)
        val out = ShortArray(buffer.size)
        for (i in buffer.indices) {
            val clamped = buffer[i].coerceIn(-0.92f, 0.92f)
            out[i] = (clamped * Short.MAX_VALUE).toInt().toShort()
        }
        return out
    }

    private fun addSine(
        buffer: FloatArray,
        startMs: Int,
        durationMs: Int,
        frequency: Double,
        volume: Double,
        decay: Double
    ) {
        val start = startMs * sampleRate / 1000
        val length = durationMs * sampleRate / 1000
        for (i in 0 until length) {
            val idx = start + i
            if (idx !in buffer.indices) break
            val progress = i.toDouble() / length.coerceAtLeast(1)
            val envelope = sin(progress * PI).coerceAtLeast(0.0) * exp(-decay * progress)
            val seconds = i.toDouble() / sampleRate
            buffer[idx] += (sin(2.0 * PI * frequency * seconds) * volume * envelope).toFloat()
        }
    }

    private fun addNoise(
        buffer: FloatArray,
        startMs: Int,
        durationMs: Int,
        volume: Double,
        seed: Int
    ) {
        var localSeed = seed
        val start = startMs * sampleRate / 1000
        val length = durationMs * sampleRate / 1000
        for (i in 0 until length) {
            val idx = start + i
            if (idx !in buffer.indices) break
            localSeed = localSeed * 1664525 + 1013904223
            val random = ((localSeed ushr 8) and 0xffff) / 32768.0 - 1.0
            val progress = i.toDouble() / length.coerceAtLeast(1)
            val envelope = sin(progress * PI).coerceAtLeast(0.0) * exp(-5.2 * progress)
            buffer[idx] += (random * volume * envelope).toFloat()
        }
    }
}
