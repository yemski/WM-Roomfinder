//
//  MapViewController.swift
//  CMU-SV-Indoor-Swift
//
//  Created by xxx on 12/2/14.
//  Copyright (c) 2014 CMU-SV. All rights reserved.
//

import UIKit
import Parse
import Bolts

let marker = GMSMarker()
let marker1 = GMSMarker()
let marker2 = GMSMarker()
let marker3 = GMSMarker()
//var markerfromModal: String?


class MapViewController: UIViewController,
    UITableViewDataSource,
UITableViewDelegate,
GMSMapViewDelegate, GPSPositionerDelegate, IndoorPositionerDelegate

{
    
    // MARK: Properties
    
    @IBOutlet var mapView: GMSMapView!
    @IBOutlet var currentBuildingLabel: UILabel!
    @IBOutlet var indoorPositionerStateLabel: UILabel!
    @IBOutlet var indoorOutdoorButton: UIBarButtonItem!
    @IBOutlet var myFloorNumberButton: UIBarButtonItem!
    @IBOutlet var myPositionButton: UIBarButtonItem!
    @IBOutlet var viewFloorNumberButton: UIBarButtonItem!
    @IBOutlet var mapTypeButton: UIBarButtonItem!
    var groundOverlays: [String: GMSGroundOverlay] = [:]
    
    var indoorPositioningTurnedOn = false
    
    var currentIndoorCoordinate = CLLocationCoordinate2DMake(0, 0)
    var currentGPSCoordinate = CLLocationCoordinate2DMake(0, 0)
    var currentHeading = CLLocationDirection(0)
    
    var cameraMode: CameraMode  = .free
    enum CameraMode {
        case free
        case centerPosition
        case centerPositionAndLockHeading
    }
    var settingCameraPosition = false
    
    var myPositionMarker = GMSMarker()
    
    var gpsLocationCircle = GMSCircle(position: CLLocationCoordinate2DMake(0, 0), radius: 1.0)

    var gpsPositioner: GPSPositioner!
    var indoorPositioner: MyIndoorPositioner!
    
    var currentBuilding = Building.None
    var currentFloor = Floor.Floor1
    var currentViewFloor = Floor.Floor1
    
    
    @IBOutlet weak var modalView: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var locations: [PFObject]!
    
    // MARK: Functional Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locations = []
        
        var query = PFQuery(className: "rooms")
        query.orderByAscending("Room_Name")
        query.findObjectsInBackgroundWithBlock { (locations: [PFObject]?, error: NSError?) -> Void in
            print("got the locations")
            print(locations)
            self.locations = locations
            self.tableView.reloadData()
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        
        //tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 120
        
        initializeGoogleMapView()
        initializeFloorplanImages()
        initializePositionMarkersAndCircles()
        initializeGPSAndIndoorPositioners()
        
        
        //
        //let item = tableView.cellForRowAtIndexPath(indexPath)!.textLabel!.text!
        
        
        
        //Place markers on the GMS overlay
        marker.opacity = 0
        marker.position = CLLocationCoordinate2DMake(37.6270541, -122.4246236)
        marker.title = "Conference Room A"
        marker.snippet = "Capacity: 50"
        marker.map = mapView
        
        
        let marker1 = GMSMarker()
        marker1.opacity = 0
        marker1.position = CLLocationCoordinate2DMake(37.6269824, -122.4245814)
        marker1.title = "Conference Room B"
        marker1.snippet = "Capacity: 75"
        marker1.map = mapView
        
        let marker2 = GMSMarker()
        marker2.opacity = 0
        marker2.position = CLLocationCoordinate2DMake(37.6271279, -122.4243682)
        marker2.title = "Learning Lab"
        marker2.snippet = "Capacity: 45"
        marker2.map = mapView
        
        let marker3 = GMSMarker()
        marker3.opacity = 0
        marker3.position = CLLocationCoordinate2DMake(37.6269601, -122.4244446)
        marker3.title = "Restroom"
        marker3.snippet = ""
        marker3.map = mapView
    }
    
    
    
    
    
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
        print("locations.count = \(locations.count)")
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // let cell = tableView.dequeueReusableCellWithIdentifier("LocationResultsCell", forIndexPath: indexPath) as! LocationResultsCell
        
        //let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        
        
        
        var cell = tableView.dequeueReusableCellWithIdentifier("LocationResultsCell") as! LocationResultsCell
        
        
        //cell.nameLabel.text = self.locations
        
        //cell.cellBtn.tag = indexPath.row
        
        //cell.cellBtn.addTarget(self, action: "setglobalVariable", forControlEvents: .TouchUpInside)
        
        var location = locations[indexPath.row]
        
        cell.nameLabel.text = location["Room_Name"] as? String
        
        
        let building = location["Building"] as? String
        
        if building == "SB850C" {
            cell.buildingsAddressLabel.text = "850 Cherry Ave., San Bruno"
        } else if building == "SB860E" {
            cell.buildingsAddressLabel.text = "860 Elm Ave., San Bruno"
        } else if building == "SV850C" {
            cell.buildingsAddressLabel.text = "850 California Ave., Sunnyvale"
        } else if building == "SV850C" {
            cell.buildingsAddressLabel.text = "840 California Ave., Sunnyvale"
        }
        
        let onFloor = location["Floor"] as? Int
        if onFloor != nil {
            cell.floorNumberLabel.text = "Floor: \(location["Floor"])"
        } else if onFloor == nil {
            cell.floorNumberLabel.text = "Floor unknown"
            cell.floorNumberLabel.textColor = UIColor.lightGrayColor()
        }
        
        let isRoom = location["isRoom"] as! Bool
        let isAvailable = location["Available_now"] as? Bool
        let hasCapacity = location["Capacity"] as? Int
        
        if isRoom == true {
            cell.locationTypeImageView.image = UIImage(named: "room icon")
            
            if isAvailable != nil && isAvailable == true {
                cell.roomAvailabilityLabel.text = "Available Now"
                cell.roomAvailabilityLabel.textColor = UIColor.greenColor()
            } else if isAvailable != nil && isAvailable == false {
                cell.roomAvailabilityLabel.text = "Not Available"
                cell.roomAvailabilityLabel.textColor = UIColor.redColor()
            } else {
                cell.roomAvailabilityLabel.text = "Availability Unknown"
                cell.roomAvailabilityLabel.textColor = UIColor.grayColor()
            }
            
            cell.roomCapacityLabel.text = "Capacity: \(location["Capacity"])"
            cell.roomAvailabilityLabel.alpha = 1
            cell.roomCapacityLabel.alpha = 1
            
        } else {  //if isRoom is false, then we're assuming it's a person. Could there be other types to capture? would we want to return the person's title, if available? any other data for people?
            cell.locationTypeImageView.image = UIImage(named: "person icon")
            cell.roomAvailabilityLabel.alpha = 0
            cell.roomCapacityLabel.alpha = 0
        }
        
        
        return cell
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("seguetoMap" , sender: self)
    }

    
    private func initializeGoogleMapView() {
        mapView.settings.compassButton = true
        let camera: GMSCameraPosition = GMSCameraPosition.cameraWithLatitude(INIT_CAM_LAT, longitude: INIT_CAM_LON, zoom: INIT_CAM_ZOOM)
        mapView.camera = camera
        mapView.delegate = self
    }
    
    private func initializeFloorplanImages() {
        let BSB_1f_image: UIImage! = UIImage(named: "Assets/Floorplans/sb-1stfloorplan.png")
        let b23_1f_image: UIImage! = UIImage(named: "Assets/Floorplans/B23-1F.png")
        let b23_2f_image: UIImage! = UIImage(named: "Assets/Floorplans/B23-2F.png")

        let BSB_1f_overlay: GMSGroundOverlay =
            GMSGroundOverlay(position: BSB_COORD, icon: BSB_1f_image, zoomLevel: BSB_SCALE)
        let b23_1f_overlay: GMSGroundOverlay =
            GMSGroundOverlay(position: B23_COORD, icon: b23_1f_image, zoomLevel: B23_SCALE)
        let b23_2f_overlay: GMSGroundOverlay =
            GMSGroundOverlay(position: B23_COORD, icon: b23_2f_image, zoomLevel: B23_SCALE)
        
        BSB_1f_overlay.bearing = BSB_BEARING;
        b23_1f_overlay.bearing = B23_BEARING;
        b23_2f_overlay.bearing = B23_BEARING;
        
        BSB_1f_overlay.map = mapView;
        b23_1f_overlay.map = mapView;
        
        groundOverlays[BSB_1F] = BSB_1f_overlay
        groundOverlays[B23_1F] = b23_1f_overlay
        groundOverlays[B23_2F] = b23_2f_overlay
        
        for buildingInfo in BUILDINGS_ARRAY.values {
            let circle = GMSCircle(position: buildingInfo.coordinate, radius: buildingInfo.range)
            circle.fillColor = UIColor.grayColor().colorWithAlphaComponent(0.15)
            circle.strokeColor = UIColor.whiteColor()
            circle.zIndex = -1
            circle.map = mapView
        }
    

    }
    
    private func initializePositionMarkersAndCircles() {
        myPositionMarker.icon = UIImage(named: "MyPositionMarker@2x.png")
        myPositionMarker.groundAnchor = CGPointMake(0.5, 0.5)
        myPositionMarker.flat = true
        myPositionMarker.rotation = 90
        myPositionMarker.zIndex = 3
        myPositionMarker.map = mapView
        
        gpsLocationCircle.fillColor = blueColor.colorWithAlphaComponent(0.15)
        gpsLocationCircle.strokeWidth = 0
        gpsLocationCircle.zIndex = 1
        gpsLocationCircle.map = mapView
    }
    
    private func initializeGPSAndIndoorPositioners() {
        gpsPositioner = GPSPositioner()
        gpsPositioner.parentViewController = self
        gpsPositioner.delegate = self
        
        indoorPositioner = MyIndoorPositioner()
        indoorPositioner.parentViewController = self
        indoorPositioner.delegate = self
    }

    private func centerCameraToCurrentCoordinate() {
        settingCameraPosition = true
        if indoorPositioningTurnedOn {
            mapView.animateToLocation(currentIndoorCoordinate)
        } else {
            mapView.animateToLocation(currentGPSCoordinate)
        }
    }
    
    private func rotateCameraToCurrentHeading() {
        settingCameraPosition = true
        mapView.animateToBearing(currentHeading)
    }
    
    private func turnOnIndoorPositioning() {
        if currentBuilding != .None {
            indoorPositioningTurnedOn = true
            
            indoorOutdoorButton.tintColor = blueColor
            indoorOutdoorButton.image = UIImage(named: "Indoor.png")
            
            switch currentBuilding {
            case .BuildingSB:
                currentBuildingLabel.text = "BSB"
                currentFloor = Floor.Floor1
                myFloorNumberButton.title = "1F"
                myFloorNumberButton.enabled = false
            default:
                currentBuildingLabel.text = "B23"
                myFloorNumberButton.enabled = true
            }
            
            self.startPositioningWith(newBuilding: currentBuilding, newFloor: currentFloor)
        }
    }
    
    private func turnOffIndoorPositioning() {
        indoorPositioningTurnedOn = false
        
        indoorOutdoorButton.tintColor = darkGreyColor
        indoorOutdoorButton.image = UIImage(named: "Outdoor.png")
        
        self.indoorPositioner.stopPositioning()
    }
    
    private func changedFloorOrBuilding(building building: Building, floor: Floor) {
        shakeDevice()
        
        if building == .None {
            currentBuilding = .None
            
            turnOffIndoorPositioning()
            indoorOutdoorButton.enabled = false
            currentBuildingLabel.text = ""
            
            return
        }
        
        indoorOutdoorButton.enabled = true
        
        switch building {
        case .BuildingSB:
            // Building 19 can only be positioned on 1st floor
            // building has just changed to BuildingSB
            myFloorNumberButton.enabled = false

            currentBuilding = .BuildingSB
            currentFloor = .Floor1
            
            myFloorNumberButton.title = "1F"
            currentBuildingLabel.text = "BSB"
            
            if indoorPositioningTurnedOn {
                startPositioningWith(newBuilding: currentBuilding, newFloor: currentFloor)
            }
        default:
            myFloorNumberButton.enabled = true
            if building != currentBuilding || floor != currentFloor {
                if building != currentBuilding {
                    currentBuilding = building
                    switch building {
                    case .None:
                        currentBuildingLabel.text = ""
                    case .BuildingSB:
                        currentBuildingLabel.text = "BSB"
                    case .Building23:
                        currentBuildingLabel.text = "B23"
                    }
                }
                if floor != currentFloor {
                    currentFloor = floor
                    switch floor {
                    case .Floor1:
                        myFloorNumberButton.title = "1F"
                    case .Floor2:
                        myFloorNumberButton.title = "2F"
                    default:
                        failGracefully("Cannot position with none floor")
                    }
                }
                viewFloor(floor)
                if indoorPositioningTurnedOn {
                    startPositioningWith(newBuilding: building, newFloor: floor)
                }
            }
        }
    }
    
    private func startPositioningWith(newBuilding newBuilding: Building, newFloor: Floor) {
        indoorPositioner.startPositioning(building: newBuilding, floor: newFloor)
    }
    
    private func viewFloor(floor: Floor) {
        if floor == currentFloor {
            viewFloorNumberButton.tintColor = UIColor.blackColor()
        } else {
            viewFloorNumberButton.tintColor = UIColor.redColor()
        }
        
        
        switch floor {
        case .None:
            viewFloorNumberButton.title = "N/A"
            groundOverlays[BSB_1F]!.map = nil
            groundOverlays[B23_1F]!.map = nil
            groundOverlays[B23_2F]!.map = nil
        case .Floor1:
            viewFloorNumberButton.title = "1F"
            groundOverlays[BSB_1F]!.map = self.mapView
            groundOverlays[B23_1F]!.map = self.mapView
            groundOverlays[B23_2F]!.map = nil
        case .Floor2:
            viewFloorNumberButton.title = "2F"
            groundOverlays[BSB_1F]!.map = nil
            groundOverlays[B23_1F]!.map = nil
            groundOverlays[B23_2F]!.map = self.mapView
        default:
            failGracefully("No such floor!")
        }
    }
    
    
    
    // MARK: GMSMapViewDelegate Methods
    
    func mapView(mapView: GMSMapView!, didChangeCameraPosition position: GMSCameraPosition!) {
        if settingCameraPosition == false {
            cameraMode = .free
            myPositionMarker.icon = UIImage(named: "MyPositionMarker.png")
            myPositionButton.image = UIImage(named: "MyPosition.png")
            myPositionButton.tintColor = darkGreyColor
        } else {
        }
    }
    
    func mapView(mapView: GMSMapView!, idleAtCameraPosition position: GMSCameraPosition!) {
        mapView.userInteractionEnabled = true
        settingCameraPosition = false;
    }
    
    // MARK: ( Method used to read floorplan image alignment marker coordinates )

    /*
     * When there is a constant bias between indoor position given by IndoorAtlas and real position, 
     * do the following steps to make floorplan adjustments on IndoorAtlas:
     * 
     * 1. Modify func initializeFloorplanImages() and/or related global constants to load flooplan images with alignment markers.
     * 2. Uncomment this function, run it on a simulator (e.g. iPhone 6 Plus) other than a real device.
     * 3. Click the center of any marker on the any floorplan image to read the coordiantes.
     * 4. Adjust the coordiantes on IndoorAtlas server.
     * 5. Recomment this function. Re-modify this app to load original floorplan images without alignment markers.
     */
    
  
    func mapView(mapView: GMSMapView!, didTapAtCoordinate coordinate: CLLocationCoordinate2D) {
        let lattitude = String(format: "%.7f", coordinate.latitude)
        let longitude = String(format: "%.7f", coordinate.longitude)

        print("Tapped at \(lattitude), \(longitude)")
        
    }
    
    
    
    
    // MARK: GPSPositionerDelegate Methods

    func didStartGPSPositioning() {
        print("Did Start GPS Positioning.")
    }
    
    func didStopGPSPositioning() {
        print("Did Stop GPS Positioning.")
    }
    
    func didUpdateLocation(coordinate coordinate: CLLocationCoordinate2D, radius: CLLocationAccuracy) {
        currentGPSCoordinate = coordinate
        
        if !indoorPositioningTurnedOn {
            myPositionMarker.position = coordinate
            
            if cameraMode != .free {
                centerCameraToCurrentCoordinate()
            }
        }
    
        gpsLocationCircle.position = coordinate
        gpsLocationCircle.radius = radius
        

        
        // Determine current building and restart indoor positioning if building change
        var closestDistance = CLLocationDistanceMax
        var closestBuilding: Building!
        for aBuilding in BUILDINGS_ARRAY.keys {
            let distance = distanceInMetersBetween(coordinate, right: BUILDINGS_ARRAY[aBuilding]!.coordinate)
            BUILDINGS_ARRAY[aBuilding]!.distance = distance
            if distance < closestDistance {
                closestDistance = distance
                closestBuilding = aBuilding
            }
        }
        
        let newBuilding =
        closestDistance <= BUILDINGS_ARRAY[closestBuilding]!.range ? closestBuilding : Building.None
        
        if currentBuilding != newBuilding {
            changedFloorOrBuilding(building: newBuilding, floor: currentFloor)
        }
    }
    
    func didUpdateHeading(heading: CLHeading) {
        currentHeading = heading.trueHeading > 0 ? heading.trueHeading: heading.magneticHeading
        
        myPositionMarker.rotation = currentHeading
        
        if cameraMode == .centerPositionAndLockHeading {
            rotateCameraToCurrentHeading()
        }
    }
    
    
    
    // MARK: IndoorPositionerDelegate Methods

    func indoorPositionerStateChanged(state: String) {
        if indoorPositioningTurnedOn {
            indoorPositionerStateLabel.backgroundColor = blueColor.colorWithAlphaComponent(0.8)
            indoorPositionerStateLabel.text = "IDP (On): " + state
        } else {
            indoorPositionerStateLabel.backgroundColor = UIColor.grayColor().colorWithAlphaComponent(0.8)
            indoorPositionerStateLabel.text = "IDP (Off): " + state
        }
    }
    
    func indoorPositioningStopped() {
        if cameraMode != .free {
            centerCameraToCurrentCoordinate()
        }
    }
    
    func indoorPositionerFailed() {
        turnOffIndoorPositioning()
    }
    
    func indoorPositionChanged(coordinate: CLLocationCoordinate2D, radius: CLLocationAccuracy) {
        currentIndoorCoordinate = coordinate

        if indoorPositioningTurnedOn {
            myPositionMarker.position = coordinate
            
            if cameraMode != .free {
                centerCameraToCurrentCoordinate()
            }
        }
    }

    
    
    // MARK: IBActions
    
    @IBAction func didTapIndoorOutdoorButton(sender: AnyObject) {
        if !indoorPositioningTurnedOn {
            turnOnIndoorPositioning()
        } else {
            turnOffIndoorPositioning()
        }
    }
    
    @IBAction func didTapMyFloorNumberButton(sender: AnyObject) {
        let alertController: UIAlertController = UIAlertController(title: "I am currently on floor:", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        let onFloor1 = UIAlertAction(title: "1F (Ground Floor)", style: UIAlertActionStyle.Default, handler: { [unowned self] (UIAlertAction) in
            
            self.changedFloorOrBuilding(building: self.currentBuilding, floor: Floor.Floor1)
        })
        
        let onFloor2 = UIAlertAction(title: "2F", style: UIAlertActionStyle.Default, handler: { [unowned self] (UIAlertAction) in
            
            self.changedFloorOrBuilding(building: self.currentBuilding, floor: Floor.Floor2)
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Destructive, handler: nil)
        
        alertController.addAction(onFloor1)
        alertController.addAction(onFloor2)
        alertController.addAction(cancel)
        
        self.presentViewController(alertController, animated: false, completion: nil)
    }
    
    @IBAction func didTapMyPositionButton(sender: AnyObject) {
        if cameraMode == .free {
            cameraMode = .centerPosition
            myPositionButton.image = UIImage(named: "MyPosition.png")
            myPositionButton.tintColor = blueColor
        
            mapView.userInteractionEnabled = false
            centerCameraToCurrentCoordinate()
        } else if cameraMode == .centerPosition {
            // Disable manual scrolling or roation
            mapView.settings.scrollGestures = false
            mapView.settings.rotateGestures = false
            
            cameraMode = .centerPositionAndLockHeading
            myPositionMarker.icon = UIImage(named: "MyPositionMarkerLockHeading.png")
            myPositionButton.image = UIImage(named: "MyPositionLockHeading.png")
            myPositionButton.tintColor = blueColor
            
            rotateCameraToCurrentHeading()
        } else if cameraMode == .centerPositionAndLockHeading {
            // Enable manual scrolling or roation
            mapView.settings.scrollGestures = true
            mapView.settings.rotateGestures = true
            
            cameraMode = .free
            myPositionMarker.icon = UIImage(named: "MyPositionMarker.png")
            myPositionButton.image = UIImage(named: "MyPosition.png")
            myPositionButton.tintColor = darkGreyColor
        }
    }
    
    @IBAction func didTapViewFloorNumberButton(sender: AnyObject) {
       let alertController: UIAlertController = UIAlertController(title: "View floor:", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        let viewNoFloor = UIAlertAction(title: "None", style: UIAlertActionStyle.Default, handler: {
            [unowned self] (UIAlertAction) in       self.viewFloor(.None)
        })
        
        let viewFloor1 = UIAlertAction(title: "1F", style: UIAlertActionStyle.Default, handler: {
            [unowned self] (UIAlertAction) in       self.viewFloor(.Floor1)
        })
        
        let viewFloor2 = UIAlertAction(title: "2F", style: UIAlertActionStyle.Default, handler: {
            [unowned self] (UIAlertAction) in       self.viewFloor(.Floor2)
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)

        alertController.addAction(viewNoFloor)
        alertController.addAction(viewFloor1)
        alertController.addAction(viewFloor2)
        alertController.addAction(cancel)
        
        self.presentViewController(alertController, animated: false, completion: nil)
    }
    
    @IBAction func didTapMapTypeButton(sender: AnyObject) {
        let alertController: UIAlertController = UIAlertController(title: "Map Type:", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        let normalMapType = UIAlertAction(title: "Normal", style: UIAlertActionStyle.Default, handler: { [unowned self] (UIAlertAction) in
            
            self.mapView.mapType = kGMSTypeNormal
            self.mapTypeButton.title = "Normal"
        })
        
        let satelliteMapType = UIAlertAction(title: "Satellite", style: UIAlertActionStyle.Default, handler: { [unowned self] (UIAlertAction) in
            
            self.mapView.mapType = kGMSTypeSatellite
            self.mapTypeButton.title = "Satellite"
        })
        
        let hybridMapType = UIAlertAction(title: "Hybrid", style: UIAlertActionStyle.Default, handler: { [unowned self] (UIAlertAction) in
            
            self.mapView.mapType = kGMSTypeHybrid
            self.mapTypeButton.title = "Hybrid"
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Destructive, handler: nil)
        
        alertController.addAction(normalMapType);
        alertController.addAction(satelliteMapType);
        alertController.addAction(hybridMapType);
        alertController.addAction(cancel);
        
        self.presentViewController(alertController, animated: false, completion: nil)
    }
    
    @IBAction func didTapSearchbutton(sender: AnyObject) {
        //print("Tapped search button")
        
        UIView.animateWithDuration(0.3, animations: {
            self.modalView.alpha = 0.8
            
        })

    }

    
    @IBAction func bckmapBtn(sender: AnyObject) {
        
       //let name = tableView.cellForRowAtIndexPath.String.nameLabel
        
        
            marker.opacity = 1
            marker1.opacity = 0
            marker2.opacity = 0
            marker3.opacity = 0
            UIView.animateWithDuration(0.3, animations: {
                self.modalView.alpha = 0
                
            })
        

        
        }
        
        
        
        

    }
    
    


