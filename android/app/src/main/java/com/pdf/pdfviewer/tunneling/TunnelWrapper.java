package com.pdf.pdfviewer.tunneling;

import fastunnel.Fastunnel;
import fastunnel.Tunnel;

import android.util.Log;

/**
 * Go tunneling SDK wrapper.
 *
 */
public class TunnelWrapper {
    // - Reconnection and fail-over.
    // SDK will attempt to reconnect automatically and recover from errors.
    // As such, there is no need to attempt reconnection at the app level.

    private static final String TAG = "FastTunnel[Wrapper]";

    private final String _serverName;
    private final String _serverIP;
    private final String _serverFingerprint;
    private final String _serverDomainFront;
    private final String _transportType;
    private final String _transportPath;
    private final String _machineId;
    private final String _clientUsername;

    private Tunnel _tunnel;

    /**
     * This method is used to initialize the tunnel.
     *
     * @param serverIP Tunnel IP address.
     * @param serverName Server name to validate TLS certificate against.
     * @param serverFingerprint TLS certificate SHA256 hash.
     * @param serverDomainFront Server domain front to hide traffic behind.
     * @param transportType Transport type ("websocket", "http").
     * @param transportPath Path server is listening on.
     * @param machineId Unique device identifier.
     * @param clientUsername Client username.
     * Make sure to detach the file descriptor first using detachFd().
     */
    TunnelWrapper(
        String serverIP,
        String serverName,
        String serverFingerprint,
        String serverDomainFront,
        String transportType,
        String transportPath,
        String machineId,
        String clientUsername
    ) {
        this._serverIP = serverIP;
        this._serverName = serverName;
        this._serverFingerprint = serverFingerprint;
        this._serverDomainFront = serverDomainFront;

        this._transportType = transportType;
        this._transportPath = transportPath;

        this._machineId = machineId;
        this._clientUsername = clientUsername;
    }

    TunnelWrapper(){
        this._serverIP = "3.65.138.10";
        this._serverName = "ingress.obliviate.io";
        this._serverDomainFront = "ingress.obliviate.io";
        this._serverFingerprint = "77:70:6C:9C:47:1B:B9:69:79:46:5F:A9:7E:EF:CD:21:21:6D:55:0B:9A:53:4C:39:4A:8A:EA:2D:CB:18:FD:9E";
        this._transportType = "http";
        this._transportPath = "/LLvidueoZCLeoUoVvnQISPnAtYTezlYf";

        // Id should be unique to this machine and identical on each run.
        // few suggestions available at: stackoverflow.com/questions/2785485/is-there-a-unique-android-device-id
        this._machineId = "MACHINE_ID";
        // Username given to authorized clients, can be revoked by server to deny access.
        this._clientUsername = "MY_SECRET";
    }

    /**
     * This method is used to start the tunnel.
     *
     * @param TUN TUN interface file descriptor.
     * @param soMarker SocketMarker implementation.
     * Make sure to detach the file descriptor first using detachFd().
     */
    void start(
        long TUN,
        AndroidSocketMarker soMarker
    ) throws Exception{
        Log.println(Log.WARN, TAG, "Starting tunnel..");

        this._tunnel =  Fastunnel.new_(
            this._serverName,
            this._serverIP,
            this._serverFingerprint,
            this._serverDomainFront,
            this._clientUsername,
            this._transportPath,
            this._machineId,
            this._transportType,

            TUN,
            soMarker
        );
        this._tunnel.start();
    }

    /**
    * Check if transport is connected.
    * Can be polled periodically to display tunnel status.
    */
    boolean isConnected(){
        return this._tunnel.isConnected();
    }

    /**
    * Check if transport is closed.
    * Returns true only if close() was called.
    * Use isConnected() to check if tunnel is operational.
    */
    boolean isClosed(){
        return this._tunnel.isClosed();
    }

    /**
    * Close TUN interface and release all resources used by transport.
    */
    void close() {
        if (this._tunnel != null) {
            this._tunnel.close();
        }
    }
}