//
//  PurchaseListView.swift
//  cashdine1
//
//  Created by Vasyl Maryna on 29.04.2024.
//

import SwiftUI
import Firebase

struct Purchase: Identifiable {
    var id: String
    var userId: String
    var restaurantId: String
    var restaurantName: String
    var items: [PurchaseItem]
    var totalAmount: Double
    var points: Double
    var date: Date
}

struct PurchaseItem: Identifiable {
    var id: String
    var itemName: String
    var amount: Double
}

struct PurchaseListView: View {
    @State private var purchases = [Purchase]()
    @State private var userId: String = Auth.auth().currentUser?.uid ?? ""

    var body: some View {
        NavigationView {
            VStack {
                if !purchases.isEmpty {
                    List(purchases) { purchase in
                        NavigationLink(destination: PurchaseDetailView(purchase: purchase)) {
                            PurchaseRowView(purchase: purchase)
                        }
                    }
                    .navigationTitle("Purchase History")
                    .refreshable {
                        fetchPurchases(for: userId)
                    }
                } else {
                    Text("No purchases found")
                        .padding()
                }
            }
            .onAppear {
                if !userId.isEmpty {
                    fetchPurchases(for: userId)
                }
            }
        }
    }

    func fetchPurchases(for userId: String) {
        let db = Firestore.firestore()

        db.collection("purchases").whereField("userId", isEqualTo: userId).getDocuments { querySnapshot, error in
            if let error = error {
                print("Error fetching purchases: \(error)")
                return
            }

            guard let documents = querySnapshot?.documents else {
                print("No purchases found")
                return
            }

            self.purchases = documents.compactMap { queryDocumentSnapshot -> Purchase? in
                let data = queryDocumentSnapshot.data()
                let id = queryDocumentSnapshot.documentID
                let userId = data["userId"] as? String ?? ""
                let restaurantId = data["restaurantId"] as? String ?? ""
                let restaurantName = data["restaurantName"] as? String ?? ""
                let itemsData = data["items"] as? [[String: Any]] ?? []
                let items = itemsData.compactMap { itemData -> PurchaseItem? in
                    let itemId = itemData["id"] as? String ?? UUID().uuidString
                    let itemName = itemData["itemName"] as? String ?? ""
                    let amount = itemData["amount"] as? Double ?? 0.0
                    return PurchaseItem(id: itemId, itemName: itemName, amount: amount)
                }
                let totalAmount = data["totalAmount"] as? Double ?? 0.0
                let points = data["points"] as? Double ?? 0.0

                let dateString = data["date"] as? String ?? ""
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let date = dateFormatter.date(from: dateString) ?? Date()

                return Purchase(id: id, userId: userId, restaurantId: restaurantId, restaurantName: restaurantName, items: items, totalAmount: totalAmount, points: points, date: date)
            }
        }
    }
}

struct PurchaseRowView: View {
    let purchase: Purchase

    var body: some View {
        VStack(alignment: .leading) {
            Text(purchase.restaurantName)
                .font(.headline)
            Text("Total Amount: \(purchase.totalAmount, specifier: "%.2f") RON")
                .font(.subheadline)
            Text("Points: \(purchase.points, specifier: "%.2f")")
                .font(.subheadline)
            Text("Date: \(purchase.date, formatter: dateFormatter)")
                .font(.subheadline)
        }
        .padding()
    }
}

struct PurchaseDetailView: View {
    let purchase: Purchase

    var body: some View {
        VStack(alignment: .leading) {
            Text(purchase.restaurantName)
                .font(.largeTitle)
                .padding()

            List(purchase.items) { item in
                HStack {
                    Text(item.itemName)
                        .font(.headline)
                    Spacer()
                    Text("\(item.amount, specifier: "%.2f") RON")
                        .font(.subheadline)
                }
            }

            Text("Total Amount: \(purchase.totalAmount, specifier: "%.2f") RON")
                .font(.headline)
                .padding()
            Text("Points: \(purchase.points, specifier: "%.2f")")
                .font(.headline)
                .padding()
            Text("Date: \(purchase.date, formatter: dateFormatter)")
                .font(.headline)
                .padding()

            Spacer()
        }
        .navigationTitle("Purchase Details")
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()
