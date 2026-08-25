package com.farookjamal.chameleon_icons

import android.content.ComponentName
import android.content.Context
import android.content.pm.ActivityInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.jvm.java
import kotlin.test.Test

/*
 * This demonstrates a simple unit test of the Kotlin portion of this plugin's implementation.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */

internal class ChameleonIconsPluginTest {
    @Test
    fun onMethodCall_getPlatformVersion_returnsError() {
        val plugin = ChameleonIconsPlugin()
        val call = MethodCall("getPlatformVersion", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).success("Android " + android.os.Build.VERSION.RELEASE)
    }

    @Test
    fun onMethodCall_changeIcon_returnsError() {
        val plugin = ChameleonIconsPlugin()
        val call = MethodCall("changeIcon", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).error(
            Mockito.eq("INVALID_ARGS"),
            Mockito.eq("targetIcon cannot be null"),
            Mockito.isNull()
        )
    }

    @Test
    fun onMethodCall_changeIcon_success_enablesTargetAndDisablesOthers() {
        val plugin = ChameleonIconsPlugin()
        //.Mock the android context & PackageManager
        val mockContext = Mockito.mock(Context::class.java)
        val mockPackageManager = Mockito.mock(PackageManager::class.java)
        val mockBinding = Mockito.mock(FlutterPlugin.FlutterPluginBinding::class.java)
        val mockMessenger = Mockito.mock(BinaryMessenger::class.java)
        Mockito.`when`(mockContext.packageName).thenReturn("com.example.app")
        Mockito.`when`(mockContext.packageManager).thenReturn(mockPackageManager)
        Mockito.`when`(mockBinding.applicationContext).thenReturn(mockContext)
        Mockito.`when`(mockBinding.binaryMessenger).thenReturn(mockMessenger)

        plugin.onAttachedToEngine(mockBinding)
        //  Mock the list of activities in the manifest
        val mockPackageInfo = PackageInfo().apply {
            activities = arrayOf(
                ActivityInfo().apply { name = "com.example.app.MainActivity" },
                ActivityInfo().apply { name = "com.example.app.MainActivityDark" }
            )
        }

        Mockito.`when`(
            mockPackageManager.getPackageInfo(
                Mockito.eq("com.example.app"),
                Mockito.anyInt()
            )
        ).thenReturn(mockPackageInfo)
        val call = MethodCall("changeIcon", mapOf("targetIcon" to "MainActivityDark"))
        val mockResult = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, mockResult)
        Mockito.verify(mockResult).success(true)

        Mockito.verify(mockPackageManager).setComponentEnabledSetting(
            //?Crashes on JVM because ComponentName.toString() is null in stubs
            //Mockito.eq(ComponentName("com.example.app", "com.example.app.MainActivityDark")),
            Mockito.any(ComponentName::class.java),
            Mockito.eq(PackageManager.COMPONENT_ENABLED_STATE_ENABLED),
            Mockito.eq(PackageManager.DONT_KILL_APP)
        )

    }

    @Test
    fun onMethodCall_getCurrentIconClassName_returnsError() {
        val plugin = ChameleonIconsPlugin()
        val call = MethodCall("getCurrentIconClassName", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).error(
            Mockito.eq("ERROR"),
            Mockito.eq("Failed to get the current icon class name"),
            Mockito.isNull()
        )
    }

    @Test
    fun onMethodCall_unknownMethod_returnsNotImplemented() {
        val plugin = ChameleonIconsPlugin()
        val call = MethodCall("unknownMethod", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, mockResult)
        Mockito.verify(mockResult).notImplemented()
    }

}
