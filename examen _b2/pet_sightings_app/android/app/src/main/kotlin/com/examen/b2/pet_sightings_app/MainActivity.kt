package com.examen.b2.pet_sightings_app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Puente nativo para el contrato de Intents del flujo "Mascota Perdida"
 * (ver CONTRATO_INTENTS.md). Expone los extras del Intent entrante hacia
 * Dart por dos canales:
 *  - MethodChannel "com.examenb2.petflow/intent", método "getInitialExtras":
 *    extras con los que se lanzó la Activity (cold start).
 *  - EventChannel "com.examenb2.petflow/intent_stream": nuevos extras que
 *    lleguen mientras la app ya está abierta (onNewIntent), porque
 *    launchMode="singleTop" hace que Android reutilice esta misma Activity.
 */
class MainActivity : FlutterActivity() {
    private val methodChannelName = "com.examenb2.petflow/intent"
    private val eventChannelName = "com.examenb2.petflow/intent_stream"
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "getInitialExtras") {
                    result.success(bundleToMap(intent.extras))
                } else {
                    result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    eventSink = sink
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    override fun onNewIntent(newIntent: Intent) {
        super.onNewIntent(newIntent)
        intent = newIntent
        eventSink?.success(bundleToMap(newIntent.extras))
    }

    private fun bundleToMap(extras: Bundle?): Map<String, Any?>? {
        if (extras == null) return null
        val map = HashMap<String, Any?>()
        for (key in extras.keySet()) {
            @Suppress("DEPRECATION")
            map[key] = extras.get(key)
        }
        return map
    }
}
