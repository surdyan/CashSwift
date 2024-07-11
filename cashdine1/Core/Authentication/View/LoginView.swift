//
//  LoginView.swift
//  cashdine1
//
//  Created by Vasyl Maryna on 26.04.2024.
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        NavigationStack{
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
                    
                    InputView(text: $password,
                              title: "Password",
                              placeholder: "Enter your password",
                              isSecureField: true)
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                //SignIn Button
                
                Button {
                    Task{
                        try await viewModel.singIn(withEamil: email, password: password)
                    }
                } label: {
                    HStack {
                        Text ("SIGN IN")
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
                
                //SignUp Button
                
                NavigationLink {
                    RegistrationView()
                        .navigationBarBackButtonHidden(true)
                } label: {
                    HStack(spacing: 3) {
                        Text("Don't have a accunt")
                        Text("Sign up")
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    }
                    .font(.system(size: 14))
                }
            }
            
        }
    }
}

//MARK: AuthenticationFormProtocol

extension LoginView: AuthenticationFormProtocol{
    var formIsValid: Bool {
        return !email.isEmpty
        && email.contains("@")
        && email.count > 10
        && !password.isEmpty
        && password.count > 5
    }
}

struct LoginView_Previews: PreviewProvider{
    static var previews: some View {
        LoginView()
    }
}
