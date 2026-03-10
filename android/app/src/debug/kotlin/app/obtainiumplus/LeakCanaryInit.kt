package app.obtainiumplus

import android.app.Application
import android.util.Log
import io.sentry.Sentry
import io.sentry.SentryEvent
import io.sentry.SentryLevel
import io.sentry.protocol.Message
import leakcanary.EventListener
import leakcanary.LeakCanary
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

fun initLeakCanary(app: Application) {
    LeakCanary.config = LeakCanary.config.copy(
        eventListeners = LeakCanary.config.eventListeners + object : EventListener {
            override fun onEvent(event: EventListener.Event) {
                if (event is EventListener.Event.HeapAnalysisDone.HeapAnalysisSucceeded) {
                    saveLeakToFile(app, event.heapAnalysis.toString())
                }
            }
        }
    )
}

private fun saveLeakToFile(app: Application, leakTrace: String) {
    try {
        val event = SentryEvent()
        event.level = SentryLevel.WARNING
        val message = Message()
        message.message = "Memory Leak Detected by LeakCanary"
        event.message = message
        event.setExtra("leak_trace", leakTrace)
        Sentry.captureEvent(event)

        val timeStamp = SimpleDateFormat("yyyy-MM-dd_HH-mm-ss", Locale.getDefault()).format(Date())
        val leakFile = File(app.getExternalFilesDir(null), "leak_report_$timeStamp.txt")
        FileOutputStream(leakFile).use { it.write(leakTrace.toByteArray()) }
        Log.d("LeakCanary", "Leak trace saved to: ${leakFile.absolutePath}")
    } catch (e: Exception) {
        Log.d("LeakCanary", "Failed to save leak trace: ${e.message}")
    }
}
