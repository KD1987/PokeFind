//
//  ViewController.swift
//  pokefinder
//
//  Created by Kiel Delina on 2017-04-01.
//  Copyright © 2017 Dilemma. All rights reserved.
//

import UIKit
import MapKit
import GeoFire
import FirebaseDatabase

class ViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate {

    
    let locationManager = CLLocationManager()
    
    var mapHasCenteredOnce = false
    var geofire: GeoFire!
    var geoFireRef: FIRDatabaseReference!
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.userTrackingMode = MKUserTrackingMode.follow
        
        geoFireRef = FIRDatabase.database().reference()
        geofire = GeoFire(firebaseRef: geoFireRef)
        
    }
    
    //GeoFire code that saves the pokemon location
    func createSighting (forlocation location: CLLocation, withPokemon pokeID: Int) {
        
        geofire.setLocation(location, forKey: "\(pokeID)")
        
    }
    

    func showSightingsonMap (location: CLLocation) {
        
        var circleQuery = geofire.query(at: location, withRadius: 2.5)
        
        var qHandler = circleQuery?.observe(.keyEntered, with: { (key, location) in
            
            if let key = key, let location = location {
                
                let anno = pokeAnnotation(coordinate: location.coordinate, pokemonNumber: Int(key)!)
                self.mapView.addAnnotation(anno)
                
            }
            
        })
        
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        locationAuthStatus()
    }
    
    //asks user to see location
    func locationAuthStatus() {
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation == true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
        
    }
    
    //Asks user if can see location then displays user location
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == .authorizedWhenInUse {
            mapView.showsUserLocation == true
        }
    }
    
    //Sets the map on center and with 2km radius
    func centerMapOnLocation(location: CLLocation) {
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
        
        mapView.setRegion(coordinateRegion, animated: true)
        
    }
    
    //Initially sets the users location in the middle
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        
        if let loc = userLocation.location {
            
            if !mapHasCenteredOnce {
                
                centerMapOnLocation(location: loc)
                mapHasCenteredOnce = true
                
            }
            
        }
        
    }
    
    //Displays all the annotation (such as ash or pokemons)
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var annotationIdentifier = "Pokemon"
        var annotationView: MKAnnotationView?
        
        if annotation.isKind(of: MKUserLocation.self) {
            
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annotationView?.image = UIImage(named: "ash")
            
        } else if let deqAnno = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) {
            
            annotationView = deqAnno
            annotationView?.annotation = annotation
            
        } else {
        
            let av = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            av.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationView = av
            
        }
        
        if let annotationView = annotationView, let anno = annotation as? pokeAnnotation {
            
            annotationView.canShowCallout = true
            annotationView.image = UIImage(named: "\(anno.pokemonNumber)")
            let btn = UIButton()
            btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            btn.setImage(UIImage(named: "map"), for: .normal)
            annotationView.rightCalloutAccessoryView = btn
        }
        
        return annotationView
        
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        showSightingsonMap(location: loc)
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if let anno = view.annotation as? pokeAnnotation {
            
            let place = MKPlacemark(coordinate: anno.coordinate)
            let destination = MKMapItem(placemark: place)
            destination.name = "Pokemon sighting"
            let regionDistance: CLLocationDistance = 1000
            let regionSpan = MKCoordinateRegionMakeWithDistance(anno.coordinate, regionDistance, regionDistance)
            
            let options = [MKLaunchOptionsMapCenterKey: NSValue (mkCoordinate: regionSpan.center), MKLaunchOptionsMapSpanKey: NSValue (mkCoordinateSpan: regionSpan.span), MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving] as [String : Any]
            
            MKMapItem.openMaps(with: [destination], launchOptions: options)
            
        }
        
    }
    
    @IBAction func spotPoke(_ sender: Any) {
        
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        let rand = arc4random_uniform(150) + 1
        createSighting(forlocation: loc, withPokemon: Int(rand))
        
        
        
    }
    
    
    
    
}





    
    
    
    
    
    
    


