//
//  ViewController.swift
//  PokeFinder
//
//  Created by Mikko Hilpinen on 27.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate
{
	@IBOutlet weak var mapView: MKMapView!
	
	let locationMngr = CLLocationManager()
	
	private let rangeKilometers = 10.0
	
	private var geoFire: GeoFire!
	private var geoFireRef: FIRDatabaseReference!
	private var mapIsCentered = false
	private var lastPokemonQueryHandle: FirebaseHandle?
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		mapView.delegate = self
		mapView.userTrackingMode = MKUserTrackingMode.follow
		
		geoFireRef = FIRDatabase.database().reference()
		geoFire = GeoFire(firebaseRef: geoFireRef)
		
		locationAuthStatus()
	}
	
	override func viewDidAppear(_ animated: Bool)
	{
		locationAuthStatus()
	}

	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	@IBAction func spotRandomPokemon(_ sender: UIButton)
	{
		let location = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
		let randomId = arc4random_uniform(151) + 1
		print("ADDING POKEMON")
		createSighting(forLocation: location, withPokemon: Int(randomId))
	}
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
	{
		if status == .authorizedWhenInUse
		{
			mapView.showsUserLocation = true
		}
	}
	
	func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation)
	{
		if !mapIsCentered
		{
			if let location = userLocation.location
			{
				centerMapOnLocation(location)
			}
		}
	}
	
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
	{
		var annotationView: MKAnnotationView?
		
		if annotation is MKUserLocation
		{
			annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
			annotationView?.image = UIImage(named: "ash")
		}
		else if let annotation = annotation as? PokeAnnotation
		{
			if let dequedView = mapView.dequeueReusableAnnotationView(withIdentifier: "Pokemon")
			{
				annotationView = dequedView
			}
			else
			{
				annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Pokemon")
			}
			
			annotationView?.annotation = annotation
			annotationView?.canShowCallout = true
			annotationView?.image = UIImage(named: "\(annotation.pokemonId)")
			
			let button = UIButton()
			button.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
			button.setImage(UIImage(named: "map"), for: .normal)
			annotationView?.rightCalloutAccessoryView = button
		}
		
		return annotationView
	}
	
	func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool)
	{
		let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
		showSightingsOnMap(location: loc)
	}
	
	func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl)
	{
		if let annotation = view.annotation as? PokeAnnotation
		{
			let placeMark = MKPlacemark(coordinate: annotation.coordinate)
			let destination = MKMapItem(placemark: placeMark)
			destination.name = "Pokemon Sighting"
			
			let regionDistance: CLLocationDistance = 1000
			let regionSpan = MKCoordinateRegionMakeWithDistance(annotation.coordinate, regionDistance, regionDistance)
			
			let options = [MKLaunchOptionsMapCenterKey : NSValue(mkCoordinate: regionSpan.center),
			               MKLaunchOptionsMapSpanKey : NSValue(mkCoordinateSpan: regionSpan.span),
			               MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeWalking] as [String : Any]
			
			MKMapItem.openMaps(with: [destination], launchOptions: options)
		}
	}
	
	func mapViewWillStartLoadingMap(_ mapView: MKMapView)
	{
		print("LOADING MAP")
	}
	
	func mapViewDidFinishLoadingMap(_ mapView: MKMapView)
	{
		print("MAP LOADED")
	}
	
	func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool)
	{
		print("MAP RENDERED")
	}
	
	func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error)
	{
		print("MAP LOAD FAILED")
		print(error)
	}
	
	private func locationAuthStatus()
	{
		if CLLocationManager.authorizationStatus() == .authorizedWhenInUse
		{
			mapView.showsUserLocation = true
		}
		else
		{
			locationMngr.requestWhenInUseAuthorization()
		}
	}
	
	private func centerMapOnLocation(_ location: CLLocation)
	{
		mapIsCentered = true
		print("CENTERING MAP ON USER")
		let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, rangeKilometers * 1000, rangeKilometers * 1000)
		mapView.setRegion(coordinateRegion, animated: true)
	}
	
	private func createSighting(forLocation location: CLLocation, withPokemon pokeId: Int)
	{
		// Normally you would use Firebase key here
		geoFire.setLocation(location, forKey: "\(pokeId)")
	}
	
	private func showSightingsOnMap(location: CLLocation)
	{
		// Always stops the previous query when the next one is started
		if let lastQueryHandle = lastPokemonQueryHandle
		{
			geoFireRef.removeObserver(withHandle: lastQueryHandle)
		}
		
		let circleQuery = geoFire.query(at: location, withRadius: rangeKilometers)
		lastPokemonQueryHandle = circleQuery?.observe(.keyEntered)
		{
			(key, location) in
			
			if let key = key, let location = location
			{
				print("NEW POKEMON DATA RECEIVED")
				let annotation = PokeAnnotation(id: Int(key)!, coordinate: location.coordinate)
				self.mapView.addAnnotation(annotation)
			}
		}
	}
}

