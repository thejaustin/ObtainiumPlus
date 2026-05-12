package dev.imranr.obtainium

import io.flutter.app.FlutterApplication

class ObtainiumApplication : FlutterApplication() {

    override fun onCreate() {
        super.onCreate()
        initLeakCanary(this)
    }
}
