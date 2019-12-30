//
//  NotificationCenterAlert.swift
//  The Repo
//
//  Created by Sherif Darwish on 12/28/19.
//  Copyright © 2019 Sherif Darwish. All rights reserved.
//

import Foundation
import UserNotifications

extension ViewController : UNUserNotificationCenterDelegate{
    func setupNotificationAlert(){
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.threadIdentifier = "The Repos"
        content.title = "New Updates"
        content.body = "Check For New Repos"
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: true)
        let request = UNNotificationRequest.init(identifier: "content", content: content, trigger: trigger)
        center.add(request) { (error) in
            if error == nil{
                print("Successfuly setup userNotification")
             //   self.refreshData()
            }else{
                print("Error setup userNotification \(error?.localizedDescription ?? " ")")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("userInteracted")
        self.refreshData()
    }
    
}
