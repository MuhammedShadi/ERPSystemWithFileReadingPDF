
package com.pdf.pdfviewer.tunneling;

import android.app.PendingIntent;
import android.net.VpnService;
import android.content.pm.PackageManager;
import android.os.ParcelFileDescriptor;
import android.util.Log;

import static android.system.OsConstants.AF_INET;


public class VPNConnection implements Runnable {
    private static final String TAG = "FastTunnel[Connection]";

    private final VpnService mService;
    private PendingIntent mConfigureIntent;
    private OnEstablishListener mOnEstablishListener;

    public VPNConnection(final VpnService service, final int connectionId) {
        mService = service;
    }

    public interface OnEstablishListener {
        void onEstablish(ParcelFileDescriptor tunInterface);
    }
    public void setOnEstablishListener(OnEstablishListener listener) {
        mOnEstablishListener = listener;
    }
    public void setConfigureIntent(PendingIntent intent) {
        mConfigureIntent = intent;
    }

    public void run() throws IllegalArgumentException {
        TunnelWrapper tunnel = null;
        ParcelFileDescriptor tunInterface;

        try {        
            if ((tunInterface = configure()) != null) {
                // TUN interface was created successfully.
                // File descriptor must be detached so native code would be able to close it.
                int tunInterfaceFd = tunInterface.detachFd();
                // Start tunnel with obtained file descriptor.
                tunnel = new TunnelWrapper();
                tunnel.start(
                     tunInterfaceFd,
                     new AndroidSocketMarker(mService)
                );
                // Wait until thread is interrupted (requested to stop).
                Thread.sleep(Long.MAX_VALUE);
            } else {
                Log.println(Log.ERROR, TAG, "Failed to create TUN!");
            }
        }

        catch (InterruptedException e){
            // Thread was requested to stop.
            ;
        }

        catch (Exception e){
            // Failed to create TUN interface, bail..
            Log.println(Log.ERROR, TAG, e.toString());
        }

        finally {
            // Clean up.
            if (tunnel != null) {
                try {
                    tunnel.close();
                } catch (Exception e) {
                    Log.println(Log.ERROR, TAG, e.toString());
                }
            }
        }
    }

    private ParcelFileDescriptor configure() throws IllegalArgumentException {
        final ParcelFileDescriptor vpnInterface;
        final VpnService.Builder builder = mService.new Builder();

        // To exempt an application from being tunneled.
        //        try {
        //            builder.addDisallowedApplication("com.pdf.pdfviewer");
        //        }
        //        catch (PackageManager.NameNotFoundException e){
        //            throw new IllegalArgumentException(e);
        //        }

        // Setup TUN interface.
        builder.setSession("FasTunnel").setConfigureIntent(mConfigureIntent);
        // Set interface address.
        builder.addAddress("10.3.3.0", 24);
        // Route all device traffic through VPN.
        builder.allowFamily(AF_INET);
        builder.addRoute("0.0.0.0", 0);
        // DNS must be overridden otherwise default ISP DNS will drop VPN server requests.
        // Google is a safe option.
        builder.addDnsServer("8.8.8.8");
        builder.addDnsServer("8.8.4.4");

        synchronized (mService) {
            vpnInterface = builder.establish();

            if (mOnEstablishListener != null) {
                mOnEstablishListener.onEstablish(vpnInterface);
            }
        }

        return vpnInterface;
    }
}