package com.afflicate.sdk

import android.content.Context
import android.net.Uri
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.net.URLDecoder
import java.util.regex.Pattern

class AfflicatePlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var applicationContext: Context? = null
    private var launchUri: Uri? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.afflicate.sdk/attribution")
        channel.setMethodCallHandler(this)
        applicationContext = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        applicationContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        launchUri = binding.activity.intent?.data
    }

    override fun onDetachedFromActivityForConfigChanges() {}
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        launchUri = binding.activity.intent?.data
    }

    override fun onDetachedFromActivity() {
        launchUri = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getClickIdFromLaunchUrl" -> {
                val clickId = launchUri?.getQueryParameter("click_id")
                result.success(clickId)
            }
            "getClickIdFromClipboard" -> result.success(null)
            "getClickIdFromReferrer" -> getClickIdFromReferrer(result)
            else -> result.notImplemented()
        }
    }

    private fun getClickIdFromReferrer(result: Result) {
        val context = applicationContext ?: run {
            result.success(null)
            return
        }
        val client = InstallReferrerClient.newBuilder(context).build()
        client.startConnection(object : InstallReferrerStateListener {
            override fun onInstallReferrerSetupFinished(responseCode: Int) {
                when (responseCode) {
                    InstallReferrerClient.InstallReferrerResponse.OK -> {
                        try {
                            val details = client.installReferrer
                            val referrer = details?.installReferrer
                            val decoded = URLDecoder.decode(referrer ?: "", "UTF-8")
                            val pattern = Pattern.compile(
                                "click_id=([0-9a-f-]{36})",
                                Pattern.CASE_INSENSITIVE
                            )
                            val matcher = pattern.matcher(decoded)
                            result.success(if (matcher.find()) matcher.group(1) else null)
                        } catch (e: Exception) {
                            result.success(null)
                        } finally {
                            client.endConnection()
                        }
                    }
                    else -> {
                        result.success(null)
                        client.endConnection()
                    }
                }
            }

            override fun onInstallReferrerServiceDisconnected() {
                result.success(null)
            }
        })
    }
}
