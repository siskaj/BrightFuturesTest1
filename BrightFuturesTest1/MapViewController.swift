//
//  ViewController.swift
//  BrightFuturesTest1
//
//  Created by Jaromir on 16.01.15.
//  Copyright (c) 2015 Baltoro. All rights reserved.
//

import UIKit
import MapKit
import BrightFutures


class MapViewController: UIViewController {

	@IBOutlet weak var mapView: MKMapView!

	
	var srcItem: MKMapItem!
	var destItem: MKMapItem!
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		mapView.delegate = self
		
		let PragueCoord = CLLocationCoordinate2D(latitude: 50.08, longitude: 14.4)
		let BrnoCoord = CLLocationCoordinate2D(latitude: 49.2, longitude: 16.6)
		
		let srcMark = MKPlacemark(coordinate: PragueCoord, addressDictionary: nil)
		let destMark = MKPlacemark(coordinate: BrnoCoord, addressDictionary: nil)
		
		srcItem = MKMapItem(placemark: srcMark)
		destItem = MKMapItem(placemark: destMark)
		
		
		let aRoute = obtainRouteFrom(srcItem, to: destItem)
		aRoute.onComplete(context: Queue.main) {  result in
			switch result {
			case .Success(let route):
				self.setupRoute(route.value)
			case .Failure(let err):
				println("Error - \(err)")
			default:
				break
			}
		}

	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


	func obtainRouteFrom(from: MKMapItem, to: MKMapItem) -> Future<MKRoute> {
		let promise = Promise<MKRoute>()
		
		let request = MKDirectionsRequest()
		request.setSource(from)
		request.setDestination(to)
		request.transportType = .Automobile
		
		let directions = MKDirections(request: request)
		directions.calculateDirectionsWithCompletionHandler { (response: MKDirectionsResponse!, error: NSError!) in
			var outError: NSError?
			if response != nil && response.routes.count > 0 {
				promise.success(response.routes[0] as MKRoute)
			} else {
				if error != nil {
					promise.failure(error)
				} else {
					outError = NSError(domain: "com.baltoro.BrightFuturesTest1", code: 404, userInfo:[NSLocalizedDescriptionKey : "No routes found!"])
					promise.failure(outError!)
				}
			}
		}
		return promise.future
	}

	func setupRoute(route: MKRoute) {
		let pl = route.polyline
		if pl != nil {
			mapView.addOverlay(pl!)
		}
		
		var points = [MKMapPoint]()
		var mapPoint = MKMapPointForCoordinate(srcItem.placemark.coordinate)
		points.append(mapPoint)
		mapPoint = MKMapPointForCoordinate(destItem.placemark.coordinate)
		points.append(mapPoint)
		
		var boundingRegion = CoordinateRegionBoundingMapPoints(points)
		boundingRegion.span.latitudeDelta *= 1.1
		boundingRegion.span.longitudeDelta *= 1.1
		
		mapView.setRegion(boundingRegion, animated: true)

	}
	
	func CoordinateRegionBoundingMapPoints(points: [MKMapPoint]) -> MKCoordinateRegion {
  if (points.count == 0) {
		return MKCoordinateRegionForMapRect(MKMapRectWorld)
  }
		
  let mapSizeZero = MKMapSizeMake(0.0, 0.0)
		
  var boundingMapRect = MKMapRect(origin: points[0], size: mapSizeZero)
		
  for point in points {
		if (!MKMapRectContainsPoint(boundingMapRect, point)) {
			boundingMapRect = MKMapRectUnion(boundingMapRect, MKMapRect(origin: point, size: mapSizeZero))
		}
  }
		
  var region = MKCoordinateRegionForMapRect(boundingMapRect)
  region.span.latitudeDelta = max(region.span.latitudeDelta, 0.001)
  region.span.longitudeDelta = max(region.span.longitudeDelta, 0.001)
		
  return region
	}

}

//MARK: MapViewDelegate
extension MapViewController: MKMapViewDelegate {
	func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
		if let polylineOverlay = overlay as? MKPolyline {
			let renderer = MKPolylineRenderer(polyline: polylineOverlay)
			renderer.strokeColor = UIColor.blueColor()
			renderer.lineWidth = 2.0
			return renderer
		}
		return nil
	}
}

