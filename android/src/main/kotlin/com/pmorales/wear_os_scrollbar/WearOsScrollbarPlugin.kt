package com.pmorales.wear_os_scrollbar

import android.view.InputDevice
import android.view.MotionEvent
import android.view.ViewConfiguration
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel

/** WearOsScrollbarPlugin */
class WearOsScrollbarPlugin : FlutterPlugin, ActivityAware {

    private val CHANNEL = "wear_os_scrollbar/rotary"
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var activityBinding: ActivityPluginBinding? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
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
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        eventChannel?.setStreamHandler(null)
        eventChannel = null
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
