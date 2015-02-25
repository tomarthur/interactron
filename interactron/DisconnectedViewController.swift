//
//  DisconnectedViewController.swfit
//  interactron
//
//  Created by Tom Arthur on 2/16/15.
//  Copyright (c) 2015 Tom Arthur. All rights reserved.
//
//  Adapted from:
//  DisconnectedViewController.swift
//  Cool Beans
//  Created by Kyle on 11/14/14.
//  Copyright (c) 2014 Kyle Weiner. All rights reserved. 
//  Cool Beans is MIT Licensed.
//

import UIKit
import IJReachability

class DisconnectedViewController: UIViewController, PTDBeanManagerDelegate {
    
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var settingsButton: UIButton!
    
    var bluetoothIsReady = false
    var isConnecting = false
    var haltConnections = false
    var automaticMode = false
    
    var nearbyBLEInteractives = [String:PTDBean]()      // PTDBean objects detected in the area
    var connectedBeanObjectID: String?                  // Parse objectId for connected bean
    
    
    var manager: PTDBeanManager!
    var connectedBean: PTDBean? {
        didSet {
            if connectedBean == nil {
                self.beanManagerDidUpdateState(manager)
                updateStatusInterface()

            } else {
                // present connected view when beacon connection established
                let connectedViewController:ConnectedViewController = ConnectedViewController(nibName: "ConnectedView", bundle: nil)
                
                //Pass identifers to connectedVC
                connectedViewController.connectedBean = connectedBean
                connectedViewController.foundInteractiveObjectID = connectedBeanObjectID

                presentViewController(connectedViewController, animated: true, completion: nil)
                
                activityIndicator.stopAnimating()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get notification when user wants to end experience
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "endInteraction:",
            name: "EndInteraction", object: nil)
      
        // when datastore and bluetooth are ready
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "startScanningForInteractives:",
            name: "readyToFind", object: nil)
        
        // TO DO: Combine following two alerts to one function
        // when iBeacon of interactive is detected or manually selected on settings view
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "initiateConnectionFromRequest:",
            name: "startInteractionRequest", object: nil)
        // when iBeacon of interactive is detected or manually selected on settings view
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "initiateConnectionFromNotification:",
            name: "startInteractionFromNotification", object: nil)
        
        // when exiting settings view update behaviors
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateMode:",
            name: "updatedMode", object: nil)
        
        // when app is no longer in focus, disconnect
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "endInteraction:",
            name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
        // when app is closing disconnect
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "endInteraction:",
            name: UIApplicationWillTerminateNotification, object: nil)
        
        manager = PTDBeanManager(delegate: self)
        
        self.view.backgroundColor = .ITWelcomeColor()
    }
    
    override func viewDidAppear(animated: Bool) {
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    // MARK: Navigation
    
    @IBAction func settingsButtonPressed(sender: AnyObject) {
        // stop app from connecting while we are in manual control
        haltConnections = true
        
        // disconnect if connected
        if connectedBean != nil {
            manager.disconnectBean(connectedBean, error:nil)
        }
        
        let settingsViewController:SettingsViewController = SettingsViewController(
            nibName: "SettingsView",bundle: nil)
        
        // send current nearby BLE interactives
        settingsViewController.nearbyBLEInteractives = nearbyBLEInteractives
        
        settingsViewController.modalTransitionStyle = .FlipHorizontal
        presentViewController(settingsViewController, animated: true, completion: nil)

    }
    
    func updateStatusInterface() {
        
        if let automaticConnectionStatus = appDelegate.defaults.boolForKey(appDelegate.automaticConnectionKeyConstant) as Bool?
        {
            if automaticConnectionStatus == true {
                automaticMode = true
                activityIndicator.startAnimating()
                status.text = "Discovering Experiences Nearby"
                
            } else {
                automaticMode = false
                activityIndicator.stopAnimating()
                status.text = "Manual Mode: Press Info for Options"
                
            }
        }


    }
    
    func updateMode(notification: NSNotification) {
        
        haltConnections = false
        
        if let automaticConnectionStatus = appDelegate.defaults.boolForKey(appDelegate.automaticConnectionKeyConstant) as Bool?
        {
            if automaticConnectionStatus == true {
                automaticMode = true
                activityIndicator.startAnimating()
                status.text = "Discovering Experiences Nearby"
                
            } else {
                automaticMode = false
                activityIndicator.stopAnimating()
                status.text = "Manual Mode: Press Info for Options"
                
            }
        }
    }
    
    
    // MARK: PTDBeanManagerDelegate
    
    func beanManagerDidUpdateState(beanManager: PTDBeanManager!) {
        switch beanManager.state {
        case .Unsupported:
            UIAlertView(
                title: "Error",
                message: "This device does not support Bluetooth Low Energy.",
                delegate: self,
                cancelButtonTitle: "OK"
                ).show()
        case .Unknown:
            UIAlertView(
                title: "Error",
                message: "This device does is not able to use Bluetooth Low Energy at this time.",
                delegate: self,
                cancelButtonTitle: "OK"
                ).show()
        case .Unauthorized:
            UIAlertView(
                title: "Error",
                message: "Please give permission for Bluetooth in Settings.",
                delegate: self,
                cancelButtonTitle: "OK"
                ).show()
        case .PoweredOff:
            UIAlertView(
                title: "Error",
                message: "Please turn on Bluetooth.",
                delegate: self,
                cancelButtonTitle: "OK"
                ).show()
        case .PoweredOn:
            bluetoothIsReady = true
            NSNotificationCenter.defaultCenter().postNotificationName("readyToFind", object: nil)
        default:
            break
        }
    }
    
    func startScanningForInteractives(notif: NSNotification)
    {
        if appDelegate.dataManager.dataStoreReady == true && bluetoothIsReady == true {
            println("Data is \(appDelegate.dataManager.dataStoreReady) and bluetooth is: \(bluetoothIsReady)")
            self.manager.startScanningForBeans_error(nil)
            updateStatusInterface()
        }
    }
    
    func beanManager(beanManager: PTDBeanManager!, didDiscoverBean bean: PTDBean!, error: NSError!) {

        // add found interactive to dictionary
        if appDelegate.dataManager.isInteractiveKnown(toString(bean.name)) == true {
            
            nearbyBLEInteractives[bean.name] = bean
        }
        
        // automatically connect if enabled, not ignored and app is in forground
        let appState : UIApplicationState = UIApplication.sharedApplication().applicationState
        if appState != UIApplicationState.Active
        {
            if connectedBean == nil && haltConnections == false && automaticMode == true
                && appDelegate.dataManager.isInteractiveIgnored(bean.identifier) == false {
                    
                    intiateConnectionIfInteractionValid(bean)
            }
        }
    }
    

    func BeanManager(beanManager: PTDBeanManager!, didConnectToBean bean: PTDBean!, error: NSError!) {
        println("CONNECTED BEAN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")
        
        if (error != nil){
            UIAlertView(
                title: "Unable to Contact Interactive",
                message: "The experience isn't able to to start. Please try again later.",
                delegate: self,
                cancelButtonTitle: "OK"
                ).show()
            return
        }
        
        if connectedBean == nil {
            connectedBeanObjectID = appDelegate.dataManager.knownInteractivesFromParse[bean.name]
            connectedBean = bean
            isConnecting = false
        }
        
        // TODO: add analytics
    }
    
    func beanManager(beanManager: PTDBeanManager!, didDisconnectBean bean: PTDBean!, error: NSError!) {
        println("DISCONNECTED BEAN \nName: \(bean.name), UUID: \(bean.identifier) RSSI: \(bean.RSSI)")
        
        if (error != nil){
           println("error disconnecting")
           println(error)
        }
        
        // Dismiss any modal view controllers.
        presentedViewController?.dismissViewControllerAnimated(true, completion: { () in
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        
        self.connectedBeanObjectID = nil
        self.connectedBean = nil

    }
    
    func intiateConnectionIfInteractionValid(bean: PTDBean!) {
        if appDelegate.dataManager.isInteractiveKnown(toString(bean.name)) == true {
            if bean.state == .Discovered {
                println("Attempting to connect to \(toString(bean.name))")
                if (isConnecting == false){
                    isConnecting = true
                    
                    activityIndicator.startAnimating()
                    
                    var connectError : NSError?
                    manager.connectToBean(bean, error: &connectError)
                    // TODO: Where is this error going when the device isn't avaialble anylonger? 
                    if (connectError != nil){
                        UIAlertView(
                            title: "Unable to Contact Interactive",
                            message: "The experience isn't able to to start. Please try again later.",
                            delegate: self,
                            cancelButtonTitle: "OK"
                            ).show()
                        return
                    }
                    
                    // tell the user what we've found
                    
                    status.text = "Contacting \(appDelegate.dataManager.knownInteractivesFromParseFriendlyNames[bean.name]!)"
                }
            } else {
                println("ERROR: cant find that bean")
            }
        }
    }
    
    // end interaction by disconnecting and adding to temporary ignore list
    func endInteraction(notification: NSNotification) {
        if connectedBean != nil {
            appDelegate.dataManager.previouslyExperiencedInteractivesToIgnore.append(connectedBean!.identifier!)
            manager.disconnectBean(connectedBean, error:nil)
        }
    }
    
    // handles notification from beacon or settings page that a interaction is requested
    func initiateConnectionFromRequest(notification: NSNotification) {
        if let interactionInfo = notification.userInfo as? Dictionary<String, PTDBean>{
            println(interactionInfo)
            if let id = interactionInfo["beaconInteractionObject"] {
                intiateConnectionIfInteractionValid(id)
            }
        }
    }
    
    // handles notification from beacon or settings page that a interaction is requested
    func initiateConnectionFromNotification(notification: NSNotification) {
        if let interactionInfo = notification.userInfo as? Dictionary<String, String>{
            println(interactionInfo)
            if let id = interactionInfo["beaconInteractionBLEName"] {
                findBeanObjectAndConnectFromBLEName(id)
            }
        }
    }
    
    func findBeanObjectAndConnectFromBLEName(bleName: String) {
        for (nearbyName, bean) in nearbyBLEInteractives {
            if bleName == nearbyName {
                intiateConnectionIfInteractionValid(bean)
            }
        }
    }
    
    
}




