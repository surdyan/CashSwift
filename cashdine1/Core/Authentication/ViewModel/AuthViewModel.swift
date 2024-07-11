//
//  AuthViewModel.swift
//  cashdine1
//
//  Created by Vasyl Maryna on 27.04.2024.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

protocol AuthenticationFormProtocol{
    var formIsValid: Bool { get }
}

@MainActor
class AuthViewModel: ObservableObject{
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    
    init(){
        self.userSession = Auth.auth().currentUser
        
        Task {
            await fetchUser()
        }
    }
    
    func singIn(withEamil email: String, password: String) async throws{
        do{
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            await fetchUser()
        } catch {
            print("DEBUG: Failed to log in with error \(error.localizedDescription)")
        }
    }
    
    func createUser(withEamil email: String, password: String, fullname: String) async throws{
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            let user = User(id: result.user.uid, fullname: fullname, email: email)
            let encodedUser = try Firestore.Encoder().encode(user)
            try await Firestore.firestore().collection("users").document(user.id).setData(encodedUser)
            await fetchUser()
        }catch{
            print("DEBUG: Failed to create user with error \(error.localizedDescription)")
        }
    }
    
    func singOut(){
        do{
            try Auth.auth().signOut()  //signs out user on backend
            self.userSession = nil     //wipes ou user session and takes to us back to login screen
            self.currentUser = nil     //wipes ou current user data model
        } catch {
            print("DEBUG: Failed to sign out with erorr \(error.localizedDescription)")
        }
    }
    
    func deleteAccount(){
        do {
            try Auth.auth().currentUser?.delete()
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
        } catch {
            print("DEBUG: Failed to delete account with error \(error.localizedDescription)")
        }
    }


    
    func fetchUser() async{
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let snapshot = try? await Firestore.firestore().collection("users").document(uid).getDocument() else { return }
        self.currentUser = try? snapshot.data(as: User.self)
    }
    
}
