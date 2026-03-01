package app.obtainiumplus

import android.database.Cursor
import android.net.Uri
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
                else -> result.notImplemented()
            }
        }
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
