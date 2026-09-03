package com.pmorales.wear_os_scrollbar

import android.os.Build
import android.view.HapticFeedbackConstants
import android.view.InputDevice
import android.view.MotionEvent
import android.view.ViewConfiguration
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** WearOsScrollbarPlugin */
class WearOsScrollbarPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {

    private val ROTARY_CHANNEL = "wear_os_scrollbar/rotary"
    private val METHODS_CHANNEL = "wear_os_scrollbar/methods"

    private var eventChannel: EventChannel? = null
    private var methodChannel: MethodChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var activityBinding: ActivityPluginBinding? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, ROTARY_CHANNEL)
        eventChannel?.setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                        eventSink = events
                    }

                    override fun onCancel(arguments: Any?) {
                        eventSink = null
                    }
                }
        )

        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, METHODS_CHANNEL)
        methodChannel?.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "performHapticFeedback") {
            val type = call.argument<String>("type") ?: "tick"
            performNativeHaptic(type)
            result.success(null)
        } else {
            result.notImplemented()
        }
    }

    private fun performNativeHaptic(type: String) {
        val activity = activityBinding?.activity ?: return
        val view = activity.window?.decorView ?: return

        // Official Wear OS Rotary Haptic Constants:
        // HapticFeedbackConstants.ROTARY_SCROLL_TICK = 18 (API 33+) / Fallback: 10002
        // HapticFeedbackConstants.ROTARY_SCROLL_LIMIT = 19 (API 33+) / Fallback: 10003
        // HapticFeedbackConstants.ROTARY_SCROLL_AXIS_TICK = 20 (API 34+)
        val feedbackConstant = when (type) {
            "limit" -> {
                if (Build.VERSION.SDK_INT >= 33) 19 else 10003
            }
            "axisTick" -> {
                if (Build.VERSION.SDK_INT >= 34) 20 else if (Build.VERSION.SDK_INT >= 33) 18 else 10002
            }
            else -> { // "tick"
                if (Build.VERSION.SDK_INT >= 33) 18 else 10002
            }
        }

        view.isHapticFeedbackEnabled = true
        val performed = view.performHapticFeedback(feedbackConstant)
        if (!performed) {
            view.performHapticFeedback(
                feedbackConstant,
                HapticFeedbackConstants.FLAG_IGNORE_VIEW_SETTING
            )
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        attachRotaryListener()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachRotaryListener()
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        attachRotaryListener()
    }

    override fun onDetachedFromActivity() {
        detachRotaryListener()
        activityBinding = null
    }

    private fun attachRotaryListener() {
        val activity = activityBinding?.activity ?: return
        val viewConfig = ViewConfiguration.get(activity)

        activity.window.decorView.setOnGenericMotionListener { _, event ->
            if (event.action == MotionEvent.ACTION_SCROLL &&
                            event.isFromSource(InputDevice.SOURCE_ROTARY_ENCODER)
            ) {
                val delta = -event.getAxisValue(MotionEvent.AXIS_SCROLL)
                val scrollPixels = delta * viewConfig.scaledVerticalScrollFactor
                eventSink?.success(scrollPixels)
                true
            } else {
                false
            }
        }
    }

    private fun detachRotaryListener() {
        activityBinding?.activity?.window?.decorView?.setOnGenericMotionListener(null)
    }
}
