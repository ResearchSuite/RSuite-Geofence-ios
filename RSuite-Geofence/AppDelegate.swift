//
//  AppDelegate.swift
//  RSuite-Geofence
//
//  Created by Christina Tsangouri on 6/26/17.
//  Copyright © 2017 Christina Tsangouri. All rights reserved.
//

import UIKit
import OhmageOMHSDK
import ResearchSuiteTaskBuilder
import ResearchSuiteResultsProcessor
import ResearchSuiteAppFramework
import Gloss
import sdlrkx
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var store: GeofenceStore!
    var ohmageManager: OhmageOMHManager!
    var taskBuilder: RSTBTaskBuilder!
    var resultsProcessor: RSRPResultsProcessor!
    var locationManager: CLLocationManager!
    let distance: NSNumber = 150
    let nameHome: String = "home"
    let nameWork: String = "work"
    var locationRegionHome: CLCircularRegion!
    var locationRegionWork: CLCircularRegion!

    
    func initializeOhmage(credentialsStore: OhmageOMHSDKCredentialStore) -> OhmageOMHManager {
        
        //load OMH client application credentials from OMHClient.plist
        guard let file = Bundle.main.path(forResource: "OMHClient", ofType: "plist") else {
            fatalError("Could not initialze OhmageManager")
        }
        
        
        let omhClientDetails = NSDictionary(contentsOfFile: file)
        
        guard let baseURL = omhClientDetails?["OMHBaseURL"] as? String,
            let clientID = omhClientDetails?["OMHClientID"] as? String,
            let clientSecret = omhClientDetails?["OMHClientSecret"] as? String else {
                fatalError("Could not initialze OhmageManager")
        }
        
        if let ohmageManager = OhmageOMHManager(baseURL: baseURL,
                                                clientID: clientID,
                                                clientSecret: clientSecret,
                                                queueStorageDirectory: "ohmageSDK",
                                                store: credentialsStore) {
            return ohmageManager
        }
        else {
            fatalError("Could not initialze OhmageManager")
        }
        
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.store = GeofenceStore()
        self.ohmageManager = self.initializeOhmage(credentialsStore: self.store)
        
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.startUpdatingLocation()
        
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            self.locationManager.startMonitoringSignificantLocationChanges()
        }
    
        self.taskBuilder = RSTBTaskBuilder(
            stateHelper: self.store,
            elementGeneratorServices: AppDelegate.elementGeneratorServices,
            stepGeneratorServices: AppDelegate.stepGeneratorServices,
            answerFormatGeneratorServices: AppDelegate.answerFormatGeneratorServices
        )
        
        self.resultsProcessor = RSRPResultsProcessor(
            frontEndTransformers: AppDelegate.resultsTransformers,
            backEnd: ORBEManager(ohmageManager: self.ohmageManager)
        )
        
    //        self.store.setValueInState(value: "" as NSSecureCoding, forKey: "home_location")
//        self.store.setValueInState(value: "" as NSSecureCoding, forKey: "work_location")
    self.showViewController(animated: false)
        
        
        return true
    }
    
    open func signOut() {
        
        self.ohmageManager.signOut { (error) in
            
            self.store.reset()
            
            DispatchQueue.main.async {
                self.showViewController(animated: true)
            }
            
        }
    }
    
    open func showViewController(animated: Bool) {
        //if not signed in, go to sign in screen
        if !self.ohmageManager.isSignedIn {
            
            let storyboard = UIStoryboard(name: "Onboarding", bundle: Bundle.main)
            let vc = storyboard.instantiateInitialViewController()
            self.transition(toRootViewController: vc!, animated: animated)

            
        }
        else {
            
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let vc = storyboard.instantiateInitialViewController()
            self.transition(toRootViewController: vc!, animated: animated)
            
        }
    }
    
    open class var stepGeneratorServices: [RSTBStepGenerator] {
        return [
            RSTBLocationStepGenerator(),
            CTFOhmageLoginStepGenerator(),
            RSTBInstructionStepGenerator(),
            RSTBTextFieldStepGenerator(),
            RSTBIntegerStepGenerator(),
            RSTBDecimalStepGenerator(),
            RSTBTimePickerStepGenerator(),
            RSTBFormStepGenerator(),
            RSTBDatePickerStepGenerator(),
            RSTBSingleChoiceStepGenerator(),
            RSTBMultipleChoiceStepGenerator(),
            RSTBBooleanStepGenerator(),
            RSTBPasscodeStepGenerator(),
            RSTBScaleStepGenerator()
        ]
    }
    
    open class var answerFormatGeneratorServices:  [RSTBAnswerFormatGenerator] {
        return [
            RSTBLocationStepGenerator(),
            RSTBTextFieldStepGenerator(),
            RSTBSingleChoiceStepGenerator(),
            RSTBIntegerStepGenerator(),
            RSTBDecimalStepGenerator(),
            RSTBTimePickerStepGenerator(),
            RSTBDatePickerStepGenerator(),
            RSTBScaleStepGenerator()
        ]
    }
    
    open class var elementGeneratorServices: [RSTBElementGenerator] {
        return [
            RSTBElementListGenerator(),
            RSTBElementFileGenerator(),
            RSTBElementSelectorGenerator()
        ]
    }
    
    open class var resultsTransformers: [RSRPFrontEndTransformer.Type] {
        return [
            YADLFullRaw.self,
            YADLSpotRaw.self,
            CTFBARTSummaryResultsTransformer.self,
            CTFDelayDiscountingRawResultsTransformer.self
        ] //super.resultsProcessorFrontEndTransformers
    }
    
    /**
     Convenience method for transitioning to the given view controller as the main window
     rootViewController.
     */
    open func transition(toRootViewController: UIViewController, animated: Bool, completion: ((Bool) -> Swift.Void)? = nil) {
        guard let window = self.window else { return }
        if (animated) {
            let snapshot:UIView = (self.window?.snapshotView(afterScreenUpdates: true))!
            toRootViewController.view.addSubview(snapshot);
            
            self.window?.rootViewController = toRootViewController;
            
            UIView.animate(withDuration: 0.3, animations: {() in
                snapshot.layer.opacity = 0;
            }, completion: {
                (value: Bool) in
                snapshot.removeFromSuperview()
                completion?(value)
            })
        }
        else {
            window.rootViewController = toRootViewController
            completion?(true)
        }
    }
    
    //utilities
    static func loadSchedule(filename: String) -> RSAFSchedule? {
        guard let json = AppDelegate.getJson(forFilename: filename) as? JSON else {
            return nil
        }
        
        return RSAFSchedule(json: json)
    }
    
    static func loadScheduleItem(filename: String) -> RSAFScheduleItem? {
        guard let json = AppDelegate.getJson(forFilename: filename) as? JSON else {
            return nil
        }
        
        return RSAFScheduleItem(json: json)
    }
    
    static func loadActivity(filename: String) -> JSON? {
        return AppDelegate.getJson(forFilename: filename) as? JSON
    }
    
    static func getJson(forFilename filename: String, inBundle bundle: Bundle = Bundle.main) -> JsonElement? {
        
        guard let filePath = bundle.path(forResource: filename, ofType: "json")
            else {
                assertionFailure("unable to locate file \(filename)")
                return nil
        }
        
        guard let fileContent = try? Data(contentsOf: URL(fileURLWithPath: filePath))
            else {
                assertionFailure("Unable to create NSData with content of file \(filePath)")
                return nil
        }
        
        let json = try! JSONSerialization.jsonObject(with: fileContent, options: JSONSerialization.ReadingOptions.mutableContainers)
        
        return json as JsonElement?
    }
    
    // Location Manager
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        
        NSLog("updated location received")
        NSLog(String(describing: locations))
        
        // location updates here
        
      
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion){
        
        // updates when entered any of the 2 defined regions
        
        let logicalLocation = LogicalLocationSample()
        logicalLocation.locationName = region.identifier
        logicalLocation.action = LogicalLocationSample.Action.enter
        
        logicalLocation.acquisitionSourceCreationDateTime = Date()
        logicalLocation.acquisitionModality = .Sensed
        logicalLocation.acquisitionSourceName = "edu.cornell.tech.foundry.OhmageOMHSDK.Geofence"
        
        NSLog("entered region")
        
        self.ohmageManager.addDatapoint(datapoint: logicalLocation, completion: { (error) in
            
            debugPrint(error)
            
        })

    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region:CLRegion){
        
        // updates when exit any of the 2 defined regions
        
        NSLog("exited region")
        
        let logicalLocation = LogicalLocationSample()
        logicalLocation.locationName = region.identifier
        logicalLocation.action = LogicalLocationSample.Action.exit
        
        logicalLocation.acquisitionSourceCreationDateTime = Date()
        logicalLocation.acquisitionModality = .Sensed
        logicalLocation.acquisitionSourceName = "edu.cornell.tech.foundry.OhmageOMHSDK.Geofence"
        
        self.ohmageManager.addDatapoint(datapoint: logicalLocation, completion: { (error) in
            
            debugPrint(error)
            
        })
    }
    
    func updateMonitoredRegions (regionChanged: String) {
        
        NSLog("start monitoring updated locations")
  
        if(regionChanged == "home"){
            
            // Stop monitoring old region
            
            let coordinateHomeLatOld = self.store.valueInState(forKey: "saved_region_lat_home") as! CLLocationDegrees
            let coordinateHomeLongOld = self.store.valueInState(forKey: "saved_region_long_home") as! CLLocationDegrees
            let radiusHomeOld = self.store.valueInState(forKey: "saved_region_distance_home") as! Double
            let coordinateHomeOld = CLLocationCoordinate2D(latitude: coordinateHomeLatOld, longitude: coordinateHomeLongOld)
            
            let locationRegionHomeOld = CLCircularRegion(center: coordinateHomeOld, radius: radiusHomeOld, identifier: nameHome as String)
            self.locationManager.stopMonitoring(for: locationRegionHomeOld)
            
            // Start monitoring new region
            
            let coordinateHomeLat = self.store.valueInState(forKey: "home_coordinate_lat") as! CLLocationDegrees
            let coordinateHomeLong = self.store.valueInState(forKey: "home_coordinate_long") as! CLLocationDegrees
            let coordinateHome = CLLocationCoordinate2D(latitude: coordinateHomeLat, longitude: coordinateHomeLong)
 
            self.locationRegionHome = CLCircularRegion(center: coordinateHome, radius: distance.doubleValue, identifier: nameHome as String)
            self.locationManager.startMonitoring(for:locationRegionHome)
            
            self.store.setValueInState(value: locationRegionHome.center.latitude as NSSecureCoding, forKey: "saved_region_lat_home")
            self.store.setValueInState(value: locationRegionHome.center.longitude as NSSecureCoding, forKey: "saved_region_long_home")
            self.store.setValueInState(value: distance.doubleValue as NSSecureCoding, forKey: "saved_region_distance_home")
            
            self.locationManager.startMonitoringVisits()
            
            
            
        }
        
        if(regionChanged == "work"){
            
            // Stop monitoring old region
            
            let coordinateWorkLatOld = self.store.valueInState(forKey: "saved_region_lat_work") as! CLLocationDegrees
            let coordinateWorkLongOld = self.store.valueInState(forKey: "saved_region_long_work") as! CLLocationDegrees
            let radiusWorkOld = self.store.valueInState(forKey: "saved_region_distance_work") as! Double
            let coordinateWorkOld = CLLocationCoordinate2D(latitude: coordinateWorkLatOld, longitude: coordinateWorkLongOld)
            
            let locationRegionWorkOld = CLCircularRegion(center: coordinateWorkOld, radius: radiusWorkOld, identifier: nameWork as String)
            
            self.locationManager.stopMonitoring(for: locationRegionWorkOld)

            
            // Start monitoring new region
            
            let coordinateWorkLat = self.store.valueInState(forKey: "work_coordinate_lat") as! CLLocationDegrees
            let coordinateWorkLong = self.store.valueInState(forKey: "work_coordinate_long") as! CLLocationDegrees
            let coordinateWork = CLLocationCoordinate2D(latitude: coordinateWorkLat, longitude: coordinateWorkLong)
            
            self.locationRegionWork = CLCircularRegion(center: coordinateWork, radius: distance.doubleValue, identifier: nameWork as String)
            self.locationManager.startMonitoring(for:locationRegionWork)
            
            self.store.setValueInState(value: locationRegionWork.center.latitude as NSSecureCoding, forKey: "saved_region_lat_work")
            self.store.setValueInState(value: locationRegionWork.center.longitude as NSSecureCoding, forKey: "saved_region_long_work")
            self.store.setValueInState(value: distance.doubleValue as NSSecureCoding, forKey: "saved_region_distance_work")
            
            self.locationManager.startMonitoringVisits()

            
            
        }
        
        if(regionChanged == "both"){
            if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self){
                
                            
                // 1. Home
                
                let coordinateHomeLat = self.store.valueInState(forKey: "home_coordinate_lat") as! CLLocationDegrees
                let coordinateHomeLong = self.store.valueInState(forKey: "home_coordinate_long") as! CLLocationDegrees
                let coordinateHome = CLLocationCoordinate2D(latitude: coordinateHomeLat, longitude: coordinateHomeLong)
                
                self.locationRegionHome = CLCircularRegion(center: coordinateHome, radius: distance.doubleValue, identifier: nameHome as String)
                self.locationManager.startMonitoring(for:locationRegionHome)
                
                self.store.setValueInState(value: locationRegionHome.center.latitude as NSSecureCoding, forKey: "saved_region_lat_home")
                self.store.setValueInState(value: locationRegionHome.center.longitude as NSSecureCoding, forKey: "saved_region_long_home")
                self.store.setValueInState(value: distance.doubleValue as NSSecureCoding, forKey: "saved_region_distance_home")

                
                
                // 2. Work
                
                let coordinateWorkLat = self.store.valueInState(forKey: "work_coordinate_lat") as! CLLocationDegrees
                let coordinateWorkLong = self.store.valueInState(forKey: "work_coordinate_long") as! CLLocationDegrees
                let coordinateWork = CLLocationCoordinate2D(latitude: coordinateWorkLat, longitude: coordinateWorkLong)
                
                self.locationRegionWork = CLCircularRegion(center: coordinateWork, radius: distance.doubleValue, identifier: nameWork as String)
                self.locationManager.startMonitoring(for:locationRegionWork)
                
                self.store.setValueInState(value: locationRegionWork.center.latitude as NSSecureCoding, forKey: "saved_region_lat_work")
                self.store.setValueInState(value: locationRegionWork.center.longitude as NSSecureCoding, forKey: "saved_region_long_work")
                self.store.setValueInState(value: distance.doubleValue as NSSecureCoding, forKey: "saved_region_distance_work")
                
                self.locationManager.startMonitoringVisits()
                
            }
            
        }
        
  
        
        
    }


}

