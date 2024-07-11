//
//  GoogleMapsView.swift
//  cashdine1
//
//  Created by Vasyl Maryna on 10.05.2024.
//

import SwiftUI
import GoogleMaps

struct GoogleMapsView: UIViewRepresentable {
    @Binding var selectedLocation: CLLocationCoordinate2D?
    
    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: 37.7749, longitude: -122.4194, zoom: 12.0)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        // Update map view
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(selectedLocation: $selectedLocation)
    }
    
    class Coordinator: NSObject, GMSMapViewDelegate {
        @Binding var selectedLocation: CLLocationCoordinate2D?
        
        init(selectedLocation: Binding<CLLocationCoordinate2D?>) {
            _selectedLocation = selectedLocation
        }
        
        func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            selectedLocation = coordinate
        }
    }
}
