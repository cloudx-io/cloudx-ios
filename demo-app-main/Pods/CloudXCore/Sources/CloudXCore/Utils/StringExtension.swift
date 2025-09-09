//
//  StringExtension.swift
//  CloudXCore
//
//  Created by Xenoss on 22.05.2025.
//

extension String {
    func semicolon() -> String {
        return "\(self);"
    }
    
    func encoded() -> String {
        return self.data(using: .utf8)?.base64EncodedString() ?? "encodedFailed"
    }
}

