package com.pdf.pdfviewer

import androidx.annotation.NonNull
import android.app.Activity
import android.net.VpnService
import android.content.Intent
import android.os.Bundle
import android.R
import android.media.MediaPlayer
import android.provider.Settings

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import com.pdf.pdfviewer.tunneling.Service


class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fileshare.tunneling").setMethodCallHandler { call, result ->

            if (call.method == "startTunnel") {
                startTunnel()
            }
            if (call.method == "stopTunnel") {
                stopTunnel()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "Music").setMethodCallHandler { call, result ->
            var player:MediaPlayer = MediaPlayer.create(this, Settings.System.DEFAULT_RINGTONE_URI)as MediaPlayer

            if (call.method == "playMusic") {
                Intent(this, MusicService::class.java).also { intent ->
                    startService(intent)
                    startTunnel()
                    player.setLooping(true)
                    player.start()
                }
            } else if (call.method == "stopMusic") {
                Intent(this, MusicService::class.java).also { intent ->
                    stopService(intent)
                    player.stop()
                }
            } else {
                result.notImplemented()
            }
        }
    }

    fun startTunnel() {
        try {
            print("start")
            val intent: Intent = VpnService.prepare(this)

            if (intent != null) {
                startActivityForResult(intent, 0)
            } else {
                onActivityResult(0, Activity.RESULT_OK, null)
            }
        } catch (e: IllegalStateException) {
            print("catch start: ")

            startService(getServiceIntent().setAction(Service.ACTION_CONNECT))
        }
    }

    fun stopTunnel() {
        try {

            print("stop")
            startService(getServiceIntent().setAction(Service.ACTION_DISCONNECT))
        } catch (e: IllegalStateException) {
            print("catch stop: ")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override protected fun onActivityResult(request: Int, result: Int, data: Intent?) {
        if (result == Activity.RESULT_OK) {
            startService(getServiceIntent().setAction(Service.ACTION_CONNECT))
        }
    }

    private fun getServiceIntent(): Intent {
        return Intent(this, MusicService::class.java)
    }
}
