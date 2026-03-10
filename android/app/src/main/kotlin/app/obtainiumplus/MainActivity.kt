package app.obtainiumplus

import android.accounts.AccountManager
import android.accounts.AccountManagerCallback
import android.accounts.AuthenticatorException
import android.accounts.OperationCanceledException
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.os.Build
import android.os.Bundle
import java.io.IOException
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app.obtainiumplus/native"
    private val REQUEST_ACCOUNT_PICKER = 1001

    // Holds the pending result while the native account picker Activity is open.
    private var pendingPickerResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
                else -> result.notImplemented()
            }
        }
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
