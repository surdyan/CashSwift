//
//  ProfileView.swift
//  cashdine1
//
//  Created by Vasyl Maryna on 27.04.2024.
//

import SwiftUI

struct ProfileSettingRowView: View {
    var imageName: String
    var title: String
    var tintColor: Color

    var body: some View {
        HStack {
            Image(systemName: imageName)
                .foregroundColor(tintColor)
                .frame(width: 24, height: 24)
            Text(title)
                .foregroundColor(.primary)
                .font(.subheadline)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ProfileView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Binding var selectedTab: Tab
    @Binding var isCreateRestaurantViewActive: Bool

    var body: some View {
        if let user = viewModel.currentUser {
            List {
                Section {
                    HStack {
                        Text(user.initials)
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 72, height: 72)
                            .background(Color(.systemGray3))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.fullname)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.top, 4)
                                .foregroundColor(.primary)
                            Text(user.email)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("General").foregroundColor(.primary)) {
                    HStack {
                        ProfileSettingRowView(imageName: "gear", title: "Version", tintColor: Color(.systemGray))
                        
                        Spacer()
                        
                        Text("1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Account").foregroundColor(.primary)) {
                    Button {
                        viewModel.singOut()
                    } label: {
                        ProfileSettingRowView(imageName: "arrow.left.circle.fill", title: "Sign Out", tintColor: .red)
                    }

                    Button {
                        viewModel.deleteAccount()
                    } label: {
                        ProfileSettingRowView(imageName: "xmark.circle.fill", title: "Delete Account", tintColor: .red)
                    }
                    
                    Toggle("Create Restaurant", isOn: $isCreateRestaurantViewActive)
                        .foregroundColor(.primary)
                }
            }
        }
    }
}
