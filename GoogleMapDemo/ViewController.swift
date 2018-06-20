//
//  ViewController.swift
//  GoogleMapDemo
//
//  Created by Pradip Kikani on 20/06/18.
//  Copyright © 2018 Pradip Kikani. All rights reserved.
//

import UIKit
import GoogleMaps
/// Point of Interest Item which implements the GMUClusterItem protocol.
class POIItem: NSObject, GMUClusterItem {
    var position: CLLocationCoordinate2D
    var name: String!
    
    init(position: CLLocationCoordinate2D, name: String) {
        self.position = position
        self.name = name
    }
}

let kClusterItemCount = 10000
let kCameraLatitude = -33.8
let kCameraLongitude = 151.2


class ViewController: UIViewController {
    private var clusterManager: GMUClusterManager!

    @IBOutlet weak var mapView: GMSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        let camera = GMSCameraPosition.camera(withLatitude: kCameraLatitude, longitude:kCameraLongitude, zoom: 10.0)
//        mapView.camera = camera
        let sessionManager = SessionManager()
        let start = CLLocationCoordinate2D(latitude: 37.778483, longitude: -122.513960)
        let end = CLLocationCoordinate2D(latitude: 37.706753, longitude: -122.418677)
        
        sessionManager.requestDirections(from: start, to: end, completionHandler: { (path, error) in
            
            if let error = error {
                print("Something went wrong, abort drawing!\nError: \(error)")
            } else {
                // Create a GMSPolyline object from the GMSPath
                let polyline = GMSPolyline(path: path!)
                polyline.strokeWidth = 5.0
                // Add the GMSPolyline object to the mapView
                polyline.map = self.mapView
                // Move the camera to the polyline
                let bounds = GMSCoordinateBounds(path: path!)
                self.showMarker(position: start)
                self.showMarker(position: end)

                let cameraUpdate = GMSCameraUpdate.fit(bounds, with: UIEdgeInsets(top: 40, left: 15, bottom: 10, right: 15))
                self.mapView.animate(with: cameraUpdate)
            }
            
        })
        
        //MARK: For Clustering Code
        /*let iconGenerator = GMUDefaultClusterIconGenerator()
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        let renderer = GMUDefaultClusterRenderer(mapView: mapView, clusterIconGenerator: iconGenerator)
        clusterManager = GMUClusterManager(map: mapView, algorithm: algorithm, renderer: renderer)
        generateClusterItems()
        clusterManager.cluster()
        clusterManager.setDelegate(self, mapDelegate: self)*/
    }

     //MARK: For Show Pin.
   func showMarker(position: CLLocationCoordinate2D){
        let marker = GMSMarker()
        marker.position = position
        marker.title = "Palo Alto"
        marker.snippet = "San Francisco"
        marker.map = mapView
    }
    
    //MARK: For Add Clustering Map Pin.
    private func generateClusterItems() {
        let extent = 0.2
        for index in 1...kClusterItemCount {
            let lat = kCameraLatitude + extent * randomScale()
            let lng = kCameraLongitude + extent * randomScale()
            let name = "Item \(index)"
            let item = POIItem(position: CLLocationCoordinate2DMake(lat, lng), name: name)
            clusterManager.add(item)
        }
    }
    private func randomScale() -> Double {
        return Double(arc4random()) / Double(UINT32_MAX) * 2.0 - 1.0
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


extension ViewController: GMSMapViewDelegate,GMUClusterManagerDelegate{
    /* handles Info Window tap */
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        print("didTapInfoWindowOf")
    }
    
    /* handles Info Window long press */
    func mapView(_ mapView: GMSMapView, didLongPressInfoWindowOf marker: GMSMarker) {
        print("didLongPressInfoWindowOf")
    }
    
    /* set a custom Info Window */
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        let view = UIView(frame: CGRect.init(x: 0, y: 0, width: 200, height: 70))
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 6
        
        let lbl1 = UILabel(frame: CGRect.init(x: 8, y: 8, width: view.frame.size.width - 16, height: 15))
        lbl1.text = "Hi there!"
        view.addSubview(lbl1)
        
        let lbl2 = UILabel(frame: CGRect.init(x: lbl1.frame.origin.x, y: lbl1.frame.origin.y + lbl1.frame.size.height + 3, width: view.frame.size.width - 16, height: 15))
        lbl2.text = "I am a custom info window."
        lbl2.font = UIFont.systemFont(ofSize: 14, weight: .light)
        view.addSubview(lbl2)
        
        return view
    }
    
    func clusterManager(_ clusterManager: GMUClusterManager, didTap cluster: GMUCluster) -> Bool {
        let newCamera = GMSCameraPosition.camera(withTarget: cluster.position,
                                                 zoom: mapView.camera.zoom + 1)
        let update = GMSCameraUpdate.setCamera(newCamera)
        mapView.moveCamera(update)
        return false
    }
    
}

class SessionManager {
    let GOOGLE_DIRECTIONS_API_KEY = "AIzaSyAXbUam9Gx3VA1ViKE40fkgfWr4Muk2UY0"
    
    func requestDirections(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, completionHandler: @escaping ((_ response: GMSPath?, _ error: Error?) -> Void)) {
        
      
        //        guard let url = URL(string: "https://maps.googleapis.com/maps/api/directions/json?origin=\(start.latitude),\(start.longitude)&destination=\(end.latitude),\(end.longitude)&key=\(GOOGLE_DIRECTIONS_API_KEY)") else {

        guard let url = URL(string: "https://maps.googleapis.com/maps/api/directions/json?origin=\(start.latitude),\(start.longitude)&destination=\(end.latitude),\(end.longitude)&sensor=true") else {
            let error = NSError(domain: "LocalDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create object URL"])
            print("Error: \(error)")
            completionHandler(nil, error)
            return
        }
        
        // Set up the session
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let task = session.dataTask(with: url) { (data, response, error) in
            // Check if there is an error.
            guard error == nil else {
                DispatchQueue.main.async {
                    print("Google Directions Request Error: \((error!)).")
                    completionHandler(nil, error)
                }
                return
            }
            
            // Make sure data was received.
            guard let data = data else {
                DispatchQueue.main.async {
                    let error = NSError(domain: "GoogleDirectionsRequest", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to receive data"])
                    print("Error: \(error).")
                    completionHandler(nil, error)
                }
                return
            }
            do {
                // Convert data to dictionary.
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    DispatchQueue.main.async {
                        let error = NSError(domain: "GoogleDirectionsRequest", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON to Dictionary"])
                        print("Error: \(error).")
                        completionHandler(nil, error)
                    }
                    return
                }
                
                // Check if the the Google Direction API returned a status OK response.
                guard let status: String = json["status"] as? String, status == "OK" else {
                    DispatchQueue.main.async {
                        let error = NSError(domain: "GoogleDirectionsRequest", code: 3, userInfo: [NSLocalizedDescriptionKey: "Google Direction API did not return status OK"])
                        print("Error: \(error).")
                        completionHandler(nil, error)
                    }
                    return
                }
                // We only need the 'points' key of the json dictionary that resides within.
                if let routes: [Any] = json["routes"] as? [Any], routes.count > 0, let routes0: [String: Any] = routes[0] as? [String: Any], let overviewPolyline: [String: Any] = routes0["overview_polyline"] as? [String: Any], let points: String = overviewPolyline["points"] as? String {
                    // We need the get the first object of the routes array (route0), then route0's overview_polyline and finally overview_polyline's points object.
                    
                    if let path: GMSPath = GMSPath(fromEncodedPath: points) {
                        DispatchQueue.main.async {
                            completionHandler(path, nil)
                        }
                        return
                    } else {
                        DispatchQueue.main.async {
                            let error = NSError(domain: "GoogleDirections", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to create GMSPath from encoded points string."])
                            completionHandler(nil, error)
                        }
                        return
                    }
                } else {
                    DispatchQueue.main.async {
                        let error = NSError(domain: "GoogleDirections", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse overview polyline's points"])
                        completionHandler(nil, error)
                    }
                    return
                }
            } catch let error as NSError  {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
        }
        task.resume()
    }
}
