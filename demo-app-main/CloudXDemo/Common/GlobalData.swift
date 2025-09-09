//
//  GlobalData.swift
//  CloudXDemo
//
//  Created by Xenoss on 24.04.2025.
//

import Foundation

public final class GlobalData {
    
    var userEmailHashed: String?
    var userEmail: String?
    var userIdRegisteredAtMS: Int
    var hashAlgo: String
    
    init() {
        self.userEmailHashed = ""
        self.userEmail = ""
        self.userIdRegisteredAtMS = 0
        self.hashAlgo = ""
    }
    
    func provideData(userEmailHashed: String?, userEmail: String?, userIdRegisteredAtMS: Int, hashAlgo: String) {
        self.userEmailHashed = userEmailHashed
        self.userEmail = userEmail
        self.userIdRegisteredAtMS = userIdRegisteredAtMS
        self.hashAlgo = hashAlgo
    }
}
