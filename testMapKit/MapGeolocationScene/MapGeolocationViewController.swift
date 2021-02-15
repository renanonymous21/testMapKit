//
//  MapGeolocationViewController.swift
//  testMapKit
//
//  Created by Rendy K.R on 17/12/20.
//

import UIKit
import MapKit
import GLKit
import CoreLocation

class MapGeolocationViewController: UIViewController {
    
    @IBOutlet weak var mapGeolocation: MKMapView!
    @IBOutlet weak var userRadiusTextField: UITextField!
    
    var locData = [LocationData]()
    let locationManager = CLLocationManager()
    var radiusDistance: CLLocationDistance = 0.0
    var userRadius: MKCircle?
    var headingImageView: UIImageView?
    var userDirection: CLLocationDirection?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapGeolocation.showsUserLocation = true
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        }
        
        mapGeolocation.delegate = self
        mapGeolocation.mapType = .standard
        mapGeolocation.isZoomEnabled = true
        mapGeolocation.isScrollEnabled = true
        mapGeolocation.showsCompass = true
        mapGeolocation.userTrackingMode = .followWithHeading
        
        getLocationData()
    }
    @IBAction func setRadiusButtonTappe(_ sender: Any) {
        self.radiusDistance = Double(userRadiusTextField.text!) ?? 0.0
        guard let coord = locationManager.location?.coordinate else { return }
        print(coord)
        drawUserRadius(location: coord, radius: self.radiusDistance)
    }
    
    func addPolygon(locations: [CLLocation]) {
        var location = locations.map { $0.coordinate }
        let polyline = MKPolygon(coordinates: &location, count: location.count)
        mapGeolocation.addOverlay(polyline)
        let centerPolygon = centerPolygonCoordinate(location)
        
        for loc in self.locData {
            mapGeolocation.addAnnotation(TestAnotations(coordinate: centerPolygon, title: loc.nama!))
        }
    }
}

extension MapGeolocationViewController: CLLocationManagerDelegate, MKMapViewDelegate {
    
    func getLocationData() {
        if let path = Bundle.main.path(forResource: "location", ofType: "json") {
//            print(path)
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [[[String: AnyObject]]]
                
                if let jsonRes = jsonResult?[0] {
                    let data = try JSONSerialization.data(withJSONObject: jsonRes, options: .fragmentsAllowed)
                    let decode = try JSONDecoder().decode([LocationData].self, from: data)
                    self.locData = decode
                    for index in 0..<self.locData.count {
                        guard let coord =  self.locData[index].koordinat else { return }
                        var arrloc: [CLLocation] = []
                        for loc in coord {
                            let cloc = CLLocation(latitude: loc.lat!, longitude: loc.lng!)
                            arrloc.append(cloc)
                        }
                        addPolygon(locations: arrloc)
                    }
                    self.radiusDistance = 10.0
                }
            } catch(let error) {
                print(error.localizedDescription)
            }
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = manager.location?.coordinate {
            
            let span = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
            let region = MKCoordinateRegion(center: location, span: span)
            mapGeolocation.setRegion(region, animated: true)
            drawUserRadius(location: location, radius: self.radiusDistance)
            updateHeadingRotation()
            let getUserRadiusPoints = userRadiusPoints(coordinate: location, radius: self.radiusDistance)
            for point in getUserRadiusPoints {
                while userInsidePolygon(userlocation: point) == true {
                    let alert = UIAlertController(title: "Notif Area Presensi", message: "Anda bisa presensi di area ini", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alert.addAction(ok)
                    self.present(alert, animated: true, completion: nil)

                    break
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for view in views where view.annotation is MKUserLocation {
            addUserDirection(to: view)
        }
    }
    
    func addUserDirection(to annotationView: MKAnnotationView) {
        let headingImage = UIImage(named: "icon_userDirection")!
        let headingImageView = UIImageView(image: headingImage)
        headingImageView.frame = CGRect(x: (annotationView.frame.size.width - headingImage.size.width)/2, y: (annotationView.frame.size.height - headingImage.size.height)/2 - 18, width: headingImage.size.width, height: headingImage.size.height)
        annotationView.insertSubview(headingImageView, at: 0)
        headingImageView.isHidden = false
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        print("NEW HEADING: ", newHeading)
        if newHeading.headingAccuracy < 0 { return }
        let heading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        userDirection = heading
//        NotificationCenter.default.post(name: Notification.Name(rawValue: "userHeading"), object: self, userInfo: nil)
    }
    
    func updateHeadingRotation() {
        if let heading = locationManager.heading?.trueHeading,
            let headingImageView = headingImageView {
            headingImageView.isHidden = false
            let rotation = CGFloat(heading/180 * .pi)
            headingImageView.transform = CGAffineTransform(rotationAngle: rotation)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolygon {
            let renderer = MKPolygonRenderer(polygon: overlay as! MKPolygon)
            renderer.fillColor = UIColor.green.withAlphaComponent(0.25)
            renderer.strokeColor = UIColor(red: 34/255, green: 139/255, blue: 34/255, alpha: 1.0)
            renderer.lineWidth = 1
            
            return renderer
            
        } else if overlay is MKCircle {
            let circle = MKCircleRenderer(overlay: overlay)
            circle.fillColor = UIColor.blue.withAlphaComponent(0.15)
            circle.lineWidth = 1
            
            return circle
        }
        return MKOverlayRenderer()
    }
    
    func userInsidePolygon(userlocation: CLLocationCoordinate2D ) -> Bool {
        var containsPoint: Bool = false
        let overlays = self.mapGeolocation.overlays
        for overlay in overlays where overlay is MKPolygon {

            let polygon =  overlay as! MKPolygon
            let polygonPath = CGMutablePath()
            let arrPoints = polygon.points()
            for index in 0..<polygon.pointCount {
                
                let polygonMapPoint: MKMapPoint = arrPoints[index]
                let polygonCoordinate = polygonMapPoint.coordinate
                let polygonPoint = mapGeolocation.convert(polygonCoordinate, toPointTo: mapGeolocation)
                
                if (index == 0) {
                    polygonPath.move(to: CGPoint(x: polygonPoint.x, y: polygonPoint.y))
                } else {
                    polygonPath.addLine(to: CGPoint(x: polygonPoint.x, y: polygonPoint.y))
                }
            }
            let mapPointAsCGP: CGPoint = self.mapGeolocation.convert(userlocation, toPointTo: self.mapGeolocation)
            containsPoint =  polygonPath.contains(mapPointAsCGP)
            if containsPoint {
                return true
            }
        }
        return containsPoint
    }
    
    func drawUserRadius(location: CLLocationCoordinate2D, radius: CLLocationDistance) {
        userRadius = MKCircle(center: location, radius: radius)
        for overlay in mapGeolocation.overlays {
            if overlay is MKCircle {
                mapGeolocation.removeOverlay(overlay)
                mapGeolocation.addOverlay(userRadius!)
            } else {
                mapGeolocation.addOverlay(userRadius!)
            }
        }
    }
    
    func centerPolygonCoordinate(_ locationPoints: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        var xPoint: Float = 0.0
        var yPoint: Float = 0.0
        var zPoint: Float = 0.0
        for point in locationPoints {
            let lat = GLKMathDegreesToRadians(Float(point.latitude))
            let long = GLKMathDegreesToRadians(Float(point.longitude))
            
            xPoint += cos(lat) * cos(long)
            yPoint += cos(lat) * sin(long)
            zPoint += sin(lat)
        }
        
        xPoint /= Float(locationPoints.count)
        yPoint /= Float(locationPoints.count)
        zPoint /= Float(locationPoints.count)
        let longitude = atan2(yPoint, xPoint)
        let centralSquare = sqrt(xPoint * xPoint + yPoint * yPoint)
        let latitude = atan2(zPoint, centralSquare)
        let result = CLLocationCoordinate2D(latitude: CLLocationDegrees(GLKMathRadiansToDegrees(Float(latitude))), longitude: CLLocationDegrees(GLKMathRadiansToDegrees(Float(longitude))))
        
        return result
    }
    
    func getRadiusPoints() -> [CLLocationCoordinate2D] {
        for overlay in mapGeolocation.overlays where overlay is MKCircle {
            return userRadiusPoints(coordinate: overlay.coordinate, radius: radiusDistance)
        }
        
        return []
    }
    
    func userRadiusPoints(coordinate: CLLocationCoordinate2D, radius: CLLocationDistance) -> [CLLocationCoordinate2D] {
        var points: [CLLocationCoordinate2D] = []
        let globeRadius = 6378137.0
        let lat = coordinate.latitude * .pi / 180.0
        let lng = coordinate.longitude * .pi / 180.0

        var t: Double = 0
        while t <= 2 * .pi {
            let pointLat = lat + (radius / globeRadius) * sin(t)
            let pointLng = lng + (radius / globeRadius) * cos(t)

            let point = CLLocationCoordinate2D(latitude: pointLat * 180 / .pi, longitude: pointLng * 180 / .pi)
            points.append(point)
            t += 0.3
        }

        return points
    }
}
