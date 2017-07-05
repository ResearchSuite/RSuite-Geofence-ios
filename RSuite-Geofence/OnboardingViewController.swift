//
//  OnboardingViewController.swift
//  RSuite-Geofence
//
//  Created by Christina Tsangouri on 6/26/17.
//  Copyright © 2017 Christina Tsangouri. All rights reserved.
//

import ResearchKit
import ResearchSuiteTaskBuilder
import Gloss
import ResearchSuiteAppFramework


class OnboardingViewController: UIViewController {
    
    @IBOutlet weak var loginButton: UIButton!
    let delegate = UIApplication.shared.delegate as! AppDelegate
    var locationOnboardingSurvey: RSAFScheduleItem!
    var resultAddressWork : String = ""
    var resultAddressHome : String = ""
    var store: GeofenceStore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.store = GeofenceStore()
        
        let color = UIColor.init(colorLiteralRed: 0.44, green: 0.66, blue: 0.86, alpha: 1.0)
        loginButton.layer.borderWidth = 1.0
        loginButton.layer.borderColor = color.cgColor
        loginButton.layer.cornerRadius = 5
        loginButton.clipsToBounds = true
    }
    
    
    @IBAction func signInTapped(_ sender: Any) {
        
        guard let signInActivity = AppDelegate.loadActivity(filename: "signIn"),
            let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let steps = appDelegate.taskBuilder.steps(forElement: signInActivity as JsonElement) else {
                return
        }
        
        let task = ORKOrderedTask(identifier: "signIn", steps: steps)
        
        let taskFinishedHandler: ((ORKTaskViewController, ORKTaskViewControllerFinishReason, Error?) -> ()) = { [weak self] (taskViewController, reason, error) in
            
            //when done, tell the app delegate to go back to the correct screen
            self?.dismiss(animated: true, completion: {
                self!.locationOnboardingSurvey = AppDelegate.loadScheduleItem(filename: "LocationOnboarding")
                self?.launchActivity(forItem: (self?.locationOnboardingSurvey)!)
                
            })
            
        }
        
        let tvc = RSAFTaskViewController(
            activityUUID: UUID(),
            task: task,
            taskFinishedHandler: taskFinishedHandler
        )
        
        self.present(tvc, animated: true, completion: nil)
        
   
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
                
            
                // work
                
                    var resultWork = taskResult.stepResult(forStepIdentifier: "work_location_step")
                    var locationAnswerWork = resultWork?.firstResult as? ORKLocationQuestionResult
                    var resultCoordWork = locationAnswerWork?.locationAnswer?.coordinate
                    var resultRegionWork = locationAnswerWork?.locationAnswer?.region
                    var resultDictionaryWork = locationAnswerWork?.locationAnswer?.addressDictionary
                    
                    self?.resultAddressWork = ""
                    var resultAddressPartsWork : [String] = []
                    
                    if resultDictionaryWork?.index(forKey: "Name") != nil {
                        let name = resultDictionaryWork?["Name"] as! String
                        resultAddressPartsWork.append(name)
                    }
                    if resultDictionaryWork?.index(forKey: "City") != nil {
                        let city = resultDictionaryWork?["City"] as! String
                        resultAddressPartsWork.append(",")
                        resultAddressPartsWork.append(" ")
                        resultAddressPartsWork.append(city)
                    }
                    if resultDictionaryWork?.index(forKey: "State") != nil {
                        let state = resultDictionaryWork?["State"] as! String
                        resultAddressPartsWork.append(",")
                        resultAddressPartsWork.append(" ")
                        resultAddressPartsWork.append(state)
                    }
                    if resultDictionaryWork?.index(forKey: "ZIP") != nil {
                        let zip = resultDictionaryWork?["ZIP"] as! String
                        resultAddressPartsWork.append(",")
                        resultAddressPartsWork.append(" ")
                        resultAddressPartsWork.append(zip)
                        
                    }
                    
                    
                    for i in resultAddressPartsWork {
                        self?.resultAddressWork = (self?.resultAddressWork)! + i
                    }
                    
                self?.store.setValueInState(value: self!.resultAddressWork as NSSecureCoding , forKey: "work_location")
                
                self?.store.setValueInState(value: resultCoordWork!.latitude as NSSecureCoding, forKey: "work_coordinate_lat")
                self?.store.setValueInState(value: resultCoordWork!.latitude as NSSecureCoding, forKey: "work_coordinate_long")
             
                
                // home
                
               
                    var resultHome = taskResult.stepResult(forStepIdentifier: "home_location_step")
                    var locationAnswerHome = resultHome?.firstResult as? ORKLocationQuestionResult
                    var resultCoordHome = locationAnswerHome?.locationAnswer?.coordinate
                    var resultRegionHome = locationAnswerHome?.locationAnswer?.region
                    var resultDictionaryHome = locationAnswerHome?.locationAnswer?.addressDictionary
                    
                    self?.resultAddressHome = ""
                    var resultAddressPartsHome : [String] = []
                    
                    if resultDictionaryHome?.index(forKey: "Name") != nil {
                        let name = resultDictionaryHome?["Name"] as! String
                        resultAddressPartsHome.append(name)
                    }
                    if resultDictionaryHome?.index(forKey: "City") != nil {
                        let city = resultDictionaryHome?["City"] as! String
                        resultAddressPartsHome.append(",")
                        resultAddressPartsHome.append(" ")
                        resultAddressPartsHome.append(city)
                    }
                    if resultDictionaryHome?.index(forKey: "State") != nil {
                        let state = resultDictionaryHome?["State"] as! String
                        resultAddressPartsHome.append(",")
                        resultAddressPartsHome.append(" ")
                        resultAddressPartsHome.append(state)
                    }
                    if resultDictionaryHome?.index(forKey: "ZIP") != nil {
                        let zip = resultDictionaryHome?["ZIP"] as! String
                        resultAddressPartsHome.append(",")
                        resultAddressPartsHome.append(" ")
                        resultAddressPartsHome.append(zip)
                        
                    }
                    
                    
                    for i in resultAddressPartsHome {
                        self?.resultAddressHome = (self?.resultAddressHome)! + i
                    }
                
                
                self?.store.setValueInState(value: self!.resultAddressHome as NSSecureCoding , forKey: "home_location")
                
                self?.store.setValueInState(value: resultCoordHome!.latitude as NSSecureCoding, forKey: "home_coordinate_lat")
                self?.store.setValueInState(value: resultCoordHome!.latitude as NSSecureCoding, forKey: "home_coordinate_long")
                
                
    
            }
            

            
            self?.dismiss(animated: true,completion: {
                appDelegate.updateMonitoredRegions(regionChanged: "both")
                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                let vc = storyboard.instantiateInitialViewController()
                appDelegate.transition(toRootViewController: vc!, animated: true)
            })

            
        }
        
        let tvc = RSAFTaskViewController(
            activityUUID: UUID(),
            task: task,
            taskFinishedHandler: taskFinishedHandler
        )
        
        self.present(tvc, animated: true, completion: nil)
    }
    


    
}
