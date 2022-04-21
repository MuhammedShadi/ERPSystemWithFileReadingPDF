package com.pdf.pdfviewer.tunneling;

import android.net.VpnService;

import network.SocketMarkerCallback;


/**
 * Android implementation of SDK's SocketMarkerCallback interface.
 * Used by SDK to protect transport file descriptors from being tunneled.
 */
public class AndroidSocketMarker implements SocketMarkerCallback {
    private VpnService _mService;

    public AndroidSocketMarker(VpnService service){
        this._mService = service;
    }

    @Override
    public void protect(long socket) {
        this._mService.protect((int) socket);
    }
}
