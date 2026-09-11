package com.powernews.app.power_news_app

import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity: FlutterActivity(), TextToSpeech.OnInitListener {
    private val CHANNEL = "com.powernews.app/tts"
    private var tts: TextToSpeech? = null
    private var isTtsInitialized = false
    private var methodChannel: MethodChannel? = null
    private var currentText: String = ""
    private var currentRate: Float = 1.0f
    private var isCurrentlySpeaking: Boolean = false
    private var currentSpeechCharIndex: Int = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        tts = TextToSpeech(this, this)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "speak" -> {
                    val text = call.argument<String>("text") ?: ""
                    val rate = (call.argument<Double>("rate") ?: 1.0).toFloat()
                    currentText = text
                    currentRate = rate
                    currentSpeechCharIndex = 0
                    if (isTtsInitialized && text.isNotEmpty()) {
                        tts?.setSpeechRate(rate)
                        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "POWER_TTS_UTTERANCE")
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "stop" -> {
                    isCurrentlySpeaking = false
                    currentSpeechCharIndex = 0
                    tts?.stop()
                    result.success(true)
                }
                "setRate" -> {
                    val rate = (call.argument<Double>("rate") ?: 1.0).toFloat()
                    currentRate = rate
                    tts?.setSpeechRate(rate)

                    // Seamless speed update: Never restart from the beginning!
                    // If currently speaking, resume from the exact word currently being spoken.
                    if (isCurrentlySpeaking && currentText.isNotEmpty() && currentSpeechCharIndex > 0) {
                        val resumeIndex = findResumeCharIndex(currentText, currentSpeechCharIndex)
                        if (resumeIndex < currentText.length) {
                            val remaining = currentText.substring(resumeIndex).trim()
                            if (remaining.isNotEmpty()) {
                                currentText = remaining
                                currentSpeechCharIndex = 0
                                tts?.speak(remaining, TextToSpeech.QUEUE_FLUSH, null, "POWER_TTS_UTTERANCE")
                            }
                        }
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun findResumeCharIndex(text: String, charIndex: Int): Int {
        if (charIndex <= 0) return 0
        if (charIndex >= text.length) return text.length
        var i = charIndex
        while (i > 0 && i > charIndex - 30 && !Character.isWhitespace(text[i - 1])) {
            i--
        }
        return i
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            val indianLocale = Locale("en", "IN")
            val langResult = tts?.setLanguage(indianLocale)
            if (langResult == TextToSpeech.LANG_MISSING_DATA || langResult == TextToSpeech.LANG_NOT_SUPPORTED) {
                tts?.setLanguage(Locale.US)
            }

            // Best Announcer: Search available voices for high-quality natural Indian English
            try {
                val availableVoices = tts?.voices
                if (availableVoices != null) {
                    val preferredVoice = availableVoices.find { voice ->
                        voice.locale.language == "en" && 
                        voice.locale.country == "IN" && 
                        !voice.isNetworkConnectionRequired &&
                        voice.quality >= Voice.QUALITY_HIGH
                    } ?: availableVoices.find { voice ->
                        voice.locale.language == "en" && voice.locale.country == "IN"
                    } ?: availableVoices.find { voice ->
                        voice.locale.language == "en" && voice.quality >= Voice.QUALITY_HIGH
                    }

                    if (preferredVoice != null) {
                        tts?.voice = preferredVoice
                    }
                }
            } catch (e: Exception) {
                // Graceful fallback to default engine voice
            }

            tts?.setPitch(1.0f)
            tts?.setSpeechRate(currentRate)

            tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) {
                    isCurrentlySpeaking = true
                    runOnUiThread { methodChannel?.invokeMethod("onStart", null) }
                }
                override fun onDone(utteranceId: String?) {
                    isCurrentlySpeaking = false
                    currentSpeechCharIndex = 0
                    runOnUiThread { methodChannel?.invokeMethod("onDone", null) }
                }
                override fun onError(utteranceId: String?) {
                    isCurrentlySpeaking = false
                    currentSpeechCharIndex = 0
                    runOnUiThread { methodChannel?.invokeMethod("onError", null) }
                }
                override fun onRangeStart(utteranceId: String?, start: Int, end: Int, frame: Int) {
                    super.onRangeStart(utteranceId, start, end, frame)
                    currentSpeechCharIndex = start
                }
            })
            isTtsInitialized = true
        }
    }

    override fun onDestroy() {
        tts?.stop()
        tts?.shutdown()
        super.onDestroy()
    }
}
