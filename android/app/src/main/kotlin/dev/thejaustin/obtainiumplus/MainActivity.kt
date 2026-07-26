package dev.thejaustin.obtainiumplus

import android.accounts.AccountManager
import android.accounts.AccountManagerCallback
import android.accounts.AuthenticatorException
import android.accounts.OperationCanceledException
import android.app.Activity
import android.app.AppOpsManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller
import android.database.Cursor
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.widget.Toast
import androidx.core.content.FileProvider
import java.io.File
import java.io.IOException
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app.obtainiumplus/native"
    private val REQUEST_ACCOUNT_PICKER = 1001

    private companion object {
        const val EXTERNAL_INSTALL_CHANNEL = "dev.imranr.obtainium/external_install"
        const val APK_MIME = "application/vnd.android.package-archive"
    }

    // Holds the pending result while the native account picker Activity is open.
    private var pendingPickerResult: MethodChannel.Result? = null

    // A share intent that arrived before the Flutter engine attached; replayed
    // once configureFlutterEngine runs so the share isn't silently dropped.
    private var pendingShareIntent: Intent? = null

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
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
                    @Suppress("DEPRECATION")
                    startActivityForResult(intent, REQUEST_ACCOUNT_PICKER)
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
                "isUsageAccessGranted" -> {
                    result.success(isUsageAccessGranted())
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
                "setUpdateOwnership" -> {
                    if (Build.VERSION.SDK_INT >= 34) {
                        val packageName = call.argument<String>("packageName")
                        if (packageName != null) {
                            try {
                                val installer = packageManager.packageInstaller
                                // Use reflection to bypass compilation issues with API 34+ methods
                                try {
                                    val method = installer.javaClass.getMethod("setUpdateOwner", String::class.java, String::class.java)
                                    method.invoke(installer, packageName, this.packageName)
                                    result.success(true)
                                } catch (e: Exception) {
                                    // Fallback or error
                                    result.error("ERROR", "Failed to set update owner: ${e.message}", null)
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
                "checkInstallConstraints" -> {
                    if (Build.VERSION.SDK_INT >= 34) {
                        val packageName = call.argument<String>("packageName")
                        if (packageName != null) {
                            try {
                                val installer = packageManager.packageInstaller
                                // Use reflection to bypass compilation issues with API 34+ methods
                                try {
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
                                } catch (e: Exception) {
                                    result.error("ERROR", "Failed to check install constraints via reflection: ${e.message}", null)
                                }
                            } catch (e: Exception) {
                                result.error("ERROR", e.message, null)
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
                                val params = android.content.pm.PackageInstaller.SessionParams(
                                    android.content.pm.PackageInstaller.SessionParams.MODE_FULL_INSTALL
                                )
                                params.setAppPackageName(packageName)
                                
                                // Create a dummy pending intent for the confirmation
                                val intent = Intent("app.obtainiumplus.PREAPPROVAL_CONFIRMATION")
                                val pendingIntent = PendingIntent.getBroadcast(
                                    this, 0, intent, 
                                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                                )
                                
                                // Use reflection to bypass compilation issues with API 34+ methods
                                try {
                                    val method = installer.javaClass.getMethod(
                                        "requestUserPreapproval",
                                        android.content.pm.PackageInstaller.SessionParams::class.java,
                                        android.content.IntentSender::class.java
                                    )
                                    method.invoke(installer, params, pendingIntent.intentSender)
                                    result.success(true)
                                } catch (e: Exception) {
                                    result.error("ERROR", "Failed to request user preapproval: ${e.message}", null)
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
                else -> result.notImplemented()
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

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
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

    private fun getGsfId(): String? {
        val URI = Uri.parse("content://com.google.android.gsf.gservices")
        val ID_KEY = "android_id"
        val params = arrayOf(ID_KEY)
        val c: Cursor? = contentResolver.query(URI, null, null, params, null)

        return try {
            if (c == null || !c.moveToFirst() || c.columnCount < 2) null
            else java.lang.Long.toHexString(java.lang.Long.parseLong(c.getString(1)))
        } catch (e: Exception) {
            null
        } finally {
            c?.close()
        }
    }
}
