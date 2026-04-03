//
//  TVControllerManagement.swift
//  Braviamote
//

import Foundation

protocol TVModel {
    func checkDevice(ip: String, perform: @escaping (String)->Void)
}

class TVControllerManagement: ObservableObject {

    @Published var loading: Bool = false

    @Published var isMuted = false
    @Published var currentVolume: Int = 0
    @Published var volumeDescription: String = ""

    @Published var isTurnedOn = false
    @Published var powerStatus: String = ""

    @Published var isConnected = false

    let api = BraviaAPIService()
    let ircc = IRCCService()

    private var savedIP: String? {
        let ip = UserDefaults.standard.string(forKey: "ipAddress") ?? ""
        return ip.isEmpty ? nil : ip
    }

    func validateIp() -> Bool {
        return savedIP != nil
    }

    // MARK: - Setup

    func setup() {
        guard savedIP != nil else { return }
        ircc.loadCodes(using: api)
        checkPowerStatus()
        checkVolumeInfo()
    }

    // MARK: - Power

    func togglePower() {
        loading = true
        if isTurnedOn {
            api.setPowerStatus(on: false) { [weak self] success in
                if success {
                    Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                        self?.checkPowerStatus()
                    }
                } else {
                    self?.loading = false
                }
            }
        } else {
            sendWoL()
            api.setPowerStatus(on: true) { [weak self] _ in
                Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                    self?.checkPowerStatus()
                }
            }
        }
    }

    private func sendWoL() {
        let mac = UserDefaults.standard.string(forKey: "macAddress") ?? ""
        guard !mac.isEmpty else { return }
        let device = Awake.Device(MAC: mac, BroadcastAddr: "255.255.255.255", Port: 9)
        if let error = Awake.target(device: device) {
            print("[WoL] \(error.localizedDescription)")
        }
    }

    // MARK: - Volume

    func volumeUp() {
        api.setAudioVolume(direction: .up) { [weak self] success in
            if success {
                self?.checkVolumeInfo()
            }
            self?.isConnected = success
        }
    }

    func volumeDown() {
        api.setAudioVolume(direction: .down) { [weak self] success in
            if success {
                self?.checkVolumeInfo()
            }
            self?.isConnected = success
        }
    }

    func toggleMute() {
        let newMuted = !isMuted
        api.setAudioMute(muted: newMuted) { [weak self] success in
            if success {
                self?.checkVolumeInfo()
            }
            self?.isConnected = success
        }
    }

    // MARK: - IRCC Commands

    func sendIRCCCommand(name: String) {
        loading = true
        ircc.sendCommand(name: name) { [weak self] success in
            self?.loading = false
            self?.isConnected = success
        }
    }

    // MARK: - Status Queries

    func checkVolumeInfo() {
        guard savedIP != nil else { return }

        api.getVolumeInformation { [weak self] response in
            guard let response = response else { return }
            if let speaker = response.speaker {
                self?.isMuted = speaker.mute
                self?.currentVolume = speaker.volume
                self?.volumeDescription = "Vol: \(speaker.volume). \(speaker.mute ? "*Muted*" : "")"
            }
            self?.isConnected = true
        }
    }

    func checkPowerStatus() {
        guard savedIP != nil else { return }

        loading = true
        api.getPowerStatus { [weak self] response in
            self?.loading = false
            guard let response = response else { return }
            self?.isTurnedOn = response.status == .active
            self?.powerStatus = response.statusDesc
            self?.isConnected = true
        }
    }
}
