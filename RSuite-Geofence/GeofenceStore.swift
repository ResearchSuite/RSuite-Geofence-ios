//
//  GeofenceStore.swift
//  RSuite-Geofence
//
//  Created by Christina Tsangouri on 6/26/17.
//  Copyright © 2017 Christina Tsangouri. All rights reserved.
//

//
//  OhmageCredentialsStore.swift
//
//  Created by James Kizer on 6/6/17.
//  Copyright © 2017 ResearchSuite. All rights reserved.
//

import UIKit
import OhmageOMHSDK
import ResearchSuiteAppFramework
import ResearchSuiteTaskBuilder

class GeofenceStore: NSObject, OhmageOMHSDKCredentialStore, RSTBStateHelper, OhmageManagerProvider {
    
    func valueInState(forKey: String) -> NSSecureCoding? {
        return self.get(key: forKey)
    }
    
    func setValueInState(value: NSSecureCoding?, forKey: String) {
        self.set(value: value, key: forKey)
    }
    
    func set(value: NSSecureCoding?, key: String) {
        RSAFKeychainStateManager.setValueInState(value: value, forKey: key)
    }
    func get(key: String) -> NSSecureCoding? {
        return RSAFKeychainStateManager.valueInState(forKey: key)
    }
    
    func getOhmageManager() -> OhmageOMHManager? {
        return (UIApplication.shared.delegate as? AppDelegate)?.ohmageManager
    }
    
    func reset() {
        RSAFKeychainStateManager.clearKeychain()
    }
    
}
