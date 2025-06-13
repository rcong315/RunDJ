//
//  RegistrationResponse.swift
//  RunDJ
//
//  Created on 6/7/25.
//

import Foundation

struct RegistrationResponse: Decodable {
    let status: String
    let message: String
    let isNewUser: Bool?
    
    enum CodingKeys: String, CodingKey {
        case status
        case message
        case isNewUser = "is_new_user"
    }
}

struct ProcessingStatusResponse: Decodable {
    let status: String
    let progress: String?
    let message: String
}
