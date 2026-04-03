import Foundation

struct PSKManager {
    static let defaultPSK = "0000"
    private static let userDefaultsKey = "psk"

    static var psk: String {
        get {
            let value = UserDefaults.standard.string(forKey: userDefaultsKey) ?? ""
            return value.isEmpty ? defaultPSK : value
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userDefaultsKey)
        }
    }
}
