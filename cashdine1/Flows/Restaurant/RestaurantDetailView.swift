//
//  RestaurantDetailView.swift
//  cashdine1
//
//  Created by Vasyl Maryna on 10.05.2024.
//

import SwiftUI

struct RestaurantDetailView: View {
    let restaurant: Restaurant

    var body: some View {
        VStack {
            Text("Restaurant Detail")
            Text("Name: \(restaurant.name)")
            Text("Address: \(restaurant.address)")
            // Add more details as needed
        }
        .padding()
        .navigationTitle("Restaurant Detail")
    }
}

