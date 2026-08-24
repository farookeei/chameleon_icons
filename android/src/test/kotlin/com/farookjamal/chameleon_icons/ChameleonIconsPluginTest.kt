package com.farookjamal.chameleon_icons

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
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
