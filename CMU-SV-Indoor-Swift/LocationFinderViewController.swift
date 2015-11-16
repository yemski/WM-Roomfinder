//
//  LocationFinderViewController.swift
//  CMU-SV-Indoor-Swift
//
//  Created by Jon Baron on 11/12/15.
//  Copyright © 2015 CMU-SV. All rights reserved.
//

import UIKit
import Parse
import Bolts

class LocationFinderViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var locations: [PFObject]!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
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
        
        cell.cellBtn.tag = indexPath.row
        
        cell.cellBtn.addTarget(self, action: "setglobalVariable", forControlEvents: .TouchUpInside)
        
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
    
    @IBAction func setglobalVariable (sender: UIButton)
    {
    }

    @IBAction func gotomapBtn(sender: AnyObject)
    {
        
        
        
        
        //let markerfromModal =  as? String
        performSegueWithIdentifier("seguetoMap", sender: self)
        
    }
}
