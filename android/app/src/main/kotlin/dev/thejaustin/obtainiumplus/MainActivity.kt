package dev.thejaustin.obtainiumplus

import android.accounts.AccountManager
import android.accounts.AccountManagerCallback
import android.accounts.AuthenticatorException
import android.accounts.OperationCanceledException
import android.app.Activity
import android.app.AppOpsManager
import android.app.PendingIntent
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageInstaller
import android.content.pm.PackageManager
import android.database.Cursor
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Rect
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.widget.Toast
import androidx.core.content.FileProvider
import java.io.File
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import rikka.shizuku.Shizuku

class MainActivity : FlutterActivity() {
    private val CHANNEL = "dev.thejaustin.obtainiumplus/native"
    private val REQUEST_ACCOUNT_PICKER = 1001

    private companion object {
        const val EXTERNAL_INSTALL_CHANNEL = "dev.imranr.obtainium/external_install"
        const val DOCUMENT_TREE_CHANNEL = "dev.imranr.obtainium/document_tree"
        const val APK_MIME = "application/vnd.android.package-archive"

        /** Request code for tracked external-installer launches. */
        const val THIRD_PARTY_INSTALL_REQUEST_CODE = 5108

        /** Request code for the read+write document-tree picker. */
        const val DOCUMENT_TREE_REQUEST_CODE = 5209

        /** Hard ceiling for a tracked external install (5 minutes). */
        const val INSTALL_TIMEOUT_MS = 300_000L

        /**
         * After the installer's activity is gone (or focus returns) and no
         * package-change broadcast arrived, keep waiting this long before
         * treating the install as cancelled.
         */
        const val CANCEL_GRACE_MS = 30_000L

        /**
         * After the installer explicitly reports a cancellation, only wait a
         * short time for a last-moment package broadcast before clearing the
         * installing state.
         */
        const val CANCEL_RESULT_GRACE_MS = 5_000L

        /**
         * Extra set by installers that support [Intent.EXTRA_RETURN_RESULT] on
         * failure; holds a PackageManager INSTALL_FAILED_* code. The constant
         * is hidden, so the raw key is used.
         */
        const val EXTRA_INSTALL_RESULT = "android.intent.extra.INSTALL_RESULT"
    }

    // Holds the pending result while the native account picker Activity is open.
    private var pendingPickerResult: MethodChannel.Result? = null

    private var pendingDocumentTreeResult: MethodChannel.Result? = null

    // A share intent that arrived before the Flutter engine attached; replayed
    // once configureFlutterEngine runs so the share isn't silently dropped.
    private var pendingShareIntent: Intent? = null

    private val installHandler = Handler(Looper.getMainLooper())
    private var installWatcher: InstallWatcher? = null

    /**
     * Tracks one external-installer handoff and resolves the pending
     * [MethodChannel.Result] on the first conclusive signal:
     *  - the installer's own result (RESULT_OK/RESULT_FIRST_USER),
     *  - a PACKAGE_ADDED/PACKAGE_REPLACED broadcast for the expected package,
     *  - the cancel grace after the installer activity is gone,
     *  - the hard timeout.
     */
    private inner class InstallWatcher(
        private val methodResult: MethodChannel.Result,
        private val expectedPackageName: String,
    ) {
        var responded = false
        var focusLost = false
        private var graceScheduled = false

        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val changedPackage = intent?.data?.schemeSpecificPart ?: return
                if (changedPackage != expectedPackageName) return
                complete(installed = true, errorCode = null)
            }
        }

        private val graceRunnable = Runnable {
            complete(installed = false, errorCode = null)
        }

        fun scheduleCancelGrace(delayMs: Long = CANCEL_GRACE_MS) {
            if (responded || graceScheduled) return
            graceScheduled = true
            installHandler.postDelayed(graceRunnable, delayMs)
        }

        /** Drops a pending grace: the user went back to the installer. */
        fun cancelGrace() {
            if (!graceScheduled) return
            graceScheduled = false
            installHandler.removeCallbacks(graceRunnable)
        }

        fun complete(installed: Boolean, errorCode: Int?) {
            if (responded) return
            responded = true
            if (installWatcher === this) {
                installWatcher = null
            }
            installHandler.removeCallbacksAndMessages(null)
            try {
                unregisterReceiver(receiver)
            } catch (_: Exception) {
            }
            methodResult.success(
                mapOf(
                    "installed" to installed,
                    "errorCode" to errorCode,
                ),
            )
        }

        fun completeError(code: String, message: String?) {
            if (responded) return
            responded = true
            if (installWatcher === this) {
                installWatcher = null
            }
            installHandler.removeCallbacksAndMessages(null)
            try {
                unregisterReceiver(receiver)
            } catch (_: Exception) {
            }
            methodResult.error(code, message, null)
        }
    }

    @Suppress("DEPRECATION")
    private fun launchInstallIntent(
        uri: String,
        type: String,
        targetPackage: String?,
        targetActivity: String?,
        expectedPackageName: String,
        methodResult: MethodChannel.Result,
    ) {
        // Only one tracked handoff at a time; settle a stale one first.
        installWatcher?.complete(installed = false, errorCode = null)

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(Uri.parse(uri), type)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            putExtra(Intent.EXTRA_RETURN_RESULT, true)
            if (!targetPackage.isNullOrEmpty() && !targetActivity.isNullOrEmpty()) {
                component = ComponentName(targetPackage, targetActivity)
            }
        }
        val watcher = InstallWatcher(methodResult, expectedPackageName)
        installWatcher = watcher
        registerReceiver(
            watcher.receiver,
            IntentFilter().apply {
                addAction(Intent.ACTION_PACKAGE_ADDED)
                addAction(Intent.ACTION_PACKAGE_REPLACED)
                addDataScheme("package")
            },
        )
        installHandler.postDelayed(
            { watcher.complete(installed = false, errorCode = null) },
            INSTALL_TIMEOUT_MS,
        )
        try {
            startActivityForResult(intent, THIRD_PARTY_INSTALL_REQUEST_CODE)
        } catch (e: Exception) {
            watcher.completeError("INSTALL_ERROR", e.message)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        intent?.let {
            setIntent(transformShareIntent(it))
        }
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        val newIntent = transformShareIntent(intent)
        setIntent(newIntent)
        try {
            super.onNewIntent(newIntent)
        } catch (_: Exception) {
            pendingShareIntent = newIntent
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pendingShareIntent?.let {
            super.onNewIntent(it)
            pendingShareIntent = null
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EXTERNAL_INSTALL_CHANNEL,
        ).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "listInstallTargets" -> result.success(listInstallTargets())
                    "contentUriForFile" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrEmpty()) {
                            result.error("BAD_ARGS", "Missing file path", null)
                        } else {
                            try {
                                result.success(contentUriForFile(path))
                            } catch (e: Exception) {
                                result.error("URI_FAILED", e.message, null)
                            }
                        }
                    }
                    "launchInstallIntent" -> {
                        val uri = call.argument<String>("uri")
                        val type = call.argument<String>("type") ?: APK_MIME
                        val targetPackage = call.argument<String>("package")
                        val targetActivity = call.argument<String>("activity")
                        val expectedPackageName = call.argument<String>("expectedPackageName")
                        if (uri.isNullOrEmpty() || expectedPackageName.isNullOrEmpty()) {
                            result.error(
                                "BAD_ARGS",
                                "Missing uri or expectedPackageName",
                                null,
                            )
                        } else {
                            launchInstallIntent(
                                uri,
                                type,
                                targetPackage,
                                targetActivity,
                                expectedPackageName,
                                result,
                            )
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                // An uncaught exception becomes a null reply, which Dart sees as
                // MissingPluginException instead of a catchable PlatformException.
                try { result.error("NATIVE_ERROR", e.message, null) } catch (_: Exception) {}
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DOCUMENT_TREE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickDocumentTree" -> pickDocumentTree(result)
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "getGsfId" -> {
                        val gsfId = getGsfId()
                        if (gsfId != null) result.success(gsfId)
                        else result.error("UNAVAILABLE", "GSF ID not available", null)
                    }
                    "pickGoogleAccount" -> {
                        if (pendingPickerResult != null) {
                            result.error("IN_PROGRESS", "Account picker already open", null)
                            return@setMethodCallHandler
                        }
                        pendingPickerResult = result
                        @Suppress("DEPRECATION")
                        val intent = AccountManager.newChooseAccountIntent(
                            null, null, arrayOf("com.google"),
                            false, null, null, null, null
                        )
                        try {
                            @Suppress("DEPRECATION")
                            startActivityForResult(intent, REQUEST_ACCOUNT_PICKER)
                        } catch (e: Exception) {
                            pendingPickerResult = null
                            result.error("PICKER_UNAVAILABLE", e.message, null)
                        }
                    }
                    "getMicroGToken" -> {
                        val email = call.argument<String>("email")
                        if (email.isNullOrBlank()) {
                            result.error("INVALID_ARGUMENT", "Email is required", null)
                        } else {
                            getMicroGToken(email, result)
                        }
                    }
                    "isVPNActive" -> {
                        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                        val active = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            cm.allNetworks.any { net ->
                                cm.getNetworkCapabilities(net)
                                    ?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true
                            }
                        } else {
                            @Suppress("DEPRECATION")
                            cm.allNetworkInfo?.any { it.typeName == "VPN" && it.isConnected } == true
                        }
                        result.success(active)
                    }
                    "invalidateMicroGToken" -> {
                        val token = call.argument<String>("token")
                        if (token.isNullOrBlank()) {
                            result.error("INVALID_ARGUMENT", "Token is required", null)
                        } else {
                            // Tell the AccountManager the token is stale — next getAuthToken
                            // call will fetch a fresh one from microG rather than returning
                            // the (now invalid) cached copy.
                            AccountManager.get(this).invalidateAuthToken("com.google", token)
                            result.success(null)
                        }
                    }
                    "getPackageName" -> {
                        result.success(packageName)
                    }
                    "abandonStaleSessions" -> {
                        // Abandoned/leaked PackageInstaller sessions for the same package make the
                        // next commit fail with STATUS_FAILURE_CONFLICT; clear ours before installing.
                        val target = call.argument<String>("packageName")
                        var abandoned = 0
                        try {
                            val installer = packageManager.packageInstaller
                            for (info in installer.mySessions) {
                                if (target == null || info.appPackageName == target) {
                                    try {
                                        installer.abandonSession(info.sessionId)
                                        abandoned++
                                    } catch (_: Exception) {
                                    }
                                }
                            }
                        } catch (_: Exception) {
                        }
                        result.success(abandoned)
                    }
                    "isUsageAccessGranted" -> {
                        result.success(isUsageAccessGranted())
                    }
                    "openUsageAccessSettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                                data = Uri.parse("package:$packageName")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (_: Exception) {
                            try {
                                val fallbackIntent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                }
                                startActivity(fallbackIntent)
                                result.success(true)
                            } catch (e: Exception) {
                                result.success(false)
                            }
                        }
                    }
                    "grantUsageAccessShizuku" -> {
                        grantUsageAccessPrivileged(result)
                    }
                    "queryAllUsageStats" -> {
                        val startTime = (call.argument<Number>("startTime"))?.toLong()
                            ?: (System.currentTimeMillis() - 365L * 24 * 60 * 60 * 1000)
                        val endTime = (call.argument<Number>("endTime"))?.toLong()
                            ?: System.currentTimeMillis()
                        // A year of usage events can take a second to
                        // aggregate; keep it off the UI thread.
                        Thread {
                            val stats = try {
                                queryAllUsageStats(startTime, endTime)
                            } catch (_: Throwable) {
                                emptyMap()
                            }
                            runOnUiThread { result.success(stats) }
                        }.start()
                    }
                    "getAppUsageStats" -> {
                        val targetPkg = call.argument<String>("packageName")
                        if (targetPkg == null) {
                            result.error("INVALID_ARGUMENT", "packageName required", null)
                        } else {
                            val startTime = (call.argument<Number>("startTime"))?.toLong()
                                ?: (System.currentTimeMillis() - 365L * 24 * 60 * 60 * 1000)
                            val endTime = (call.argument<Number>("endTime"))?.toLong()
                                ?: System.currentTimeMillis()
                            Thread {
                                val stats = try {
                                    queryAllUsageStats(startTime, endTime)[targetPkg]
                                } catch (_: Throwable) {
                                    null
                                }
                                runOnUiThread { result.success(stats) }
                            }.start()
                        }
                    }
                    "isRooted" -> {
                        result.success(isRooted())
                    }
                    "isMicroGAvailable" -> {
                        val available = try {
                            packageManager.getPackageInfo("com.google.android.gms", 0)
                            true
                        } catch (e: Exception) {
                            false
                        }
                        result.success(available)
                    }
                    "isIgnoringBatteryOptimizations" -> {
                        val powerManager = getSystemService(Context.POWER_SERVICE) as? android.os.PowerManager
                        val isIgnoring = powerManager?.isIgnoringBatteryOptimizations(packageName) ?: false
                        result.success(isIgnoring)
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        try {
                            val intent = Intent(android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:$packageName")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (_: Exception) {
                            try {
                                val fallbackIntent = Intent(android.provider.Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                }
                                startActivity(fallbackIntent)
                                result.success(true)
                            } catch (e: Exception) {
                                result.success(false)
                            }
                        }
                    }
                    "setUpdateOwnership" -> {
                        if (Build.VERSION.SDK_INT >= 34) {
                            val packageName = call.argument<String>("packageName")
                            if (packageName != null) {
                                try {
                                    // In Android 14 (API 34), setUpdateOwnerPackageName is on PackageManager
                                    val method = packageManager.javaClass.getMethod(
                                        "setUpdateOwnerPackageName",
                                        String::class.java,
                                        String::class.java
                                    )
                                    method.invoke(packageManager, packageName, this.packageName)
                                    result.success(true)
                                } catch (_: Exception) {
                                    // Some OEM builds may expose setUpdateOwner on PackageInstaller
                                    try {
                                        val installer = packageManager.packageInstaller
                                        val fallbackMethod = installer.javaClass.getMethod(
                                            "setUpdateOwner",
                                            String::class.java,
                                            String::class.java
                                        )
                                        fallbackMethod.invoke(installer, packageName, this.packageName)
                                        result.success(true)
                                    } catch (e2: Exception) {
                                        result.success(false)
                                    }
                                }
                            } else {
                                result.error("INVALID_ARGUMENT", "Package name is required", null)
                            }
                        } else {
                            result.success(false)
                        }
                    }
                    "checkInstallConstraints" -> {
                        if (Build.VERSION.SDK_INT >= 34) {
                            val packageName = call.argument<String>("packageName")
                            if (packageName != null) {
                                try {
                                    val installer = packageManager.packageInstaller
                                    val builderClass = Class.forName("android.content.pm.PackageInstaller\$InstallConstraints\$Builder")
                                    val builder = builderClass.getDeclaredConstructor().newInstance()
                                
                                    builderClass.getMethod("setAppNotForegroundRequired").invoke(builder)
                                    builderClass.getMethod("setAppNotInteractingRequired").invoke(builder)
                                    builderClass.getMethod("setNotInCallRequired").invoke(builder)
                                
                                    val constraints = builderClass.getMethod("build").invoke(builder)
                                
                                    val packages = listOf(packageName)
                                    val checkMethod = installer.javaClass.getMethod(
                                        "checkInstallConstraints",
                                        List::class.java,
                                        Class.forName("android.content.pm.PackageInstaller\$InstallConstraints"),
                                        java.util.concurrent.Executor::class.java,
                                        java.util.function.Consumer::class.java
                                    )
                                
                                    checkMethod.invoke(
                                        installer,
                                        packages,
                                        constraints,
                                        java.util.concurrent.Executor { command -> command.run() },
                                        java.util.function.Consumer<Any> { resultStatus ->
                                            runOnUiThread {
                                                try {
                                                    val satisfied = resultStatus.javaClass.getMethod("areAllConstraintsSatisfied").invoke(resultStatus) as Boolean
                                                    result.success(satisfied)
                                                } catch (e: Exception) {
                                                    result.error("ERROR", "Failed to check satisfy status: ${e.message}", null)
                                                }
                                            }
                                        }
                                    )
                                } catch (_: Exception) {
                                    result.success(true)
                                }
                            } else {
                                result.error("INVALID_ARGUMENT", "Package name is required", null)
                            }
                        } else {
                            result.success(true)
                        }
                    }
                    "requestUserPreapproval" -> {
                        if (Build.VERSION.SDK_INT >= 34) {
                            val packageName = call.argument<String>("packageName")
                            if (packageName != null) {
                                try {
                                    val installer = packageManager.packageInstaller
                                    val params = PackageInstaller.SessionParams(
                                        PackageInstaller.SessionParams.MODE_FULL_INSTALL
                                    )
                                    params.setAppPackageName(packageName)

                                    val intent = Intent("app.obtainiumplus.PREAPPROVAL_CONFIRMATION")
                                    val pendingIntent = PendingIntent.getBroadcast(
                                        this, 0, intent,
                                        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                                    )

                                    val sessionId = installer.createSession(params)
                                    val session = try {
                                        installer.openSession(sessionId)
                                    } catch (e: Exception) {
                                        try { installer.abandonSession(sessionId) } catch (_: Exception) {}
                                        throw e
                                    }
                                    try {
                                        val builderClass = Class.forName("android.content.pm.PackageInstaller\$PreapprovalDetails\$Builder")
                                        val detailsBuilder = builderClass.getDeclaredConstructor().newInstance()
                                        builderClass.getMethod("setPackageName", String::class.java).invoke(detailsBuilder, packageName)
                                        val label = try {
                                            packageManager.getApplicationLabel(packageManager.getApplicationInfo(packageName, 0)).toString()
                                        } catch (_: Exception) {
                                            packageName
                                        }
                                        builderClass.getMethod("setLabel", CharSequence::class.java).invoke(detailsBuilder, label)
                                        val details = builderClass.getMethod("build").invoke(detailsBuilder)

                                        val preapprovalMethod = session.javaClass.getMethod(
                                            "requestUserPreapproval",
                                            Class.forName("android.content.pm.PackageInstaller\$PreapprovalDetails"),
                                            android.content.IntentSender::class.java
                                        )
                                        preapprovalMethod.invoke(session, details, pendingIntent.intentSender)
                                        session.close()
                                        result.success(true)
                                    } catch (e: Exception) {
                                        session.abandon()
                                        result.success(false)
                                    }
                                } catch (e: Exception) {
                                    result.success(false)
                                }
                            } else {
                                result.error("INVALID_ARGUMENT", "Package name is required", null)
                            }
                        } else {
                            result.success(false)
                        }
                    }
                    "requestArchive" -> {
                        if (Build.VERSION.SDK_INT >= 34) {
                            val packageName = call.argument<String>("packageName")
                            if (packageName != null) {
                                try {
                                    val installer = packageManager.packageInstaller
                                    val intent = Intent("app.obtainiumplus.ARCHIVE_CONFIRMATION")
                                    val pendingIntent = PendingIntent.getBroadcast(
                                        this, 0, intent,
                                        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                                    )
                                    // Reflection: requestArchive() is API 34+ and this module
                                    // may still compile against an older SDK.
                                    try {
                                        val method = installer.javaClass.getMethod(
                                            "requestArchive",
                                            String::class.java,
                                            android.content.IntentSender::class.java
                                        )
                                        method.invoke(installer, packageName, pendingIntent.intentSender)
                                        result.success(true)
                                    } catch (e: Exception) {
                                        result.error("ERROR", "Failed to request archive: ${e.message}", null)
                                    }
                                } catch (e: Exception) {
                                    result.error("ERROR", e.message, null)
                                }
                            } else {
                                result.error("INVALID_ARGUMENT", "Package name is required", null)
                            }
                        } else {
                            result.success(false)
                        }
                    }
                    "isAppArchived" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName == null) {
                            result.error("INVALID_ARGUMENT", "Package name is required", null)
                        } else if (Build.VERSION.SDK_INT >= 34) {
                            try {
                                val info = packageManager.getApplicationInfo(packageName, 0)
                                val method = info.javaClass.getMethod("isArchived")
                                result.success(method.invoke(info) as? Boolean ?: false)
                            } catch (e: Exception) {
                                // Not installed at all reads the same as "not archived" here —
                                // callers only use this to decide whether to show an unarchive
                                // vs. archive action.
                                result.success(false)
                            }
                        } else {
                            result.success(false)
                        }
                    }
                    "getInstalledProfilesAndApps" -> {
                        try {
                            val targetPackage = call.argument<String>("packageName")
                            val userManager = getSystemService(Context.USER_SERVICE) as? android.os.UserManager
                            val launcherApps = getSystemService(Context.LAUNCHER_APPS_SERVICE) as? android.content.pm.LauncherApps
                            val list = mutableListOf<Map<String, Any?>>()

                            if (userManager != null && launcherApps != null) {
                                for (user in userManager.userProfiles) {
                                    val userId = try {
                                        val m = user.javaClass.getMethod("getIdentifier")
                                        m.invoke(user) as? Int ?: 0
                                    } catch (_: Exception) {
                                        user.hashCode()
                                    }
                                    val profileLabel = when (userId) {
                                        0 -> "Main Profile"
                                        10, 11, 12 -> "Work Profile (Insular / Shelter)"
                                        95 -> "Dual Messenger (Samsung)"
                                        999 -> "Parallel Space (Dual Apps)"
                                        else -> "Profile $userId"
                                    }

                                    val activities = try {
                                        launcherApps.getActivityList(targetPackage, user)
                                    } catch (_: Exception) {
                                        emptyList()
                                    }
                                    for (activity in activities) {
                                        val appInfo = activity.applicationInfo
                                        var versionName: String? = null
                                        try {
                                            val pInfo = packageManager.getPackageInfo(appInfo.packageName, 0)
                                            versionName = pInfo.versionName
                                        } catch (_: Exception) {}
                                        list.add(mapOf(
                                            "packageName" to appInfo.packageName,
                                            "label" to activity.label.toString(),
                                            "versionName" to versionName,
                                            "userId" to userId,
                                            "profileLabel" to profileLabel,
                                        ))
                                    }
                                }
                            }
                            result.success(list)
                        } catch (e: Exception) {
                            result.error("PROFILE_DETECTION_FAILED", e.message, null)
                        }
                    }
                    "getLabelsAndIcons" -> {
                        val packages = call.argument<List<String>>("packages") ?: emptyList()
                        val sizePx = (call.argument<Int>("sizePx") ?: 96).coerceIn(16, 512)
                        labelIconExecutor.execute {
                            val out = loadLabelsAndIcons(packages, sizePx)
                            runOnUiThread {
                                try { result.success(out) } catch (_: Exception) {}
                            }
                        }
                    }
                    "getInstallerPackageName" -> {
                        val target = call.argument<String>("packageName")
                        if (target.isNullOrEmpty()) {
                            result.success(null)
                        } else {
                            try {
                                val installer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                                    packageManager.getInstallSourceInfo(target).installingPackageName
                                } else {
                                    @Suppress("DEPRECATION")
                                    packageManager.getInstallerPackageName(target)
                                }
                                result.success(installer)
                            } catch (_: Exception) {
                                result.success(null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                // An uncaught exception becomes a null reply, which Dart sees as
                // MissingPluginException instead of a catchable PlatformException.
                try { result.error("NATIVE_ERROR", e.message, null) } catch (_: Exception) {}
            }
        }
    }

    /**
     * One entry per install-capable activity across all apps. Apps that expose
     * several install-capable activities return all of them so the user can
     * pick the specific intent they want.
     */
    private fun listInstallTargets(): List<Map<String, String>> {
        val targets = ArrayList<Map<String, String>>()
        val probe = Uri.parse("content://$packageName.probe/sample.apk")
        val actions = listOf(Intent.ACTION_VIEW, Intent.ACTION_INSTALL_PACKAGE)
        for (action in actions) {
            @Suppress("DEPRECATION")
            val intent = Intent(action).setDataAndType(probe, APK_MIME)
            for (resolved in packageManager.queryIntentActivities(intent, 0)) {
                val info = resolved.activityInfo ?: continue
                val pkg = info.packageName ?: continue
                if (pkg == packageName) continue
                val activity = info.name ?: continue
                targets.add(mapOf("package" to pkg, "activity" to activity))
            }
        }
        return targets
    }

    /** Exposes a downloaded file through the app's FileProvider as a content:// URI. */
    private fun contentUriForFile(path: String): String {
        val uri = FileProvider.getUriForFile(this, packageName, File(path))
        return uri.toString()
    }

    /** Redirects a shared-text SEND intent to the obtainium://add/ deep link the app already handles. */
    private fun transformShareIntent(intent: Intent): Intent {
        if (intent.action == Intent.ACTION_SEND && intent.type?.startsWith("text/") == true) {
            val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
            val match = sharedText?.let { """https?://[^\s]+""".toRegex().find(it) }
            if (match != null) {
                val url = match.value.trimEnd('.', ',', ';', '!', '?', ')')
                intent.apply {
                    action = Intent.ACTION_VIEW
                    data = Uri.parse("obtainium://add/${Uri.encode(url)}")
                }
            } else {
                Toast.makeText(this, "No URL found in shared text", Toast.LENGTH_SHORT).show()
            }
        }
        return intent
    }

    private fun isRooted(): Boolean {
        val paths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su"
        )
        for (path in paths) {
            if (File(path).exists()) return true
        }
        return false
    }

    private fun isUsageAccessGranted(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /// Single worker so picker batches don't pile up threads; the package
    /// manager and icon rendering run off the Android main thread.
    private val labelIconExecutor: ExecutorService = Executors.newSingleThreadExecutor()

    /// Label + small PNG icon per package for the installed-apps picker. Icons
    /// are rendered at [sizePx] instead of full size, so each one is a few KB.
    private fun loadLabelsAndIcons(packages: List<String>, sizePx: Int): Map<String, Map<String, Any?>> {
        val pm = packageManager
        val out = HashMap<String, Map<String, Any?>>(packages.size)
        for (pkg in packages) {
            try {
                val info = pm.getApplicationInfo(pkg, 0)
                val label = try { pm.getApplicationLabel(info).toString() } catch (_: Exception) { null }
                var icon: ByteArray? = null
                try {
                    val drawable = pm.getApplicationIcon(info)
                    val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
                    val canvas = Canvas(bitmap)
                    val oldBounds = Rect(drawable.bounds)
                    drawable.setBounds(0, 0, sizePx, sizePx)
                    drawable.draw(canvas)
                    drawable.bounds = oldBounds
                    val stream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                    bitmap.recycle()
                    icon = stream.toByteArray()
                } catch (_: Exception) {
                }
                out[pkg] = mapOf("label" to label, "icon" to icon)
            } catch (_: Exception) {
                // Uninstalled since the list was taken, or not visible to us.
            }
        }
        return out
    }

    private fun grantUsageAccessPrivileged(result: MethodChannel.Result) {
        Thread {
            try {
                var methodUsed = "none"
                var succeeded = false

                // 1. Try Shizuku if alive
                var isShizukuAlive = false
                try {
                    isShizukuAlive = Shizuku.pingBinder()
                } catch (_: Throwable) {}

                if (isShizukuAlive) {
                    val shizukuPerm = try {
                        Shizuku.checkSelfPermission()
                    } catch (_: Throwable) {
                        PackageManager.PERMISSION_DENIED
                    }

                    if (shizukuPerm == PackageManager.PERMISSION_GRANTED) {
                        methodUsed = "shizuku"
                        var p: Process? = null
                        try {
                            val newProcessMethod = Shizuku::class.java.getDeclaredMethod(
                                "newProcess",
                                Array<String>::class.java,
                                Array<String>::class.java,
                                String::class.java
                            ).apply { isAccessible = true }
                            p = newProcessMethod.invoke(
                                null,
                                arrayOf("sh", "-c", "appops set $packageName GET_USAGE_STATS allow"),
                                null,
                                null
                            ) as? Process
                            p?.waitFor()
                            succeeded = isUsageAccessGranted()
                        } catch (_: Throwable) {
                        } finally {
                            try {
                                p?.outputStream?.close()
                                p?.inputStream?.close()
                                p?.errorStream?.close()
                            } catch (_: Throwable) {}
                            try { p?.destroy() } catch (_: Throwable) {}
                        }
                    } else {
                        runOnUiThread {
                            result.success(
                                mapOf(
                                    "success" to false,
                                    "status" to "SHIZUKU_PERMISSION_REQUIRED",
                                    "message" to "Shizuku permission not yet granted to Obtainium+"
                                )
                            )
                        }
                        return@Thread
                    }
                }

                // 2. Try root fallback if Shizuku wasn't available or didn't succeed
                if (!succeeded && isRooted()) {
                    var rootProc: Process? = null
                    try {
                        methodUsed = "root"
                        rootProc = Runtime.getRuntime().exec(arrayOf("su", "-c", "appops set $packageName GET_USAGE_STATS allow"))
                        rootProc.waitFor()
                        succeeded = isUsageAccessGranted()
                    } catch (_: Throwable) {
                    } finally {
                        try {
                            rootProc?.outputStream?.close()
                            rootProc?.inputStream?.close()
                            rootProc?.errorStream?.close()
                        } catch (_: Throwable) {}
                        try { rootProc?.destroy() } catch (_: Throwable) {}
                    }
                }

                val finalGranted = isUsageAccessGranted()
                runOnUiThread {
                    result.success(
                        mapOf(
                            "success" to finalGranted,
                            "status" to if (finalGranted) "GRANTED" else if (!isShizukuAlive) "SHIZUKU_NOT_RUNNING" else "FAILED",
                            "method" to methodUsed
                        )
                    )
                }
            } catch (e: Exception) {
                runOnUiThread {
                    result.error("GRANT_ERROR", e.message, null)
                }
            }
        }.start()
    }

    private fun queryAllUsageStats(startTimeMs: Long, endTimeMs: Long): Map<String, Map<String, Long>> {
        if (!isUsageAccessGranted()) {
            return emptyMap()
        }
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return emptyMap()
        val map = HashMap<String, MutableMap<String, Long>>()

        val aggregated = try {
            usm.queryAndAggregateUsageStats(startTimeMs, endTimeMs)
        } catch (_: Exception) {
            null
        }

        if (!aggregated.isNullOrEmpty()) {
            for ((pkg, stats) in aggregated) {
                if (stats.lastTimeUsed > 0 || stats.totalTimeInForeground > 0) {
                    map[pkg] = mutableMapOf(
                        "lastTimeUsed" to stats.lastTimeUsed,
                        "totalForegroundMs" to stats.totalTimeInForeground,
                        "firstTimeStamp" to stats.firstTimeStamp,
                        "lastTimeStamp" to stats.lastTimeStamp
                    )
                }
            }
        } else {
            val statsList = try {
                usm.queryUsageStats(UsageStatsManager.INTERVAL_BEST, startTimeMs, endTimeMs)
            } catch (_: Exception) {
                null
            }
            if (statsList != null) {
                for (usage in statsList) {
                    val existing = map.getOrPut(usage.packageName) {
                        mutableMapOf(
                            "lastTimeUsed" to 0L,
                            "totalForegroundMs" to 0L,
                            "firstTimeStamp" to usage.firstTimeStamp,
                            "lastTimeStamp" to usage.lastTimeStamp
                        )
                    }
                    if (usage.lastTimeUsed > existing["lastTimeUsed"]!!) {
                        existing["lastTimeUsed"] = usage.lastTimeUsed
                    }
                    existing["totalForegroundMs"] = existing["totalForegroundMs"]!! + usage.totalTimeInForeground
                }
            }
        }
        return map
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == THIRD_PARTY_INSTALL_REQUEST_CODE) {
            val watcher = installWatcher
            if (watcher != null && !watcher.responded) {
                when (resultCode) {
                    Activity.RESULT_OK -> watcher.complete(
                        installed = true,
                        errorCode = null,
                    )
                    Activity.RESULT_FIRST_USER -> watcher.complete(
                        installed = false,
                        errorCode = data?.getIntExtra(EXTRA_INSTALL_RESULT, -1),
                    )
                    // RESULT_CANCELED is also what installers that do not
                    // implement EXTRA_RETURN_RESULT produce on finish, and
                    // singleInstance installers (e.g. InstallerX-Revived)
                    // return it immediately. Use a short grace for an explicit
                    // cancel result; the longer grace remains for focus-only
                    // returns.
                    else -> watcher.scheduleCancelGrace(
                        delayMs = CANCEL_RESULT_GRACE_MS,
                    )
                }
            }
            return
        }
        if (requestCode == DOCUMENT_TREE_REQUEST_CODE) {
            val pending = pendingDocumentTreeResult
            pendingDocumentTreeResult = null
            val uri = data?.data
            if (resultCode != Activity.RESULT_OK || uri == null) {
                pending?.success(null)
                return
            }
            try {
                contentResolver.takePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                )
            } catch (_: Exception) {
                // Session-only access; later availability checks report it.
            }
            pending?.success(uri.toString())
            return
        }
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_ACCOUNT_PICKER) {
            val result = pendingPickerResult ?: return
            pendingPickerResult = null
            if (resultCode == Activity.RESULT_OK && data != null) {
                val email = data.getStringExtra(AccountManager.KEY_ACCOUNT_NAME)
                if (email != null) result.success(email)
                else result.error("NO_ACCOUNT", "No account returned from picker", null)
            } else {
                result.error("CANCELLED", "Account selection cancelled", null)
            }
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        val watcher = installWatcher ?: return
        if (watcher.responded) return
        if (!hasFocus) {
            watcher.focusLost = true
            // The user went back to the installer; a pending grace no longer
            // means the install is finished.
            watcher.cancelGrace()
        } else if (watcher.focusLost) {
            // The installer is no longer in front; give a package-change
            // broadcast a short grace before treating the install as cancelled.
            watcher.scheduleCancelGrace()
        }
    }

    override fun onDestroy() {
        installWatcher?.complete(installed = false, errorCode = null)
        pendingPickerResult?.let {
            pendingPickerResult = null
            try { it.error("CANCELLED", "Activity destroyed", null) } catch (_: Exception) {}
        }
        labelIconExecutor.shutdown()
        releaseBackgroundFetchEventSink()
        super.onDestroy()
    }

    /// background_fetch 1.7.0 keeps a process-wide singleton whose stream
    /// handler holds the last EventSink, and through the old engine's plugins
    /// this destroyed Activity, until another Activity attaches (LeakCanary:
    /// BackgroundFetchModule.sInstance). The plugin is null-safe here (it logs
    /// and skips), and the next engine sets a new sink when Dart re-listens.
    private fun releaseBackgroundFetchEventSink() {
        try {
            val module = Class.forName(
                "com.transistorsoft.flutter.backgroundfetch.BackgroundFetchModule"
            )
            val instance = module.getDeclaredField("sInstance")
                .apply { isAccessible = true }
                .get(null) ?: return
            val handler = module.getDeclaredField("mFetchCallback")
                .apply { isAccessible = true }
                .get(instance) ?: return
            handler.javaClass.getDeclaredField("mEventSink")
                .apply { isAccessible = true }
                .set(handler, null)
        } catch (_: Throwable) {
            // Plugin internals changed; nothing to release.
        }
    }

    /**
     * Retrieves a Google Play OAuth2 token for [email] from the microG AccountManager.
     *
     * Passes `this` as the Activity so microG can automatically launch its account
     * consent screen when the user hasn't yet granted Google Play access — the same
     * behaviour as Aurora Store, YouTube ReVanced, and other microG-aware apps.
     */
    private fun getMicroGToken(email: String, result: MethodChannel.Result) {
        val am = AccountManager.get(this)
        val account = am.getAccountsByType("com.google").find { it.name == email }

        if (account == null) {
            result.error(
                "ACCOUNT_NOT_FOUND",
                "Account '$email' was not found. Make sure it is added in microG Settings.",
                null
            )
            return
        }

        // OAuth2 scope for Play Store DFE API — same scope used by Aurora Store.
        val scope = "oauth2:https://www.googleapis.com/auth/googleplay"

        am.getAuthToken(
            account,
            scope,
            Bundle.EMPTY,
            this,  // Activity — microG launches its consent UI automatically if needed
            AccountManagerCallback { future ->
                try {
                    val bundle: Bundle = future.result
                    val token = bundle.getString(AccountManager.KEY_AUTHTOKEN)
                    if (token != null) {
                        result.success(token)
                    } else {
                        result.error(
                            "AUTH_FAILED",
                            "microG returned no token. Check that the account has Google Play " +
                                "scope enabled in microG Settings.",
                            null
                        )
                    }
                } catch (e: OperationCanceledException) {
                    result.error("CANCELLED", "Authentication was cancelled.", null)
                } catch (e: AuthenticatorException) {
                    result.error(
                        "AUTHENTICATOR_ERROR",
                        "microG authenticator error: ${e.message}. " +
                            "Try signing out and back in to the account in microG.",
                        null
                    )
                } catch (e: IOException) {
                    result.error("IO_ERROR", "Network error while fetching token: ${e.message}", null)
                } catch (e: Exception) {
                    result.error("AUTH_EXCEPTION", e.message ?: "Unknown error", null)
                }
            },
            null  // null handler → callback runs on main thread
        )
    }

    /**
     * Opens the system folder picker requesting read+write persistable access.
     * shared_storage can only request one of the two, so a persisted export
     * directory loses read access after a restart (#3227).
     */
    @Suppress("DEPRECATION")
    private fun pickDocumentTree(methodResult: MethodChannel.Result) {
        if (pendingDocumentTreeResult != null) {
            methodResult.error("BUSY", "A folder picker is already open", null)
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
            )
        }
        pendingDocumentTreeResult = methodResult
        try {
            startActivityForResult(intent, DOCUMENT_TREE_REQUEST_CODE)
        } catch (e: Exception) {
            pendingDocumentTreeResult = null
            methodResult.error("NO_PICKER", e.message, null)
        }
    }

    private fun getGsfId(): String? {
        val URI = Uri.parse("content://com.google.android.gsf.gservices")
        val ID_KEY = "android_id"
        val params = arrayOf(ID_KEY)
        var c: Cursor? = null
        return try {
            c = contentResolver.query(URI, null, null, params, null)
            if (c == null || !c.moveToFirst() || c.columnCount < 2) null
            else java.lang.Long.toHexString(java.lang.Long.parseLong(c.getString(1)))
        } catch (e: Exception) {
            null
        } finally {
            c?.close()
        }
    }
}
