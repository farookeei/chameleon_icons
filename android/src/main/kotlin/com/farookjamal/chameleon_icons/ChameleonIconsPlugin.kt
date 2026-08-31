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
private const val DEFAULT_ICON_ALIAS_META = "com.farookjamal.chameleon_icons.DEFAULT_ICON_ALIAS"

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
            "isAlternateIconsSupported" -> result.success(isAlternateIconsSupported())
            "getCurrentIcon" -> {
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
                    val cleanIconName = currentActivityClassName?.substringAfterLast(".")

                    result.success(cleanIconName)
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
                    changeIconInternal(targetIcon)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("CHANGE_ICON_FAILED", e.localizedMessage, null)
                }
            }

            "resetIcon" -> {
                try {
                    val defaultIconAlias = getDefaultIconAlias()
                    changeIconInternal(defaultIconAlias)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("RESET_ICON_FAILED", e.message, e.localizedMessage)
                }
            }

            else -> result.notImplemented()
        }


    }

    /**
     * Enables the target alias and disables all other aliases.
     */
    private fun changeIconInternal(targetIcon: String) {
        val packageManager: PackageManager = context.packageManager
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
                packageManager.setComponentEnabledSetting(
                    ComponentName(packageName, activityInfo.name),
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP
                )
                Log.d(TAG, "$activityInfo.name:DISABLED")
            }
        }


    }

    /**
     * Retrieves the default icon alias name from AndroidManifest.xml metadata.
     *
     * Throws [IllegalStateException] if metadata is not configured.
     */
    private fun getDefaultIconAlias(): String {
        return try {
            val applicationInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.packageManager.getApplicationInfo(
                    packageName, PackageManager.ApplicationInfoFlags.of(
                        PackageManager.GET_META_DATA.toLong()
                    )
                )
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)

            }

            applicationInfo.metaData.getString(DEFAULT_ICON_ALIAS_META)
                ?: throw IllegalStateException(
                    "Meta-data '$DEFAULT_ICON_ALIAS_META' not found in AndroidManifest.xml. " +
                            "Please add: <meta-data android:name=\"$DEFAULT_ICON_ALIAS_META\" android:value=\"YourDefaultAliasName\" />"
                )
        } catch (e: PackageManager.NameNotFoundException) {
            throw IllegalStateException("Application meta-data could not be retrieved", e)
        }
    }

    private fun isAlternateIconsSupported(): Boolean {
        try {
            getDefaultIconAlias()
            return true;
        } catch (e: Exception) {
            return false
        }
    }


    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
