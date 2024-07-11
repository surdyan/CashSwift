//
//  TransferView.swift
//  cashdine1
//
//  Created by Vasyl Maryna on 29.04.2024.
//

import SwiftUI
import Firebase

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct TransferView: View {
    @Binding var selectedRestaurant: AppRestaurant?
    @State private var pointsToTransfer: String = ""
    @State private var transferToUserId: String? = nil
    @State private var userId: String = Auth.auth().currentUser?.uid ?? ""
    @State private var restaurants = [AppRestaurant]()
    @State private var users = [AppUser]()
    @State private var availablePoints: Double = 0.0
    @State private var showTransferUserPicker = false
    @State private var showError = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    @State private var transferButtonText = "Transfer la Utilizator"
    @State private var successMessage = ""

    var body: some View {
        NavigationView { 
            VStack {
                Spacer()
                
                Text("Transfer Puncte")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                    .padding(.leading, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                Form {
                    Section(header: Text("Alege Restaurantul").font(.headline)) {
                        Picker("Restaurant", selection: Binding(
                            get: { selectedRestaurant?.id },
                            set: { newValue in
                                if let newValue = newValue, let restaurant = restaurants.first(where: { $0.id == newValue }) {
                                    selectedRestaurant = restaurant
                                    fetchAvailablePoints()
                                }
                            })) {
                            if selectedRestaurant == nil {
                                Text("Selectează un restaurant").tag(String?.none)
                            }
                            ForEach(restaurants.sorted(by: { $0.name < $1.name }), id: \.id) { restaurant in
                                Text(restaurant.name).tag(String?.some(restaurant.id))
                            }
                        }
                    }

                    Text("Puncte disponibile: \(availablePoints, specifier: "%.2f")")
                        .font(.headline)
                        .padding()

                    Section(header: Text("Puncte de Transferat").font(.headline)) {
                        TextField("Introdu punctele", text: $pointsToTransfer)
                            .keyboardType(.decimalPad)
                            .onChange(of: pointsToTransfer) { _ in
                                validatePoints()
                            }
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        UIApplication.shared.endEditing()
                                    }
                                }
                            }
                        if showError {
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }
                        if showSuccess {
                            Text(successMessage)
                                .foregroundColor(.green)
                        }
                    }

                    Section {
                        Button(action: {
                            showTransferUserPicker.toggle()
                            transferButtonText = showTransferUserPicker ? "Transfer la Restaurant" : "Transfer la Utilizator"
                            transferToUserId = nil
                        }) {
                            Text(transferButtonText)
                                .font(.headline)
                        }
                        if showTransferUserPicker {
                            Picker("Utilizator", selection: $transferToUserId) {
                                if transferToUserId == nil {
                                    Text("Selectează un utilizator").tag(String?.none)
                                }
                                ForEach(users.sorted(by: { $0.fullname < $1.fullname }).filter { $0.id != userId }, id: \.id) { user in
                                    Text(user.fullname).tag(String?.some(user.id))
                                }
                            }
                        }
                    }

                    Button(action: {
                        transferPoints()
                    }) {
                        Text("Transferă Puncte")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .padding()
                }
                .onAppear {
                    fetchRestaurants()
                    fetchUsers()
                    if let selectedRestaurant = selectedRestaurant {
                        fetchAvailablePoints()
                    }
                }
            }
            .navigationBarItems(trailing: NavigationLink(destination: TransferHistoryView()) {
                Text("History")
            })
            .navigationTitle("")
        }
    }

    func fetchRestaurants() {
        let db = Firestore.firestore()
        db.collection("restaurants").getDocuments { querySnapshot, error in
            if let error = error {
                print("Eroare la preluarea restaurantelor: \(error)")
                return
            }
            guard let documents = querySnapshot?.documents else {
                print("Nu s-au găsit restaurante")
                return
            }
            self.restaurants = documents.compactMap { queryDocumentSnapshot -> AppRestaurant? in
                let data = queryDocumentSnapshot.data()
                let id = queryDocumentSnapshot.documentID
                let name = data["name"] as? String ?? ""
                let description = data["description"] as? String ?? ""
                let location = data["location"] as? String ?? ""
                let imageURL = data["imageURL"] as? String ?? ""
                return AppRestaurant(id: id, name: name, description: description, location: location, imageURL: imageURL, points: 0, distance: nil)
            }
        }
    }

    func fetchUsers() {
        let db = Firestore.firestore()
        db.collection("users").getDocuments { querySnapshot, error in
            if let error = error {
                print("Eroare la preluarea utilizatorilor: \(error)")
                return
            }
            guard let documents = querySnapshot?.documents else {
                print("Nu s-au găsit utilizatori")
                return
            }
            self.users = documents.compactMap { queryDocumentSnapshot -> AppUser? in
                let data = queryDocumentSnapshot.data()
                let id = queryDocumentSnapshot.documentID
                let fullname = data["fullname"] as? String ?? ""
                return AppUser(id: id, fullname: fullname)
            }
        }
    }

    func fetchAvailablePoints() {
        let db = Firestore.firestore()
        guard let selectedRestaurant = selectedRestaurant else {
            self.availablePoints = 0.0
            return
        }
        db.collection("puncte")
            .whereField("userId", isEqualTo: userId)
            .whereField("restaurantId", isEqualTo: selectedRestaurant.id)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Eroare la preluarea punctelor: \(error)")
                    return
                }
                guard let document = querySnapshot?.documents.first else {
                    self.availablePoints = 0.0
                    return
                }
                self.availablePoints = document.data()["points"] as? Double ?? 0.0
            }
    }

    func transferPoints() {
        let sanitizedPointsToTransfer = pointsToTransfer.replacingOccurrences(of: ",", with: ".")
        guard let points = Double(sanitizedPointsToTransfer), points > 0, points <= availablePoints else {
            print("Introdu puncte valide")
            showError = true
            showSuccess = false
            errorMessage = "Valoare invalidă sau insuficientă"
            return
        }

        let db = Firestore.firestore()
        let toType = showTransferUserPicker ? "utilizator" : "restaurant"
        let toUserId = showTransferUserPicker ? transferToUserId ?? "" : selectedRestaurant?.id ?? ""

        let transferData: [String: Any] = [
            "fromUserId": userId,
            "toUserId": toUserId,
            "restaurantId": selectedRestaurant?.id ?? "",
            "points": points,
            "timestamp": Timestamp(date: Date()),
            "toType": toType
        ]

        db.collection("transfers").addDocument(data: transferData) { error in
            if let error = error {
                print("Eroare la transferul punctelor: \(error)")
                showError = true
                showSuccess = false
                errorMessage = "Eroare la transferul punctelor"
            } else {
                print("Transfer realizat cu succes!")
                updatePointsInRestaurant(points: points)
                if let transferToUserId = transferToUserId {
                    updateUserPoints(points: points)
                }
                showError = false
                showSuccess = true
                successMessage = "Punctele au fost transferate"
                clearForm()
            }
        }
    }

    func updatePointsInRestaurant(points: Double) {
        let db = Firestore.firestore()

        db.collection("puncte")
            .whereField("userId", isEqualTo: userId)
            .whereField("restaurantId", isEqualTo: selectedRestaurant?.id ?? "")
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Eroare la actualizarea punctelor: \(error)")
                    return
                }

                guard let document = querySnapshot?.documents.first else { return }
                let existingPoints = document.data()["points"] as? Double ?? 0.0
                let newPoints = existingPoints - points

                db.collection("puncte").document(document.documentID).updateData([
                    "points": newPoints,
                    "userId": userId,
                    "restaurantId": selectedRestaurant?.id ?? ""
                ]) { error in
                    if let error = error {
                        print("Eroare la actualizarea punctelor: \(error)")
                    } else {
                        print("Punctele au fost actualizate!")
                        fetchAvailablePoints()
                    }
                }
            }
    }

    func updateUserPoints(points: Double) {
        let db = Firestore.firestore()
        let targetUserId = transferToUserId ?? userId
        let docRef = db.collection("puncte")
            .whereField("userId", isEqualTo: targetUserId)
            .whereField("restaurantId", isEqualTo: selectedRestaurant?.id ?? "")

        docRef.getDocuments { querySnapshot, error in
            if let error = error {
                print("Eroare la actualizarea punctelor utilizatorului: \(error)")
                return
            }

            if let document = querySnapshot?.documents.first {
                let existingPoints = document.data()["points"] as? Double ?? 0.0
                let newPoints = existingPoints + points

                db.collection("puncte").document(document.documentID).updateData([
                    "points": newPoints,
                    "userId": targetUserId,
                    "restaurantId": selectedRestaurant?.id ?? ""
                ]) { error in
                    if let error = error {
                        print("Eroare la actualizarea punctelor utilizatorului: \(error)")
                    } else {
                        print("Punctele utilizatorului au fost actualizate!")
                    }
                }
            } else {
                let newUserPointsData: [String: Any] = [
                    "userId": targetUserId,
                    "restaurantId": selectedRestaurant?.id ?? "",
                    "points": points
                ]

                db.collection("puncte").addDocument(data: newUserPointsData) { error in
                    if let error = error {
                        print("Eroare la crearea documentului pentru punctele utilizatorului: \(error)")
                    } else {
                        print("Documentul pentru punctele utilizatorului a fost creat!")
                    }
                }
            }
        }
    }

    func validatePoints() {
        let sanitizedPointsToTransfer = pointsToTransfer.replacingOccurrences(of: ",", with: ".")
        if let points = Double(sanitizedPointsToTransfer), points > availablePoints {
            showError = true
            errorMessage = "Nu aveți suficiente puncte disponibile."
        } else {
            showError = false
            errorMessage = ""
        }
    }

    func clearForm() {
        pointsToTransfer = ""
        transferToUserId = nil
        showError = false
        errorMessage = ""
        fetchAvailablePoints()
    }
}

struct AppUser: Identifiable {
    var id: String
    var fullname: String
}

struct AppRestaurant: Identifiable {
    var id: String
    var name: String
    var description: String
    var location: String
    var imageURL: String
    var points: Int
    var distance: Double?
}
