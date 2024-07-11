//
//  RestaurantView.swift
//  cashdine1
//
//  Created by Vasyl Maryna on 29.04.2024.
//

import SwiftUI
import Firebase
import SDWebImageSwiftUI
import CoreLocation
import MapKit

struct RestaurantView: View {
    @StateObject private var coordinator = Coordinator()
    @State private var restaurants = [Restaurant]()
    @State private var filteredRestaurants = [Restaurant]()
    @State private var userCity: String = "Obținere locație..."
    @State private var userLocation: CLLocation?
    @State private var searchQuery: String = ""
    @State private var selectedFilter: FilterType = .alphabetical

    var selectRestaurantForTransfer: (AppRestaurant) -> Void

    enum FilterType {
        case alphabetical, location, points
    }

    var body: some View {
        NavigationView {
            VStack {
                Text(userCity)
                    .padding()

                Picker("Filtrează după", selection: $selectedFilter) {
                    Text("Alfabetic").tag(FilterType.alphabetical)
                    Text("Locație").tag(FilterType.location)
                    Text("Puncte").tag(FilterType.points)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if !filteredRestaurants.isEmpty {
                    List {
                        ForEach(filteredRestaurants, id: \.id) { restaurant in
                            NavigationLink(destination: RestaurantDetailView(restaurant: restaurant, userLocation: $userLocation, selectRestaurantForTransfer: selectRestaurantForTransfer)) {
                                RestaurantRowView(restaurant: restaurant, userLocation: userLocation)
                            }
                        }
                    }
                    .navigationTitle("Restaurante")
                } else {
                    Text("Așteptăm restaurantele...")
                        .padding()
                }
            }
            .onAppear {
                coordinator.startUpdatingLocation()
                fetchRestaurants()
            }
            .onChange(of: selectedFilter) { _ in
                applyFilter()
            }
            .onReceive(coordinator.$userLocation) { location in
                if let location = location {
                    userLocation = location
                    getCityName(from: location) { city in
                        userCity = city ?? "Locație necunoscută"
                    }
                }
            }
        }
    }

    func fetchRestaurants() {
        let db = Firestore.firestore()
        guard let userId = Auth.auth().currentUser?.uid else { return }
        guard let userLocation = userLocation else { return }

        db.collection("restaurants").getDocuments { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Nu s-au găsit documente")
                return
            }
            
            var fetchedRestaurants = [Restaurant]()
            
            let dispatchGroup = DispatchGroup()
            
            for queryDocumentSnapshot in documents {
                dispatchGroup.enter()
                let data = queryDocumentSnapshot.data()
                let id = queryDocumentSnapshot.documentID
                let name = data["name"] as? String ?? ""
                let description = data["description"] as? String ?? ""
                let location = data["location"] as? GeoPoint
                let imageURL = data["imageURL"] as? String ?? ""

                var points: Double = 0
                db.collection("puncte")
                    .whereField("userId", isEqualTo: userId)
                    .whereField("restaurantId", isEqualTo: id)
                    .getDocuments { (querySnapshot, error) in
                        if let error = error {
                            print("Eroare la preluarea punctelor: \(error)")
                        } else {
                            for document in querySnapshot!.documents {
                                if let data = document.data() as? [String: Any],
                                   let fetchedPoints = data["points"] as? Double {
                                    points += fetchedPoints
                                }
                            }
                        }
                        
                        if let location = location {
                            let locationString = "\(location.latitude),\(location.longitude)"
                            let restaurantLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                            let distance = userLocation.distance(from: restaurantLocation)
                            fetchedRestaurants.append(Restaurant(id: id, name: name, description: description, location: locationString, imageURL: imageURL, points: points, distance: distance))
                        } else {
                            fetchedRestaurants.append(Restaurant(id: id, name: name, description: description, location: "", imageURL: imageURL, points: points, distance: nil))
                        }
                        dispatchGroup.leave()
                    }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.restaurants = fetchedRestaurants
                applyFilter()
            }
        }
    }

    func applyFilter() {
        switch selectedFilter {
        case .alphabetical:
            filteredRestaurants = restaurants.sorted { $0.name < $1.name }
        case .location:
            filteredRestaurants = restaurants.sorted { ($0.distance ?? 0) < ($1.distance ?? 0) }
        case .points:
            filteredRestaurants = restaurants.sorted { $0.points > $1.points }
        }
    }

    func getCityName(from location: CLLocation, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Eroare la geocodare inversă: \(error.localizedDescription)")
                completion(nil)
            } else if let placemarks = placemarks, let placemark = placemarks.first {
                let city = placemark.locality ?? placemark.subAdministrativeArea ?? placemark.administrativeArea
                completion(city)
            } else {
                completion(nil)
            }
        }
    }
}

class Coordinator: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var userLocation: CLLocation?

    let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func startUpdatingLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            userLocation = location
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error getting location: \(error.localizedDescription)")
    }
}

struct Restaurant: Identifiable {
    var id: String
    var name: String
    var description: String
    var location: String
    var imageURL: String
    var points: Double
    var distance: Double?

    func distance(from location: CLLocation?) -> String? {
        guard let distance = distance else {
            return nil
        }

        if distance > 1000 {
            let distanceInKilometers = distance / 1000
            return String(format: "%.1f km", distanceInKilometers)
        } else {
            return String(format: "%.0f m", distance)
        }
    }

    func locationCoordinate() -> CLLocationCoordinate2D? {
        let components = self.location.components(separatedBy: ",")
        guard components.count == 2, let latitude = Double(components[0]), let longitude = Double(components[1]) else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct RestaurantRowView: View {
    let restaurant: Restaurant
    var userLocation: CLLocation?

    var body: some View {
        HStack(spacing: 15) {
            WebImage(url: URL(string: restaurant.imageURL))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .cornerRadius(10)
                .shadow(radius: 5)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(restaurant.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(restaurant.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let distanceString = restaurant.distance(from: userLocation) {
                    Text("Distanță: \(distanceString)")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Text("Distanță necunoscută")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text("Puncte acumulate: \(restaurant.points, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 5)
            
            Spacer()
        }
        .padding(10)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    @Binding var userLocation: CLLocation?
    @State private var points: Double = 0.0
    @State private var navigateToTransferView = false
    @State private var selectedRestaurantForTransfer: AppRestaurant?
    
    var selectRestaurantForTransfer: (AppRestaurant) -> Void

    var body: some View {
        VStack {
            Text(restaurant.description)
                .padding()

            Text("Puncte acumulate: \(points, specifier: "%.2f")")
                .font(.headline)
                .padding()
                .onTapGesture {
                    let appRestaurant = AppRestaurant(id: restaurant.id, name: restaurant.name, description: restaurant.description, location: restaurant.location, imageURL: restaurant.imageURL, points: Int(points), distance: restaurant.distance)
                    selectRestaurantForTransfer(appRestaurant)
                    navigateToTransferView = true
                }

            if let restaurantCoordinate = restaurant.locationCoordinate(), let userLocation = userLocation {
                Button(action: {
                    openMapForPlace(latitude: restaurantCoordinate.latitude, longitude: restaurantCoordinate.longitude, placeName: restaurant.name)
                }) {
                    RestaurantMapView(userLocation: userLocation, destinationCoordinate: restaurantCoordinate)
                        .frame(height: 300)
                        .cornerRadius(8)
                        .padding()
                }

                Text("Distanță față de locația ta: \(restaurant.distance(from: userLocation) ?? "necunoscută")")
                    .foregroundColor(.blue)
            } else {
                Text("Locația restaurantului nu este disponibilă")
                    .foregroundColor(.red)
            }

            Spacer()
        }
        .navigationTitle(restaurant.name)
        .onAppear {
            fetchPuncte()
        }
        .background(
            NavigationLink(
                destination: TransferView(selectedRestaurant: $selectedRestaurantForTransfer),
                isActive: $navigateToTransferView,
                label: { EmptyView() }
            )
        )
    }

    func fetchPuncte() {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }

        let db = Firestore.firestore()
        db.collection("puncte")
            .whereField("userId", isEqualTo: userId)
            .whereField("restaurantId", isEqualTo: restaurant.id)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Eroare la preluarea punctelor: \(error)")
                } else {
                    var totalPoints: Double = 0.0
                    for document in querySnapshot!.documents {
                        if let data = document.data() as? [String: Any],
                           let fetchedPoints = data["points"] as? Double {
                            totalPoints += fetchedPoints
                        }
                    }
                    points = totalPoints
                }
            }
    }

    func openMapForPlace(latitude: Double, longitude: Double, placeName: String) {
        let urlString = "http://maps.apple.com/?q=\(placeName)&sll=\(latitude),\(longitude)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

struct RestaurantMapView: UIViewRepresentable {
    var userLocation: CLLocation
    var destinationCoordinate: CLLocationCoordinate2D
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        let userAnnotation = MKPointAnnotation()
        userAnnotation.coordinate = userLocation.coordinate
        userAnnotation.title = "Locația ta"
        
        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.coordinate = destinationCoordinate
        destinationAnnotation.title = "Restaurant"
        
        mapView.addAnnotations([userAnnotation, destinationAnnotation])
        
        let region = MKCoordinateRegion(center: destinationCoordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
        
        let directionRequest = MKDirections.Request()
        let userPlacemark = MKPlacemark(coordinate: userLocation.coordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
        
        directionRequest.source = MKMapItem(placemark: userPlacemark)
        directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            guard let response = response else {
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
                return
            }
            
            let route = response.routes[0]
            mapView.addOverlay(route.polyline, level: .aboveRoads)
            
            var rect = route.polyline.boundingMapRect
            rect = mapView.mapRectThatFits(rect, edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
            mapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }
        
        let circle = MKCircle(center: userLocation.coordinate, radius: 10)
        mapView.addOverlay(circle)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RestaurantMapView
        
        init(_ parent: RestaurantMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 4.0
                return renderer
            } else if let circle = overlay as? MKCircle {
                let renderer = MKCircleRenderer(circle: circle)
                renderer.fillColor = UIColor.blue.withAlphaComponent(0.1)
                renderer.strokeColor = .blue
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
