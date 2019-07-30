//
//  MapViewController.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 30/07/19.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    var location: CLLocation!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Map"
        setupUI()
        createRightButton()
    }

    func setupUI() {
        var region = MKCoordinateRegion()
        region.center.latitude = location.coordinate.latitude
        region.center.longitude = location.coordinate.longitude
        region.span.latitudeDelta = 0.01
        region.span.longitudeDelta = 0.01
        mapView.setRegion(region, animated: false)
        mapView.showsUserLocation = true
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        mapView.addAnnotation(annotation)
    }

    func createRightButton() {
        navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Open In Maps",
                style: .plain, target: self, action: #selector(openInMap))]
    }

    @objc func openInMap() {
        let regionDestination: CLLocationDistance = 10000
        let coordinates = location.coordinate
        let regionSpan = MKCoordinateRegion(center: coordinates,
                latitudinalMeters: regionDestination,
                longitudinalMeters: regionDestination)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placeMark = MKPlacemark(coordinate: coordinates)
        let mapItem = MKMapItem(placemark: placeMark)
        mapItem.name = "User's Location"
        mapItem.openInMaps(launchOptions: options)
    }
}
