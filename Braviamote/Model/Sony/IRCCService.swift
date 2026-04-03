import Foundation

class IRCCService {

    private var dynamicCodes: [String: String] = [:]
    private var codesLoaded = false

    // MARK: - Load codes from TV

    func loadCodes(using api: BraviaAPIService, completion: (() -> Void)? = nil) {
        api.getRemoteControllerInfo { [weak self] commands in
            guard !commands.isEmpty else {
                print("[IRCC] Failed to fetch remote codes, using fallback")
                completion?()
                return
            }
            var codes: [String: String] = [:]
            for cmd in commands {
                codes[cmd.name] = cmd.value
            }
            self?.dynamicCodes = codes
            self?.codesLoaded = true
            print("[IRCC] Loaded \(codes.count) codes from TV")
            completion?()
        }
    }

    // MARK: - Send command

    func sendCommand(name: String, completion: ((Bool) -> Void)? = nil) {
        let code: String?
        if codesLoaded {
            code = dynamicCodes[name] ?? Self.fallbackCodes[name]
        } else {
            code = Self.fallbackCodes[name]
        }

        guard let irccCode = code else {
            print("[IRCC] Unknown command: \(name)")
            completion?(false)
            return
        }

        sendIRCC(code: irccCode, completion: completion)
    }

    private func sendIRCC(code: String, completion: ((Bool) -> Void)? = nil) {
        let stored = UserDefaults.standard.string(forKey: "ipAddress") ?? ""
        guard !stored.isEmpty, let url = URL(string: "http://\(stored)/sony/IRCC") else {
            completion?(false)
            return
        }

        let body = """
        <?xml version="1.0"?>\
        <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" \
        s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">\
        <s:Body>\
        <u:X_SendIRCC xmlns:u="urn:schemas-sony-com:service:IRCC:1">\
        <IRCCCode>\(code)</IRCCCode>\
        </u:X_SendIRCC>\
        </s:Body>\
        </s:Envelope>
        """

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body.data(using: .utf8)
        request.setValue("text/xml; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue(PSKManager.psk, forHTTPHeaderField: "X-Auth-PSK")
        request.setValue("\"urn:schemas-sony-com:service:IRCC:1#X_SendIRCC\"", forHTTPHeaderField: "SOAPACTION")
        request.timeoutInterval = 5

        URLSession.shared.dataTask(with: request) { _, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[IRCC] sendCommand error: \(error.localizedDescription)")
                    completion?(false)
                } else {
                    completion?(true)
                }
            }
        }.resume()
    }

    // MARK: - Fallback codes

    static let fallbackCodes: [String: String] = [
        "hdmi1": "AAAAAgAAABoAAABaAw==",
        "hdmi2": "AAAAAgAAABoAAABbAw==",
        "hdmi3": "AAAAAgAAABoAAABcAw==",
        "hdmi4": "AAAAAgAAABoAAABdAw==",
        "PowerOff": "AAAAAQAAAAEAAAAvAw==",
        "Input": "AAAAAQAAAAEAAAAlAw==",
        "GGuide": "AAAAAQAAAAEAAAAOAw==",
        "EPG": "AAAAAgAAAKQAAABbAw==",
        "Favorites": "AAAAAgAAAHcAAAB2Aw==",
        "Display": "AAAAAQAAAAEAAAA6Aw==",
        "Home": "AAAAAQAAAAEAAABgAw==",
        "Options": "AAAAAgAAAJcAAAA2Aw==",
        "Return": "AAAAAgAAAJcAAAAjAw==",
        "Up": "AAAAAQAAAAEAAAB0Aw==",
        "Down": "AAAAAQAAAAEAAAB1Aw==",
        "Right": "AAAAAQAAAAEAAAAzAw==",
        "Left": "AAAAAQAAAAEAAAA0Aw==",
        "Confirm": "AAAAAQAAAAEAAABlAw==",
        "Red": "AAAAAgAAAJcAAAAlAw==",
        "Green": "AAAAAgAAAJcAAAAmAw==",
        "Yellow": "AAAAAgAAAJcAAAAnAw==",
        "Blue": "AAAAAgAAAJcAAAAkAw==",
        "Num1": "AAAAAQAAAAEAAAAAAw==",
        "Num2": "AAAAAQAAAAEAAAABAw==",
        "Num3": "AAAAAQAAAAEAAAACAw==",
        "Num4": "AAAAAQAAAAEAAAADAw==",
        "Num5": "AAAAAQAAAAEAAAAEAw==",
        "Num6": "AAAAAQAAAAEAAAAFAw==",
        "Num7": "AAAAAQAAAAEAAAAGAw==",
        "Num8": "AAAAAQAAAAEAAAAHAw==",
        "Num9": "AAAAAQAAAAEAAAAIAw==",
        "Num0": "AAAAAQAAAAEAAAAJAw==",
        "Num11": "AAAAAQAAAAEAAAAKAw==",
        "Num12": "AAAAAQAAAAEAAAALAw==",
        "VolumeUp": "AAAAAQAAAAEAAAASAw==",
        "VolumeDown": "AAAAAQAAAAEAAAATAw==",
        "Mute": "AAAAAQAAAAEAAAAUAw==",
        "ChannelUp": "AAAAAQAAAAEAAAAQAw==",
        "ChannelDown": "AAAAAQAAAAEAAAARAw==",
        "SubTitle": "AAAAAgAAAJcAAAAoAw==",
        "ClosedCaption": "AAAAAgAAAKQAAAAQAw==",
        "Enter": "AAAAAQAAAAEAAAALAw==",
        "DOT": "AAAAAgAAAJcAAAAdAw==",
        "Analog": "AAAAAgAAAHcAAAANAw==",
        "Teletext": "AAAAAQAAAAEAAAA/Aw=",
        "Exit": "AAAAAQAAAAEAAABjAw==",
        "Analog2": "AAAAAQAAAAEAAAA4Aw==",
        "Digital": "AAAAAgAAAJcAAAAyAw==",
        "BS": "AAAAAgAAAJcAAAAsAw==",
        "CS": "AAAAAgAAAJcAAAArAw==",
        "BSCS": "AAAAAgAAAJcAAAAQAw==",
        "Ddata": "AAAAAgAAAJcAAAAVAw==",
        "PicOff": "AAAAAQAAAAEAAAA+Aw=",
        "Tv_Radio": "AAAAAgAAABoAAABXAw==",
        "Theater": "AAAAAgAAAHcAAABgAw==",
        "SEN": "AAAAAgAAABoAAAB9Aw==",
        "InternetWidgets": "AAAAAgAAABoAAAB6Aw==",
        "InternetVideo": "AAAAAgAAABoAAAB5Aw==",
        "Netflix": "AAAAAgAAABoAAAB8Aw==",
        "Youtube": "AAAAAgAAAMQAAABHAw==",
        "SceneSelect": "AAAAAgAAABoAAAB4Aw==",
        "Mode3D": "AAAAAgAAAHcAAABNAw==",
        "iManual": "AAAAAgAAABoAAAB7Aw==",
        "Audio": "AAAAAQAAAAEAAAAXAw==",
        "Wide": "AAAAAgAAAKQAAAA9Aw==",
        "Jump": "AAAAAQAAAAEAAAA7Aw==",
        "PAP": "AAAAAgAAAKQAAAB3Aw==",
        "MyEPG": "AAAAAgAAAHcAAABrAw==",
        "ProgramDescription": "AAAAAgAAAJcAAAAWAw==",
        "WriteChapter": "AAAAAgAAAHcAAABsAw==",
        "TrackID": "AAAAAgAAABoAAAB+Aw=",
        "TenKey": "AAAAAgAAAJcAAAAMAw==",
        "AppliCast": "AAAAAgAAABoAAABvAw==",
        "acTVila": "AAAAAgAAABoAAAByAw==",
        "DeleteVideo": "AAAAAgAAAHcAAAAfAw==",
        "PhotoFrame": "AAAAAgAAABoAAABVAw==",
        "TvPause": "AAAAAgAAABoAAABnAw==",
        "KeyPad": "AAAAAgAAABoAAAB1Aw==",
        "Media": "AAAAAgAAAJcAAAA4Aw==",
        "SyncMenu": "AAAAAgAAABoAAABYAw==",
        "Forward": "AAAAAgAAAJcAAAAcAw==",
        "Play": "AAAAAgAAAJcAAAAaAw==",
        "Rewind": "AAAAAgAAAJcAAAAbAw==",
        "Prev": "AAAAAgAAAJcAAAA8Aw==",
        "Stop": "AAAAAgAAAJcAAAAYAw==",
        "Next": "AAAAAgAAAJcAAAA9Aw==",
        "Rec": "AAAAAgAAAJcAAAAgAw==",
        "Pause": "AAAAAgAAAJcAAAAZAw==",
        "Eject": "AAAAAgAAAJcAAABIAw==",
        "FlashPlus": "AAAAAgAAAJcAAAB4Aw==",
        "FlashMinus": "AAAAAgAAAJcAAAB5Aw==",
        "TopMenu": "AAAAAgAAABoAAABgAw==",
        "PopUpMenu": "AAAAAgAAABoAAABhAw==",
        "RakurakuStart": "AAAAAgAAAHcAAABqAw==",
        "OneTouchTimeRec": "AAAAAgAAABoAAABkAw==",
        "OneTouchView": "AAAAAgAAABoAAABlAw==",
        "OneTouchRec": "AAAAAgAAABoAAABiAw==",
        "OneTouchStop": "AAAAAgAAABoAAABjAw="
    ]
}
