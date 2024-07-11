//
//  RestaurantManager.swift
//  cashdine1
//
//  Created by Vasyl Maryna on 10.05.2024.
//

import SwiftUI

class RestaurantManager: ObservableObject {
    @Published var restaurants: [Restaurant] = []
    
    func addRestaurant(name: String, latitude: Double, longitude: Double) {
        let newRestaurant = Restaurant(name: name, latitude: latitude, longitude: longitude)
        restaurants.append(newRestaurant)
    }
}

struct Restaurant {
    var name: String
    var latitude: Double
    var longitude: Double
}
