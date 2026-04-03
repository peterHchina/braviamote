//
//  NetworkManagement.swift
//  Braviamote
//
//  Created by Marvin Wagner on 25/06/20.
//  Copyright © 2020 Marvin Wagner. All rights reserved.
//

import SwiftUI

class NetworkPresenter: NSObject, MMLANScannerDelegate, ObservableObject {
    @Published var connectedDevices: [Device] = []
    
    @Published var progressValue: Float = 0.0

    @Published var isScanRunning: Bool = false
    
    var lanScanner: MMLANScanner!
    
    var sony = Sony()
    
    override init() {
        super.init()
        self.lanScanner = MMLANScanner(delegate: self)
    }
    
    //MARK: - Button Actions
    //This method is responsible for handling the tap button action on RemoteView. In case the scan is running and the button is tapped it will stop the scan
    func scanButtonClicked() {
        if (self.isScanRunning) {
            self.stopNetWorkScan()
        } else {
            self.startNetWorkScan()
        }
    }

    func startNetWorkScan() {
        if self.isScanRunning {
            self.stopNetWorkScan()
        }
        self.connectedDevices.removeAll()
        self.isScanRunning = true
        self.lanScanner.start()
    }

    func stopNetWorkScan() {
        self.lanScanner.stop()
        self.isScanRunning = false
    }
    
    // MARK: - SSID Info
    //Getting the SSID string using LANProperties
    func ssidName() -> String {
        return LANProperties.fetchSSIDInfo()
    }
    
    // MARK: - MMLANScanner Delegates
    //The delegate methods of MMLANScanner
    func lanScanDidFindNewDevice(_ foundDevice: MMDevice!) {
        //Adding the found device in the array
        sony.checkDevice(ip: foundDevice.ipAddress) { (name) in
             let device = Device(tvName: name, macAddress: foundDevice.macAddress ?? "mac unavailable", ipAddress: foundDevice.ipAddress!)
            
            if(!self.connectedDevices.contains(device)) {
                self.connectedDevices.append(device)
            }
        }
    }
    
    func lanScanDidFailedToScan() {
        self.isScanRunning = false
    }
    
    func lanScanDidFinishScanning(with status: MMLanScannerStatus) {
        self.isScanRunning = false
    }
    
    func lanScanProgressPinged(_ pingedHosts: Float, from overallHosts: Int) {
        //Updating the progress value. MainVC will be notified by KVO
        self.progressValue = pingedHosts / Float(overallHosts)
    }
}
