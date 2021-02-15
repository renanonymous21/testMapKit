//
//  ViewController.swift
//  testMapKit
//
//  Created by Rendy K.R on 18/11/20.
//

import UIKit
import MapKit

class TestAnotations: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String) {
        self.coordinate = coordinate
        self.title = title
    }
}

class ViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var flyoverButton: UIButton!
    
    let locationsData = [
            ["timelog": "2020-11-18 13:30:08", "lokasi": "113.73000,-8.164196438163671"],
            ["timelog": "2020-11-18 13:35:08", "lokasi": "113.75000,-8.18000"],
            ["timelog": "2020-11-19 13:40:08", "lokasi": "113.77000,-8.20000"]
        ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self

        for index in locationsData {
            let temp = index["lokasi"]?.split(separator: ",")
            let long = Double((temp?[0])!)
            let lat = Double((temp?[1])!)!
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long!)
            let title = index["timelog"]!
            mapView.addAnnotation(TestAnotations(coordinate: coordinate, title: title))
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    @IBAction func flyoverTapped(_ sender: Any) {
        let camera = MKMapCamera()
        camera.centerCoordinate = mapView.centerCoordinate
        camera.pitch = 80.0
        camera.altitude = 100.0
        camera.heading = 45.0
        mapView.setCamera(camera, animated: true)
    }
    
//    func test(date: String) -> [Dictionary<String, String>] {
//        let f = locationsData.filter({ ($0["timelog"]?.contains(date))!})
//        
//        return f
//    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView = MKAnnotationView()
        var identifier = ""
        for time in locationsData {
            identifier = time["timelog"]!
            if let dequedView = mapView.dequeueReusableAnnotationView(
                        withIdentifier: identifier)
                        as? MKPinAnnotationView {
                        annotationView = dequedView
            } else {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            annotationView.tintColor = .red
            annotationView.canShowCallout = true
            
            annotationView.accessibilityLabel = identifier
            
//            annotationView.clusteringIdentifier = identifier
        }
        
        return annotationView
    }
    
    func openAnnotation(annotation: MKAnnotation) {
        _ = [mapView.selectAnnotation(annotation, animated: true)]
    }
}
