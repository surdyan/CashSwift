//
//  User.swift
//  cashdine1
//
//  Created by Vasyl Maryna on 27.04.2024.
//

import Foundation

struct User: Identifiable, Codable {
    let id: String
    let fullname: String
    let email: String
 
    var initials: String{
        let formatter = PersonNameComponentsFormatter()
        if let componets = formatter.personNameComponents(from: fullname){
            formatter.style = .abbreviated
            return formatter.string(from: componets)
        }
        return ""
    }
    
//    enum CodingKeys: String, CodingKey {
//        case id = "idZzz"
//        case fullname = "nume"
//        case email = "unEmail"
//    }
}

extension User{
    static var MOCK_USER = User(id: NSUUID().uuidString, fullname: "Koby Bryant", email: "test@gmail.com")
    
}
