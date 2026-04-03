import Foundation

enum VolumeDirection {
    case up
    case down

    var value: String {
        switch self {
        case .up: return "+1"
        case .down: return "-1"
        }
    }
}

class BraviaAPIService {

    private let ip: String?
    
    init(ip: String? = nil) {
        self.ip = ip
    }

    private var resolvedIP: String? {
        if let ip = ip, !ip.isEmpty { return ip }
        let stored = UserDefaults.standard.string(forKey: "ipAddress") ?? ""
        return stored.isEmpty ? nil : stored
    }

    // MARK: - Core JSON-RPC

    private func performJSONRPC(
        service: String,
        method: String,
        params: [[String: Any]] = [],
        version: String = "1.0",
        id: Int = 1,
        completion: @escaping (Data?) -> Void
    ) {
        guard let ip = resolvedIP, let url = URL(string: "http://\(ip)/sony/\(service)") else {
            DispatchQueue.main.async { completion(nil) }
            return
        }

        let json: [String: Any] = [
            "method": method,
            "id": id,
            "params": params,
            "version": version
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: json) else {
            DispatchQueue.main.async { completion(nil) }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(PSKManager.psk, forHTTPHeaderField: "X-Auth-PSK")
        request.timeoutInterval = 5

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("[BraviaAPI] \(method) error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            DispatchQueue.main.async { completion(data) }
        }.resume()
    }

    // MARK: - System

    func getPowerStatus(completion: @escaping (PowerStatusResponse?) -> Void) {
        performJSONRPC(service: "system", method: "getPowerStatus", id: 50) { data in
            guard let data = data else { completion(nil); return }
            completion(try? JSONDecoder().decode(PowerStatusResponse.self, from: data))
        }
    }

    func setPowerStatus(on: Bool, completion: @escaping (Bool) -> Void) {
        let params: [[String: Any]] = [["status": on]]
        performJSONRPC(service: "system", method: "setPowerStatus", params: params, id: 55) { data in
            completion(data != nil)
        }
    }

    func getRemoteControllerInfo(completion: @escaping ([RemoteCommand]) -> Void) {
        performJSONRPC(service: "system", method: "getRemoteControllerInfo", id: 54) { data in
            guard let data = data,
                  let response = try? JSONDecoder().decode(RemoteControllerInfoResponse.self, from: data) else {
                completion([])
                return
            }
            completion(response.commands)
        }
    }

    func getInterfaceInformation(completion: @escaping (SystemResponse?) -> Void) {
        performJSONRPC(service: "system", method: "getInterfaceInformation", id: 33) { data in
            guard let data = data else { completion(nil); return }
            completion(try? JSONDecoder().decode(SystemResponse.self, from: data))
        }
    }

    // MARK: - Audio

    func getVolumeInformation(completion: @escaping (VolumeResponse?) -> Void) {
        performJSONRPC(service: "audio", method: "getVolumeInformation", id: 33) { data in
            guard let data = data else { completion(nil); return }
            completion(try? JSONDecoder().decode(VolumeResponse.self, from: data))
        }
    }

    func setAudioVolume(direction: VolumeDirection, completion: @escaping (Bool) -> Void) {
        let params: [[String: Any]] = [["volume": direction.value, "target": "speaker", "ui": "on"]]
        performJSONRPC(service: "audio", method: "setAudioVolume", params: params, version: "1.2", id: 601) { data in
            completion(data != nil)
        }
    }

    func setAudioMute(muted: Bool, completion: @escaping (Bool) -> Void) {
        let params: [[String: Any]] = [["status": muted]]
        performJSONRPC(service: "audio", method: "setAudioMute", params: params, id: 602) { data in
            completion(data != nil)
        }
    }
}
