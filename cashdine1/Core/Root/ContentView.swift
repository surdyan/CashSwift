//
//  TransferView.swift
//  cashdine1
//
//  Created by Vasyl Maryna on 26.04.2024.
//

import SwiftUI

enum Tab {
    case profile
    case restaurant
    case camera
    case createRestaurant
    case history
    case transfer
}

struct ContentView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var selectedTab: Tab = .profile
    @State private var scannedCode: String? = nil
    @State private var isCreateRestaurantViewActive = false
    @State private var selectedRestaurantForTransfer: AppRestaurant?

    var body: some View {
        Group {
            if viewModel.userSession != nil {
                TabView(selection: $selectedTab) {
                    RestaurantView(selectRestaurantForTransfer: selectRestaurantForTransfer)
                        .tabItem {
                            Label("Restaurants", systemImage: "fork.knife.circle")
                        }
                        .tag(Tab.restaurant)
                               
                    PurchaseListView()
                        .tabItem {
                            Label("History", systemImage: "list.bullet.circle.fill")
                        }
                        .tag(Tab.history)

                    TransferView(selectedRestaurant: $selectedRestaurantForTransfer)
                        .tabItem {
                            Label("Transfer", systemImage: "arrowshape.up.circle.fill")
                        }
                        .tag(Tab.transfer)

                    if isCreateRestaurantViewActive {
                        CreateRestaurantView()
                            .tabItem {
                                Label("Create", systemImage: "plus.circle.fill")
                            }
                            .tag(Tab.createRestaurant)
                    }

                    ProfileView(selectedTab: $selectedTab, isCreateRestaurantViewActive: $isCreateRestaurantViewActive)
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                        .tag(Tab.profile)
                }
                .onChange(of: selectedTab) { newTab in
                    if newTab == .restaurant {
                        selectedRestaurantForTransfer = nil
                    }
                }
            } else {
                LoginView()
            }
        }
    }

    func selectRestaurantForTransfer(_ restaurant: AppRestaurant) {
        selectedRestaurantForTransfer = restaurant
        selectedTab = .transfer
    }
}
