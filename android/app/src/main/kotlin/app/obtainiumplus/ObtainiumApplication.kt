package app.obtainiumplus

import io.flutter.app.FlutterApplication
import leakcanary.LeakCanary
import leakcanary.EventListener
import leakcanary.SharkLog
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class ObtainiumApplication : FlutterApplication() {

    override fun onCreate() {
        super.onCreate()
        
        // Custom LeakCanary config to log to file for CLI analysis
        LeakCanary.config = LeakCanary.config.copy(
            eventListeners = LeakCanary.config.eventListeners + object : EventListener {
                override fun onEvent(event: EventListener.Event) {
                    if (event is EventListener.Event.HeapAnalysisDone.HeapAnalysisSucceeded) {
                        saveLeakToFile(event.heapAnalysis.toString())
                    }
                }
            }
        )
    import io.sentry.Sentry
    import io.sentry.SentryEvent
    import io.sentry.SentryLevel
    import io.sentry.protocol.Message
    ...
        private fun saveLeakToFile(leakTrace: String) {
            try {
                // Also report to Sentry as a non-fatal message with high severity
                val event = SentryEvent()
                event.level = SentryLevel.WARNING
                val message = Message()
                message.message = "Memory Leak Detected by LeakCanary"
                event.message = message
                event.setExtra("leak_trace", leakTrace)
                Sentry.captureEvent(event)

                // Write to a shared storage folder that the CLI (Termux) can access easily
    ...

            val timeStamp = SimpleDateFormat("yyyy-MM-dd_HH-mm-ss", Locale.getDefault()).format(Date())
            val filename = "leak_report_$timeStamp.txt"
            
            // Internal app storage — Termux can access this if Obtainium+ is debuggable
            val leakFile = File(getExternalFilesDir(null), filename)
            
            FileOutputStream(leakFile).use { fos ->
                fos.write(leakTrace.toByteArray())
            }
            
            // Also log it so it shows up in logcat
            SharkLog.d { "Leak trace saved to: ${leakFile.absolutePath}" }
        } catch (e: Exception) {
            SharkLog.d { "Failed to save leak trace: ${e.message}" }
        }
    }
}
