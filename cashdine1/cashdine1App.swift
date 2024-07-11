//
//  cashdine1App.swift
//  cashdine1
//
//  Created by Vasyl Maryna on 26.04.2024.
//

import SwiftUI
import Firebase

@main
struct cashdine1App: App {
    @StateObject var viewModel = AuthViewModel()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
