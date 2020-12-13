//
//  ViewController.swift
//  Map
//
//  Created by admin on 11.12.2020.
//

import UIKit
import MapKit
import CoreLocation

class MapVC: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var stepsBtn: UIButton!
    @IBOutlet weak var carBtn: UIButton!
    
    let locationManager = CLLocationManager()
    let regionInMeters : Double = 10000
    var previousLocation : CLLocation?
    var transportType : Bool = false
    var geoCoder = CLGeocoder()
    var directionsArray: [MKDirections] = []
        
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkLocationServices()
        stepsBtn.layer.masksToBounds = true
        carBtn.layer.masksToBounds = true
        stepsBtn.layer.cornerRadius = 16
        carBtn.layer.cornerRadius = 16
    }

    //MARK: - BUTTONS
    
    @IBAction func stepsBTN(_ sender: Any) {
        transportType = true
        getDirections()
    }
    
    @IBAction func carBTN(_ sender: Any) {
        transportType = false
        getDirections()
    }
    
    @IBAction func locationBTN(_ sender: Any) {
        centerViewOnUserLocation()
    }
    
    @IBAction func cancelBTN(_ sender: Any) {
        centerViewOnUserLocation()
        removeDirections()
    }
    
    //MARK: - LOCATION
    
    func setUpLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setUpLocationManager()
            checkLocationAuthorization()
        } else {
            // Show alert letting the user know they have to turn this on.
        }
    }
    
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
        func checkLocationAuthorization() {
            
            switch CLLocationManager.authorizationStatus() {
            
            case .authorizedWhenInUse:
                startTrackingUserLocation()
            case .denied:
                break
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
                break
            case .restricted:
                //
                break
            case .authorizedAlways:
                //
                break
            @unknown default:
                print("ERROR")
            }
        }
    
    func startTrackingUserLocation() {
        mapView.showsUserLocation = true
        centerViewOnUserLocation()
        locationManager.startUpdatingLocation()
        previousLocation = getCenterLocation(for: mapView)
    }
    
    func getCenterLocation(for mapView : MKMapView) -> CLLocation {
        let latidute = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latidute, longitude: longitude)
    }
    
    //MARK:-DIRECTIONS
    
    func getDirections() {
        
        guard let location = locationManager.location?.coordinate else {
            //TODO: Inform user we don't have their current location
            return
        }
        
        let request = createDirectionsRequest(from: location)
        let directions = MKDirections(request: request)
        resetMapView(withNew: directions)
        
        directions.calculate { [unowned self] (response, error) in
            
            guard let response = response else { return }
            
            for route in response.routes {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        let destinationCoordinate       = getCenterLocation(for: mapView).coordinate
        let startingLocation            = MKPlacemark(coordinate: coordinate)
        let destination                 = MKPlacemark(coordinate: destinationCoordinate)
        
        let request                     = MKDirections.Request()
        request.source                  = MKMapItem(placemark: startingLocation)
        request.destination             = MKMapItem(placemark: destination)
        request.transportType           = transoprtType()
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    func transoprtType()-> MKDirectionsTransportType {
        if transportType {
            return MKDirectionsTransportType.automobile
        } else {
            return MKDirectionsTransportType.walking
        }
    }
    
    func resetMapView(withNew directions: MKDirections) {
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map { $0.cancel() }
    }
    
    func removeDirections() {
        mapView.removeOverlays(mapView.overlays)
    }
}




