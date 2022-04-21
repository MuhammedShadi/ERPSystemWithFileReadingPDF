package com.pdf.pdfviewer

import android.annotation.TargetApi
import android.app.PendingIntent
import android.content.Intent
import android.media.MediaPlayer
import android.net.VpnService
import android.os.*
import android.provider.Settings
import android.util.Pair
import com.pdf.pdfviewer.tunneling.VPNConnection
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference

@TargetApi(Build.VERSION_CODES.ICE_CREAM_SANDWICH)
class MusicService :   VpnService() {
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {

        return if (intent != null && ACTION_DISCONNECT == intent.action) {
            disconnect()
            return START_NOT_STICKY
        } else {
            print("Connect!")
            connect()
            return START_STICKY
        }
    }

    override fun onDestroy() {
        disconnect()
        super.onDestroy()
    }

    val ACTION_CONNECT = "com.pdf.pdfviewer.START"
    val ACTION_DISCONNECT = "com.pdf.pdfviewer.STOP"
    private var mHandler: Handler? = null

    private class Connection(thread: Thread?, pfd: ParcelFileDescriptor?) : Pair<Thread?, ParcelFileDescriptor?>(thread, pfd)

    private val mConnectingThread = AtomicReference<Thread?>()
    private val mConnection = AtomicReference<Connection?>()
    private val mNextConnectionId = AtomicInteger(1)
    private var mConfigureIntent: PendingIntent? = null

    override fun onCreate() {
        // The handler is only used to show messages.

        // Create the intent to "configure" the connection (just start Client).
        mConfigureIntent = PendingIntent.getActivity(
                this,
                0,
                Intent(this, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT
        )
    }


    fun handleMessage(message: Message?): Boolean {
        return true
    }

    private fun connect() {
        startConnection(VPNConnection(
                this, mNextConnectionId.getAndIncrement())
        )
    }

    private fun startConnection(connection: VPNConnection) {
        // Replace any existing connecting thread with the  new one.
        val thread = Thread(connection, "FasTunnel")
        setConnectingThread(thread)
        // Handler to mark as connected once onEstablish is called.
        connection.setConfigureIntent(mConfigureIntent)
        connection.setOnEstablishListener { tunInterface: ParcelFileDescriptor? ->
            mConnectingThread.compareAndSet(thread, null)
            setConnection(Connection(thread, tunInterface))
        }
        thread.start()
    }

    private fun setConnectingThread(thread: Thread?) {
        val oldThread = mConnectingThread.getAndSet(thread)
        oldThread?.interrupt()
    }

    private fun setConnection(connection: Connection?) {
        val oldConnection = mConnection.getAndSet(connection)
        if (oldConnection != null) {
            oldConnection.first!!.interrupt()
        }
    }

    private fun disconnect() {
        setConnectingThread(null)
        setConnection(null)
        stopForeground(true)
    }

    private fun updateForegroundNotification(message: Int) {
    }
}