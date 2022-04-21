package com.pdf.pdfviewer.tunneling;

import java.io.IOException;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

import android.app.PendingIntent;
import android.content.Intent;
import android.net.VpnService;
import android.os.Handler;
import android.os.Message;
import android.os.ParcelFileDescriptor;
import android.util.Pair;


public class Service extends VpnService implements Handler.Callback {

    public static final String ACTION_CONNECT = "com.pdf.pdfviewer.START";
    public static final String ACTION_DISCONNECT = "com.pdf.pdfviewer.STOP";
    private Handler mHandler;

    private static class Connection extends Pair<Thread, ParcelFileDescriptor> {
        public Connection(Thread thread, ParcelFileDescriptor pfd) {
            super(thread, pfd);
        }
    }
    private final AtomicReference<Thread> mConnectingThread = new AtomicReference<>();
    private final AtomicReference<Connection> mConnection = new AtomicReference<>();
    private AtomicInteger mNextConnectionId = new AtomicInteger(1);
    private PendingIntent mConfigureIntent;

    @Override
    public void onCreate() {
        // The handler is only used to show messages.
        if (mHandler == null) {
            mHandler = new Handler(this);
        }

        // Create the intent to "configure" the connection (just start Client).
        mConfigureIntent = PendingIntent.getActivity(
            this,
            0,
            new Intent(this, com.pdf.pdfviewer.MainActivity.class),
            PendingIntent.FLAG_UPDATE_CURRENT
        );
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && ACTION_DISCONNECT.equals(intent.getAction())) {
            disconnect();
            return START_NOT_STICKY;

        } else {
            connect();
            return START_STICKY;
        }
    }

    @Override
    public void onDestroy() {
        disconnect();
    }

    @Override
    public boolean handleMessage(Message message) {
        return true;
    }

    private void connect() {
        startConnection(new VPNConnection(
            this, mNextConnectionId.getAndIncrement())
        );
    }

    private void startConnection(final VPNConnection connection) {
        // Replace any existing connecting thread with the  new one.
        final Thread thread = new Thread(connection, "FasTunnel");

        setConnectingThread(thread);
        // Handler to mark as connected once onEstablish is called.
        connection.setConfigureIntent(mConfigureIntent);
        connection.setOnEstablishListener(tunInterface -> {
            mConnectingThread.compareAndSet(thread, null);
            setConnection(new Connection(thread, tunInterface));
        });

        thread.start();
    }

    private void setConnectingThread(final Thread thread) {
        final Thread oldThread = mConnectingThread.getAndSet(thread);

        if (oldThread != null) {
            oldThread.interrupt();
        }
    }

    private void setConnection(final Connection connection) {
        final Connection oldConnection = mConnection.getAndSet(connection);

        if (oldConnection != null) {
            oldConnection.first.interrupt();
        }
    }

    private void disconnect() {
        setConnectingThread(null);
        setConnection(null);
        stopForeground(true);
    }

    private void updateForegroundNotification(final int message) {
        ;
    }
}