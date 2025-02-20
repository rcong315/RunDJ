//
//  Keychain.swift
//  RunDJ
//
//  Created by Richard Cong on 2/16/25.
//

import Security

func saveToKeychain(key: String, value: String) {
    let data = value.data(using: .utf8)!
    
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecValueData as String: data
    ]
    
    SecItemDelete(query as CFDictionary) // Ensure no duplicates
    SecItemAdd(query as CFDictionary, nil)
}
