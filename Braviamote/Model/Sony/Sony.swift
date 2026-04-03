//
//  Sony.swift
//  Braviamote
//

import Foundation

struct Sony: TVModel {

    func checkDevice(ip: String, perform: @escaping (String) -> Void) {
        let api = BraviaAPIService(ip: ip)
        api.getInterfaceInformation { response in
            if let response = response {
                perform(response.modelName)
            }
        }
    }
}
