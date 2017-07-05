//
//  SettingsViewController.swift
//  RSuite-Geofence
//
//  Created by Christina Tsangouri on 6/26/17.
//  Copyright © 2017 Christina Tsangouri. All rights reserved.
//

import UIKit
import ResearchKit
import ResearchSuiteTaskBuilder
import Gloss
import ResearchSuiteAppFramework

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var store: GeofenceStore!
    @IBOutlet weak var backButton: UIBarButtonItem!
    var workLocationSurvey: RSAFScheduleItem!
    var homeLocationSurvey: RSAFScheduleItem!
    var items: [String] = ["","Reset your Home Location", "","Reset your Work Location","", "Sign out"];
    var resultAddress : String = ""
    let appDelegate = UIApplication.shared.delegate as? AppDelegate

    
    
    @IBOutlet
    var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.store = GeofenceStore()
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let deselectedCell = tableView.cellForRow(at: indexPath)!
        deselectedCell.backgroundColor = UIColor.clear
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "cell")!
        
        let homeLocation = self.store.valueInState(forKey: "home_location") as! String
        let workLocation = self.store.valueInState(forKey: "work_location") as! String
        
        NSLog("locations")
        NSLog(homeLocation)
        NSLog(workLocation)

     
        if indexPath.row == 0 || indexPath.row == 2 || indexPath.row == 4 {
            cell.textLabel?.textColor = UIColor.black
            cell.backgroundColor = UIColor.init(red:0.95, green:0.95, blue:0.95, alpha:1.0)

            if indexPath.row == 0 {
                cell.textLabel?.text = ""
            }
            if indexPath.row == 2 {
                cell.textLabel?.text = homeLocation
            }
            if indexPath.row == 4 {
                cell.textLabel?.text = workLocation
            }
            
        }
        else {
            cell.textLabel?.text = self.items[indexPath.row]
            cell.textLabel?.textColor = UIColor.init(colorLiteralRed: 1.00, green: 0.47, blue: 0.30, alpha: 1.0)

        }
   
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.row == 0 || indexPath.row == 2 || indexPath.row == 4 {
            return 40.0
        }
        else {
             return 60.0
        }
        
     
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NSLog(String(describing: indexPath.row))
        tableView.deselectRow(at: indexPath, animated: true)
        
        
        if indexPath.row == 1 {
            self.launchHomeLocationSurvey()
        }
        
        if indexPath.row == 3 {
            self.launchWorkLocationSurvey()
        }
        
        if indexPath.row == 5 {
            self.signOut()
        }
        
    }
    
    func launchHomeLocationSurvey() {
        self.homeLocationSurvey = AppDelegate.loadScheduleItem(filename: "homeLocation")
        self.launchActivity(forItem: (self.homeLocationSurvey)!)

    }
    
    func launchWorkLocationSurvey() {
        self.workLocationSurvey = AppDelegate.loadScheduleItem(filename: "workLocation")
        self.launchActivity(forItem: (self.workLocationSurvey)!)

    }
    
    func launchActivity(forItem item: RSAFScheduleItem) {
        
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let steps = appDelegate.taskBuilder.steps(forElement: item.activity as JsonElement) else {
                return
        }
        
        let task = ORKOrderedTask(identifier: item.identifier, steps: steps)
        
        let taskFinishedHandler: ((ORKTaskViewController, ORKTaskViewControllerFinishReason, Error?) -> ()) = { [weak self] (taskViewController, reason, error) in
            //when finised, if task was successful (e.g., wasn't canceled)
            //process results
            if reason == ORKTaskViewControllerFinishReason.completed {
                let taskResult = taskViewController.result
                appDelegate.resultsProcessor.processResult(taskResult: taskResult, resultTransforms: item.resultTransforms)
                
                
                if item.identifier == "location_survey_work" {
                    let result = taskResult.stepResult(forStepIdentifier: "work_location_step")
                    let locationAnswer = result?.firstResult as? ORKLocationQuestionResult
                    let resultCoord = locationAnswer?.locationAnswer?.coordinate
                    let resultDictionary = locationAnswer?.locationAnswer?.addressDictionary
                    
                    self?.resultAddress = ""
                    var resultAddressParts : [String] = []
                    
                    if resultDictionary?.index(forKey: "Name") != nil {
                        let name = resultDictionary?["Name"] as! String
                        resultAddressParts.append(name)
                    }
                    if resultDictionary?.index(forKey: "City") != nil {
                        let city = resultDictionary?["City"] as! String
                        resultAddressParts.append(",")
                        resultAddressParts.append(" ")
                        resultAddressParts.append(city)
                    }
                    if resultDictionary?.index(forKey: "State") != nil {
                        let state = resultDictionary?["State"] as! String
                        resultAddressParts.append(",")
                        resultAddressParts.append(" ")
                        resultAddressParts.append(state)
                    }
                    if resultDictionary?.index(forKey: "ZIP") != nil {
                        let zip = resultDictionary?["ZIP"] as! String
                        resultAddressParts.append(",")
                        resultAddressParts.append(" ")
                        resultAddressParts.append(zip)

                    }
                    
                    
                    for i in resultAddressParts {
                        self?.resultAddress = (self?.resultAddress)! + i
                    }
                    
                    self?.store.setValueInState(value: self!.resultAddress as NSSecureCoding , forKey: "work_location")
                    
                    self?.store.setValueInState(value: resultCoord!.latitude as NSSecureCoding, forKey: "work_coordinate_lat")
                    self?.store.setValueInState(value: resultCoord!.latitude as NSSecureCoding, forKey: "work_coordinate_long")
                    
                    DispatchQueue.main.async{
                        self?.tableView.reloadData()
                    }
                    
                    self?.appDelegate?.updateMonitoredRegions(regionChanged: "work")
                }
                
                if item.identifier == "location_survey_home" {
                    let result = taskResult.stepResult(forStepIdentifier: "home_location_step")
                    let locationAnswer = result?.firstResult as? ORKLocationQuestionResult
                    let resultCoord = locationAnswer?.locationAnswer?.coordinate
                    let resultDictionary = locationAnswer?.locationAnswer?.addressDictionary
                    
                    self?.resultAddress = ""
                    var resultAddressParts : [String] = []
                    
                    if resultDictionary?.index(forKey: "Name") != nil {
                        let name = resultDictionary?["Name"] as! String
                        resultAddressParts.append(name)
                    }
                    if resultDictionary?.index(forKey: "City") != nil {
                        let city = resultDictionary?["City"] as! String
                        resultAddressParts.append(",")
                        resultAddressParts.append(" ")
                        resultAddressParts.append(city)
                    }
                    if resultDictionary?.index(forKey: "State") != nil {
                        let state = resultDictionary?["State"] as! String
                        resultAddressParts.append(",")
                        resultAddressParts.append(" ")
                        resultAddressParts.append(state)
                    }
                    if resultDictionary?.index(forKey: "ZIP") != nil {
                        let zip = resultDictionary?["ZIP"] as! String
                        resultAddressParts.append(",")
                        resultAddressParts.append(" ")
                        resultAddressParts.append(zip)
                        
                    }
                    
                    
                    for i in resultAddressParts {
                        self?.resultAddress = (self?.resultAddress)! + i
                    }
                    
                    self?.store.setValueInState(value: self!.resultAddress as NSSecureCoding , forKey: "home_location")
                    
                    self?.store.setValueInState(value: resultCoord!.latitude as NSSecureCoding, forKey: "home_coordinate_lat")
                    self?.store.setValueInState(value: resultCoord!.latitude as NSSecureCoding, forKey: "home_coordinate_long")
                    
                    DispatchQueue.main.async{
                        self?.tableView.reloadData()
                    }
                    
                    self?.appDelegate?.updateMonitoredRegions(regionChanged: "home")

                }
                
                
            }
            
            self?.dismiss(animated: true,completion: nil)
            
            
        }
        
        let tvc = RSAFTaskViewController(
            activityUUID: UUID(),
            task: task,
            taskFinishedHandler: taskFinishedHandler
        )
        
        self.present(tvc, animated: true, completion: nil)
    }

    
    func signOut() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.signOut()
        
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    

    

}
