//
//  VolumeResponse.swift
//  Braviamote
//
//  Created by Marvin Wagner on 18/06/20.
//  Copyright © 2020 Marvin Wagner. All rights reserved.
//

import Foundation

struct VolumeResponse: Decodable {
    let id: Int
    let result: [[VolumeInfoResponse]]

    var speaker: VolumeInfoResponse? {
        result.first?.first { $0.target == "speaker" }
    }
}

struct VolumeInfoResponse: Decodable {
    let volume: Int
    let minVolume: Int
    let mute: Bool
    let maxVolume: Int
    let target: String // speaker
}
