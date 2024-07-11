//
//  LocationPickerView.swift
//  cashdine1
//
//  Created by Vasyl Maryna on 17.05.2024.
//

import SwiftUI
import MapKit
import CoreLocation

struct LocationPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @State private var searchText = ""
    @State private var mapView = MKMapView()
    @StateObject private var locationManager = LocationManager()
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    
    var body: some View {
        VStack {
            HStack {
                TextField("Caută locația", text: $searchText, onEditingChanged: { editingChanged in
                    isSearching = editingChanged
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                
                Button("Caută") {
                    searchLocation()
                }
                .padding()
            }
            
            if isSearching && !searchResults.isEmpty {
                List(searchResults, id: \.self) { item in
                    Button(action: {
                        selectLocation(item: item)
                    }) {
                        Text(item.name ?? "Unknown place")
                            .padding()
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.white.opacity(0.8))
                .cornerRadius(10)
                .padding()
                .transition(.opacity)
            }
            
            MapView(selectedLocation: $selectedLocation, mapView: $mapView, locationManager: locationManager)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismissSearch()
                }
                .onAppear {
                    if let userLocation = locationManager.currentLocation {
                        let region = MKCoordinateRegion(center: userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                        mapView.setRegion(region, animated: true)
                    }
                }
                .onDisappear {
                    if let coordinate = mapView.annotations.first?.coordinate {
                        selectedLocation = coordinate
                    }
                }
            
            Button("Selectează această locație") {
                if let coordinate = mapView.annotations.first?.coordinate {
                    selectedLocation = coordinate
                }
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
    }
    
    private func searchLocation() {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response else {
                print("Eroare la căutarea locației: \(String(describing: error))")
                return
            }
            
            searchResults = response.mapItems
        }
    }
    
    private func selectLocation(item: MKMapItem) {
        let coordinate = item.placemark.coordinate
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = item.name
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(annotation)
        mapView.setRegion(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)), animated: true)
        selectedLocation = coordinate
        dismissSearch()
    }
    
    private func dismissSearch() {
        searchText = ""
        isSearching = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.first
    }
}

struct MapView: UIViewRepresentable {
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var mapView: MKMapView
    var locationManager: LocationManager
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        self.mapView = mapView
        let gestureRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.tap(_:)))
        mapView.addGestureRecognizer(gestureRecognizer)
        mapView.showsUserLocation = true
        if let userLocation = locationManager.currentLocation {
            let region = MKCoordinateRegion(center: userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            mapView.setRegion(region, animated: true)
        }
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        if let coordinate = selectedLocation {
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            uiView.removeAnnotations(uiView.annotations)
            uiView.addAnnotation(annotation)
            uiView.setRegion(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)), animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        @objc func tap(_ gestureRecognizer: UITapGestureRecognizer) {
            let mapView = gestureRecognizer.view as! MKMapView
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            parent.selectedLocation = coordinate
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotation(annotation)
        }
    }
}

