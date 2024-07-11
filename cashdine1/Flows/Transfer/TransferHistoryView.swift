//
//  TransferHistoryView.swift
//  cashdine1
//
//  Created by Vasyl Maryna on 29.04.2024.
//

import SwiftUI
import Firebase

struct TransferHistoryView: View {
    @State private var transferHistory = [Transfer]()
    @State private var userId: String = Auth.auth().currentUser?.uid ?? ""
    @State private var userNames: [String: String] = [:]
    @State private var restaurantNames: [String: String] = [:]
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack {
            Text("Istoric Transferuri")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
                .padding(.leading, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            List(transferHistory) { transfer in
                VStack(alignment: .leading) {
                    Text("De la: \(userNames[transfer.fromUserId] ?? transfer.fromUserId)")
                    Text("Către: \(transfer.toType == "restaurant" ? (restaurantNames[transfer.toUserId] ?? transfer.toUserId) : (userNames[transfer.toUserId] ?? transfer.toUserId))")
                    Text("Restaurant: \(restaurantNames[transfer.restaurantId] ?? transfer.restaurantId)")
                    Text("Puncte: \(transfer.points, specifier: "%.2f")")
                    Text("Data: \(transfer.timestamp.dateValue(), formatter: dateFormatter)")
                }
                .padding()
            }
        }
        .onAppear {
            fetchUserNames {
                fetchRestaurantNames {
                    fetchTransferHistory()
                }
            }
        }
    }
    
    func fetchUserNames(completion: @escaping () -> Void) {
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
            var names = [String: String]()
            for document in documents {
                let data = document.data()
                let id = document.documentID
                let fullname = data["fullname"] as? String ?? ""
                names[id] = fullname
            }
            self.userNames = names
            completion()
        }
    }
    
    func fetchRestaurantNames(completion: @escaping () -> Void) {
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
            var names = [String: String]()
            for document in documents {
                let data = document.data()
                let id = document.documentID
                let name = data["name"] as? String ?? ""
                names[id] = name
            }
            self.restaurantNames = names
            completion()
        }
    }
    
    func fetchTransferHistory() {
        let db = Firestore.firestore()
        db.collection("transfers")
            .whereField("fromUserId", isEqualTo: userId)
            .getDocuments { fromQuerySnapshot, error in
                if let error = error {
                    print("Eroare la preluarea transferurilor: \(error)")
                    return
                }
                guard let fromDocuments = fromQuerySnapshot?.documents else {
                    print("Nu s-au găsit transferuri trimise")
                    return
                }
                let fromTransfers = fromDocuments.compactMap { queryDocumentSnapshot -> Transfer? in
                    let data = queryDocumentSnapshot.data()
                    let id = queryDocumentSnapshot.documentID
                    let fromUserId = data["fromUserId"] as? String ?? ""
                    let toUserId = data["toUserId"] as? String ?? ""
                    let restaurantId = data["restaurantId"] as? String ?? ""
                    let points = data["points"] as? Double ?? 0.0
                    let timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
                    let toType = data["toType"] as? String ?? ""
                    return Transfer(id: id, fromUserId: fromUserId, toUserId: toUserId, restaurantId: restaurantId, points: points, timestamp: timestamp, toType: toType)
                }
                
                db.collection("transfers")
                    .whereField("toUserId", isEqualTo: userId)
                    .getDocuments { toQuerySnapshot, error in
                        if let error = error {
                            print("Eroare la preluarea transferurilor: \(error)")
                            return
                        }
                        guard let toDocuments = toQuerySnapshot?.documents else {
                            print("Nu s-au găsit transferuri primite")
                            return
                        }
                        let toTransfers = toDocuments.compactMap { queryDocumentSnapshot -> Transfer? in
                            let data = queryDocumentSnapshot.data()
                            let id = queryDocumentSnapshot.documentID
                            let fromUserId = data["fromUserId"] as? String ?? ""
                            let toUserId = data["toUserId"] as? String ?? ""
                            let restaurantId = data["restaurantId"] as? String ?? ""
                            let points = data["points"] as? Double ?? 0.0
                            let timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
                            let toType = data["toType"] as? String ?? ""
                            return Transfer(id: id, fromUserId: fromUserId, toUserId: toUserId, restaurantId: restaurantId, points: points, timestamp: timestamp, toType: toType)
                        }
                        
                        // Combine and sort the transfer arrays
                        let allTransfers = fromTransfers + toTransfers
                        self.transferHistory = allTransfers.sorted { $1.timestamp.dateValue() < $0.timestamp.dateValue() }
                    }
            }
    }
}

struct Transfer: Identifiable {
    var id: String
    var fromUserId: String
    var toUserId: String
    var restaurantId: String
    var points: Double
    var timestamp: Timestamp
    var toType: String
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()
