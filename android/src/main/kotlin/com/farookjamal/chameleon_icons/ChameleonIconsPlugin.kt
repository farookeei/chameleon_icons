package com.farookjamal.chameleon_icons

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

private const val TAG = "ChameleonIcons"

/** ChameleonIconsPlugin */
class ChameleonIconsPlugin :
    FlutterPlugin,
    MethodCallHandler {
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var packageName: String

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "chameleon_icons")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        packageName = context.packageName
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            "getCurrentIconClassName" -> {
                try {
                    val intent = Intent(Intent.ACTION_MAIN).apply {
                        addCategory(Intent.CATEGORY_LAUNCHER)
                        setPackage(packageName)
                    }
                    val resolveInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        context.packageManager.resolveActivity(
                            intent,
                            PackageManager.ResolveInfoFlags.of(0)
                        )
                    } else {
                        @Suppress("DEPRECATION")
                        context.packageManager.resolveActivity(intent, 0)
                    }
                    val currentActivityClassName = resolveInfo?.activityInfo?.name

                    result.success(currentActivityClassName)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to get the current icon class name", null)
                }
            }

            "changeIcon" -> {
                val targetIcon = call.argument<String>("targetIcon")

                if (targetIcon == null) {
                    result.error("INVALID_ARGS", "targetIcon cannot be null", null)
                    return
                }

                try {
                    val flags =
                        PackageManager.GET_ACTIVITIES or PackageManager.MATCH_DISABLED_COMPONENTS
                    val packageInfo: PackageInfo

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        packageInfo = context.packageManager.getPackageInfo(
                            packageName,
                            PackageManager.PackageInfoFlags.of(flags.toLong())
                        )
                    } else {
                        @Suppress("DEPRECATION")
                        packageInfo = context.packageManager.getPackageInfo(packageName, flags)
                    }
                    val allActivities = packageInfo.activities ?: emptyArray()
                    //enabling the desired class
                    val targetActivity = "$packageName.$targetIcon";
                    val component = ComponentName(packageName, targetActivity)
                    context.packageManager.setComponentEnabledSetting(
                        component,
                        PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                        PackageManager.DONT_KILL_APP
                    )
                    Log.v(TAG, "$packageName.$targetIcon:ENABLED")
                    for (activityInfo in allActivities) {
                        if (activityInfo.name != targetActivity && !activityInfo.name.endsWith(".MainActivity")) {
                            context.packageManager.setComponentEnabledSetting(
                                ComponentName(packageName, activityInfo.name),
                                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                                PackageManager.DONT_KILL_APP
                            )
                            Log.d(TAG, "$activityInfo.name:DISABLED")
                        }
                    }
                    result.success(true)

                } catch (e: Exception) {
                    result.error("CHANGE_ICON_FAILED", e.localizedMessage, null)
                }
            }

            else -> result.notImplemented()
        }


    }


    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
