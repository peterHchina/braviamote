import Foundation

struct RemoteControllerInfoResponse: Decodable {
    let id: Int
    let result: [RemoteControllerResult]

    var commands: [RemoteCommand] {
        guard result.count > 1, case .commands(let cmds) = result[1] else {
            return []
        }
        return cmds
    }
}

enum RemoteControllerResult: Decodable {
    case info(RemoteControllerBundleInfo)
    case commands([RemoteCommand])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let commands = try? container.decode([RemoteCommand].self) {
            self = .commands(commands)
        } else if let info = try? container.decode(RemoteControllerBundleInfo.self) {
            self = .info(info)
        } else {
            throw DecodingError.typeMismatch(
                RemoteControllerResult.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unexpected result element")
            )
        }
    }
}

struct RemoteControllerBundleInfo: Decodable {
    let bundled: Bool?
    let type: String?
}

struct RemoteCommand: Decodable {
    let name: String
    let value: String
}
