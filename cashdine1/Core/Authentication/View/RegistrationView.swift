//
//  RegistrationView.swift
//  cashdine1
//
//  Created by Vasyl Maryna on 27.04.2024.
//

import SwiftUI

struct RegistrationView: View {
    @State private var email = ""
    @State private var fullname = ""
    @State private var password = ""
    @State private var confirmpassword = ""
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    var body: some View {
        VStack{
            //Image
            Image ("CashDine")
                .resizable()
                .scaledToFit()
                .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
                .clipShape(Circle())
                .padding(.vertical, 32)
            
            //Form fields
            VStack(spacing: 24){
                InputView(text: $email,
                          title: "Email Adress",
                          placeholder: "name@example.com")
                .autocapitalization(.none)
                
                InputView(text: $fullname,
                          title: "Full Name",
                          placeholder: "Enter your name")
                
                InputView(text: $password,
                          title: "Password",
                          placeholder: "Enter your password",
                          isSecureField: true)
                
                ZStack(alignment: .trailing){
                    InputView(text: $confirmpassword,
                              title: "Confirm Password",
                              placeholder: "Confirm your password",
                              isSecureField: true)
                    
                    if !password.isEmpty && !confirmpassword.isEmpty{
                        if password == confirmpassword{
                            Image(systemName: "checkmark.circle.fill")
                                .imageScale(.large)
                                .fontWeight(.bold)
                                .foregroundColor(Color(.systemGreen))
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .imageScale(.large)
                                .fontWeight(.bold)
                                .foregroundColor(Color(.systemRed))
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            Button {
                Task{
                    try await viewModel.createUser(withEamil: email, password: password, fullname: fullname)
                }
            } label: {
                HStack {
                    Text ("SIGN UP")
                        .fontWeight(.semibold)
                    Image (systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(width: UIScreen.main.bounds.width - 32, height: 48)
            }
                .background (Color (.systemBlue))
                .disabled(!formIsValid)
                .opacity(formIsValid ? 1.0 : 0.5)
                .cornerRadius(10)
                .padding(.top, 24)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                HStack(spacing: 3) {
                    Text("Already have a accunt")
                    Text("Sign in")
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                }
                .font(.system(size: 14))
            }

            
        }
    }
}
 
//MARK: AuthenticationFormProtocol

extension RegistrationView: AuthenticationFormProtocol{
    var formIsValid: Bool {
        return !email.isEmpty
        && email.contains("@")
        && email.count > 10
        && !password.isEmpty
        && password.count > 5
        && confirmpassword == password
        && !fullname.isEmpty
        && fullname.count > 2
    }
}
        
#Preview {
    RegistrationView()
}
