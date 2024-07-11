//
//  CreateRestaurantView.swift
//  cashdine1
//
//  Created by Vasyl Maryna on 29.04.2024.
//

import SwiftUI
import Firebase
import MapKit
import CoreLocation
import FirebaseStorage

struct CreateRestaurantView: View {
    @State private var restaurantName = ""
    @State private var restaurantDescription = ""
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var selectedImage: UIImage?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showLocationPicker = false
    @State private var showImagePicker = false
    
    var body: some View {
        VStack {
            TextField("Nume restaurant", text: $restaurantName)
                .padding()
            
            TextField("Descriere restaurant", text: $restaurantDescription)
                .padding()
            
            Button(action: {
                showLocationPicker = true
            }) {
                Text("Adaugă Locația")
            }
            .padding()
            
            if let location = selectedLocation {
                Text("Locația selectată: \(location.latitude), \(location.longitude)")
            }
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .padding()
            }
            
            Button(action: {
                showImagePicker = true
            }) {
                Text("Adaugă Imagine")
            }
            .padding()
            
            Button(action: {
                addRestaurant()
            }) {
                Text("Adaugă restaurant")
            }
            .padding()
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(selectedLocation: $selectedLocation)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Succes"), message: Text(alertMessage), dismissButton: .default(Text("OK"), action: {
                resetFields()
            }))
        }
    }
    
    func addRestaurant() {
        guard !restaurantName.isEmpty else {
            showAlert(message: "Te rog introdu numele restaurantului.")
            return
        }
        
        guard let selectedLocation = selectedLocation else {
            showAlert(message: "Te rog selectează locația restaurantului pe hartă.")
            return
        }
        
        guard let selectedImage = selectedImage else {
            showAlert(message: "Te rog adaugă o imagine.")
            return
        }
        
        uploadImage(image: selectedImage) { imageURL in
            let location = CLLocation(latitude: selectedLocation.latitude, longitude: selectedLocation.longitude)
            
            let db = Firestore.firestore()
            let restaurantRef = db.collection("restaurants").document()
            let restaurantId = restaurantRef.documentID
            
            restaurantRef.setData([
                "id": restaurantId,
                "name": restaurantName,
                "description": restaurantDescription,
                "location": GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude),
                "imageURL": imageURL
            ]) { error in
                if let error = error {
                    print("Eroare la adăugarea restaurantului: \(error)")
                    showAlert(message: "Eroare la adăugarea restaurantului: \(error.localizedDescription)")
                } else {
                    print("Restaurant adăugat cu succes!")
                    showAlert(message: "Restaurant adăugat cu succes!")
                }
            }
        }
    }
    
    func uploadImage(image: UIImage, completion: @escaping (String) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Eroare la compresia imaginii.")
            showAlert(message: "Eroare la compresia imaginii.")
            return
        }
        
        let storageRef = Storage.storage().reference().child("restaurant_images/\(UUID().uuidString).jpg")
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Eroare la încărcarea imaginii: \(error)")
                showAlert(message: "Eroare la încărcarea imaginii: \(error.localizedDescription)")
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Eroare la obținerea URL-ului imaginii: \(error)")
                    showAlert(message: "Eroare la obținerea URL-ului imaginii: \(error.localizedDescription)")
                    return
                }
                
                guard let imageURL = url?.absoluteString else {
                    print("URL-ul imaginii este nil.")
                    showAlert(message: "URL-ul imaginii este nil.")
                    return
                }
                
                completion(imageURL)
            }
        }
    }
    
    func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
    
    func resetFields() {
        restaurantName = ""
        restaurantDescription = ""
        selectedLocation = nil
        selectedImage = nil
    }
}
