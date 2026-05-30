package dev.thejaustin.obtainium.plus

import io.flutter.app.FlutterApplication
import app.obtainiumplus.initLeakCanary

class ObtainiumApplication : FlutterApplication() {

    override fun onCreate() {
        super.onCreate()
        initLeakCanary(this)
    }
}
