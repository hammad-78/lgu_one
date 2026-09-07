package com.example.lgu_one

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val notificationPermissionRequestCode = 1001
	private var pendingNotificationPermissionResult: MethodChannel.Result? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			"lgu_one/notifications",
		).setMethodCallHandler { call, result ->
			if (call.method != "requestNotificationPermission") {
				result.notImplemented()
				return@setMethodCallHandler
			}

			if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
				ContextCompat.checkSelfPermission(
					this,
					Manifest.permission.POST_NOTIFICATIONS,
				) == PackageManager.PERMISSION_GRANTED
			) {
				result.success(true)
				return@setMethodCallHandler
			}

			pendingNotificationPermissionResult = result
			ActivityCompat.requestPermissions(
				this,
				arrayOf(Manifest.permission.POST_NOTIFICATIONS),
				notificationPermissionRequestCode,
			)
		}
	}

	override fun onRequestPermissionsResult(
		requestCode: Int,
		permissions: Array<out String>,
		grantResults: IntArray,
	) {
		super.onRequestPermissionsResult(requestCode, permissions, grantResults)
		if (requestCode == notificationPermissionRequestCode) {
			pendingNotificationPermissionResult?.success(
				grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED,
			)
			pendingNotificationPermissionResult = null
		}
	}
}
