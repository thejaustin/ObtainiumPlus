package app.obtainiumplus

import android.accounts.Account
import android.accounts.AccountManager
import android.database.Cursor
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app.obtainiumplus/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getGsfId" -> {
                    val gsfId = getGsfId()
                    if (gsfId != null) {
                        result.success(gsfId)
                    } else {
                        result.error("UNAVAILABLE", "GSF ID not available", null)
                    }
                }
                "getAccounts" -> {
                    val am = AccountManager.get(this)
                    val accounts = am.getAccountsByType("com.google")
                    val emails = accounts.map { it.name }
                    result.success(emails)
                }
                "getMicroGToken" -> {
                    val email = call.argument<String>("email")
                    if (email == null) {
                        result.error("INVALID_ARGUMENT", "Email is required", null)
                        return@setMethodCallHandler
                    }
                    getMicroGToken(email, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getMicroGToken(email: String, result: MethodChannel.Result) {
        val am = AccountManager.get(this)
        val accounts = am.getAccountsByType("com.google")
        val account = accounts.find { it.name == email }

        if (account == null) {
            result.error("ACCOUNT_NOT_FOUND", "Account not found on device", null)
            return
        }

        val scope = "oauth2:https://www.googleapis.com/auth/googleplay"
        
        am.getAuthToken(account, scope, null, this, { future ->
            try {
                val bundle: Bundle = future.result
                val token = bundle.getString(AccountManager.KEY_AUTHTOKEN)
                if (token != null) {
                    result.success(token)
                } else {
                    result.error("AUTH_FAILED", "Token was null", null)
                }
            } catch (e: Exception) {
                result.error("AUTH_EXCEPTION", e.message, null)
            }
        }, null)
    }

    private fun getGsfId(): String? {
        val URI = Uri.parse("content://com.google.android.gsf.gservices")
        val ID_KEY = "android_id"
        val params = arrayOf(ID_KEY)
        val c: Cursor? = contentResolver.query(URI, null, null, params, null)
        
        return try {
            if (c == null || !c.moveToFirst() || c.columnCount < 2) {
                null
            } else {
                java.lang.Long.toHexString(java.lang.Long.parseLong(c.getString(1)))
            }
        } catch (e: Exception) {
            null
        } finally {
            c?.close()
        }
    }
}
