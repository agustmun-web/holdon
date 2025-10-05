package com.example.holdon

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class VolumeControllerPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel
    private lateinit var context: Context
    private lateinit var audioManager: AudioManager

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "volume_controller")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setVolume" -> {
                val volume = call.argument<Double>("volume") ?: 0.5
                setVolume(volume, result)
            }
            "getVolume" -> {
                getVolume(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun setVolume(volume: Double, result: Result) {
        try {
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            val targetVolume = (volume * maxVolume).toInt()
            
            audioManager.setStreamVolume(
                AudioManager.STREAM_MUSIC,
                targetVolume,
                AudioManager.FLAG_SHOW_UI
            )
            
            result.success(true)
        } catch (e: Exception) {
            result.error("VOLUME_ERROR", "Error setting volume: ${e.message}", null)
        }
    }

    private fun getVolume(result: Result) {
        try {
            val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            val volumePercentage = currentVolume.toDouble() / maxVolume.toDouble()
            
            result.success(volumePercentage)
        } catch (e: Exception) {
            result.error("VOLUME_ERROR", "Error getting volume: ${e.message}", null)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
