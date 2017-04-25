//
//  ViewController.swift
//  GoogleMapPolyLine
//
//  Created by Boominadha Prakash on 20/04/17.
//  Copyright © 2017 Boomi. All rights reserved.
//

import UIKit
import Foundation
import GoogleMaps
import GooglePlaces
import CoreLocation

class ViewController: UIViewController, GMSMapViewDelegate {

    @IBOutlet weak var gmapview: GMSMapView!
    let locationManager = CLLocationManager()
    var originMarker:GMSMarker!
    var destinationMarker:GMSMarker!
    var originAddress:String!
    var destinationAddress:String!
    var source_target:CLLocationCoordinate2D!
    var dest_target:CLLocationCoordinate2D!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let source_location = CLLocation(latitude: <SOURCE LATITUDE>, longitude: <SOURCE LONGITUDE>)
        let dest_location = CLLocation(latitude: <DESTINATION LATITUDE>, longitude: <DESTINATION LONGITUDE>)
        source_target = CLLocationCoordinate2D(latitude: source_location.coordinate.latitude, longitude: source_location.coordinate.longitude)
        dest_target = CLLocationCoordinate2D(latitude: dest_location.coordinate.latitude, longitude: dest_location.coordinate.longitude)
        self.gmapview.camera = GMSCameraPosition.camera(withTarget: source_target, zoom: 14.0)
        self.callGoogleServiceToGetRouteDataFromSource(sourceLocation: source_location, destinationLocation: dest_location, onMap: gmapview)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        gmapview.isMyLocationEnabled = true
        gmapview.settings.myLocationButton = true
        locationManager.startUpdatingLocation()
        print("Location update")
        gmapview.delegate=self
        gmapview.settings.allowScrollGesturesDuringRotateOrZoom = false
        print("Location is:\(locationManager.location)")
        if locationManager.location != nil
        {
            let camera = GMSCameraPosition.camera(withLatitude: locationManager.location!.coordinate.latitude, longitude: locationManager.location!.coordinate.longitude, zoom: 10)
            self.gmapview.camera = camera
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func callGoogleServiceToGetRouteDataFromSource(sourceLocation:CLLocation, destinationLocation: CLLocation, onMap:GMSMapView)
    {

        let urlstring = "https://maps.googleapis.com/maps/api/directions/json?origin=\(destinationLocation.coordinate.latitude),\(destinationLocation.coordinate.longitude)&destination=\(sourceLocation.coordinate.latitude),\(sourceLocation.coordinate.longitude)&sensor=false"
        let encodeurl = NSURL(string: urlstring)
        
        let task = URLSession.shared.dataTask(with: encodeurl! as URL) { (data, response, error) -> Void in
            do {
                if data != nil{
                    let dic = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableLeaves) as! NSDictionary
                    print("Dictionary:\(dic)")
            
                    let routesArray = (dic.value(forKey: "routes") as? Array) ?? []
                    let routes = routesArray.first as? Dictionary<String, AnyObject> ?? [:]
                    let legs = (routes as NSDictionary).object(forKey: "legs") as! Array<Dictionary<NSObject, AnyObject>>
                    self.originAddress = ((legs as NSArray).object(at: 0) as AnyObject).value(forKey: "start_address") as! String
                    self.destinationAddress = ((legs as NSArray).object(at: legs.count-1) as AnyObject).value(forKey: "end_address") as! String
                    let overviewPolyline = (routes["overview_polyline"] as? Dictionary<String, AnyObject>) ?? [:]
                    let polypoints = (overviewPolyline["points"] as? String) ?? ""
                    let line = polypoints
                    
                    self.performSelector(onMainThread: #selector(ViewController.addPolyLine(encodedString:)), with: line, waitUntilDone: true)
                }
                
            }catch {
                print("Error")
            }
        }
        task.resume()
    }
    
    func addPolyLine(encodedString: String)
    {
        self.originMarker = GMSMarker(position: self.source_target)
        self.originMarker.map = self.gmapview
        self.originMarker.icon = GMSMarker.markerImage(with: UIColor.green)
        self.originMarker.title = self.originAddress
        
        self.destinationMarker = GMSMarker(position: self.dest_target)
        self.destinationMarker.map = self.gmapview
        self.destinationMarker.icon = GMSMarker.markerImage(with: UIColor.red)
        self.destinationMarker.title = self.destinationAddress
        
        let point1:MKMapPoint = MKMapPointForCoordinate(originMarker.position)
        let point2:MKMapPoint = MKMapPointForCoordinate(destinationMarker.position)
        
        let mapViewWidth = self.gmapview.frame.size.width
        let mapViewHeight = self.gmapview.frame.size.height
        
        let centerPoint = MKMapPointMake((point1.x + point2.x) / 2, (point1.y + point2.y)/2)
        let centerLocation:CLLocationCoordinate2D = MKCoordinateForMapPoint(centerPoint)
        
        let mapScaleWidth:Double = Double(Double(mapViewWidth) / Double(fabs(point2.x - point1.x)))
        let mapScaleHeight:Double = Double(Double(mapViewHeight) / Double(fabs(point2.y - point1.y)))
        let mapScale = min(mapScaleWidth, mapScaleHeight)
        
        let zoomLevel = 19 + log2(mapScale)
        self.gmapview.camera = GMSCameraPosition.camera(withLatitude: centerLocation.latitude, longitude: centerLocation.longitude, zoom: Float(zoomLevel))
        
        let path = GMSMutablePath(fromEncodedPath: encodedString)
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 5
        polyline.strokeColor = .blue
        polyline.map = gmapview
    }


}

extension ViewController: CLLocationManagerDelegate {
    
    private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        //Checking whether Current location is enabled in GPS or not.
        
        if status == .authorizedAlways {
            print("Running always")
            locationManager.startUpdatingLocation()
            gmapview.isMyLocationEnabled = true
            gmapview.settings.myLocationButton = true
        }
        else if status == .authorizedWhenInUse
        {
            print("Running when in use")
            locationManager.startUpdatingLocation()
            gmapview.isMyLocationEnabled = true
            gmapview.settings.myLocationButton = true
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        if let location = locations.first
        {
            
            print("currLat:",location.coordinate.latitude)
            print("CurrLong:",location.coordinate.longitude)
            let currentLat = location.coordinate.latitude
            let currentLong = location.coordinate.longitude
            
            if currentLat != 0.0 && currentLong != 0.0
            {
                gmapview.camera = GMSCameraPosition(target: CLLocationCoordinate2DMake(currentLat, currentLat), zoom: 14, bearing: 0, viewingAngle: 0)
            }
            
            self.locationManager.stopUpdatingLocation()
        }
    }
}

