//
//  AppDelegate.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//


import UIKit
import Firebase
//import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
//    let gcmMessageIDKey = NSUUID().uuidString

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
//        attemptToRegisterForNotifications(application: application)
        return true
    }
    
//    func attemptToRegisterForNotifications(application: UIApplication) {
//        Messaging.messaging().delegate = self
//        UNUserNotificationCenter.current().delegate = self
//
//        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
//        UNUserNotificationCenter.current().requestAuthorization(options: options) { (authorized, error) in
//            if authorized {
//                print("DEBUG: SUCCESSFULLY REGISTERED FOR NOTIFICATIONS")
//            }
//        }
//
//        application.registerForRemoteNotifications()
//    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
      // If you are receiving a notification message while your app is in the background,
      // this callback will not be fired till the user taps on the notification launching the application.
      // TODO: Handle data of notification

      // With swizzling disabled you must let Messaging know about the message, for Analytics
      // Messaging.messaging().appDidReceiveMessage(userInfo)

      // Print message ID.
//      if let messageID = userInfo[gcmMessageIDKey] {
//        print("Message ID: \(messageID)")
      }

      // Print full message.
//      print(userInfo)
//    }

//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
//                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
      // If you are receiving a notification message while your app is in the background,
      // this callback will not be fired till the user taps on the notification launching the application.
      // TODO: Handle data of notification

      // With swizzling disabled you must let Messaging know about the message, for Analytics
      // Messaging.messaging().appDidReceiveMessage(userInfo)

      // Print message ID.
//      if let messageID = userInfo[gcmMessageIDKey] {
//        print("Message ID: \(messageID)")
//      }

      // Print full message.
//      print(userInfo)
//
//      completionHandler(UIBackgroundFetchResult.newData)
//    }
//}

//extension AppDelegate: MessagingDelegate {
//    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        print("DEBUG: Registered for notifications with device token: ", deviceToken)
//        Messaging.messaging().apnsToken = deviceToken
//    }
//
//    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
//        print("DEBUG: Registered with FCM Token: ", fcmToken)
//    }
//}
//
//@available(iOS 10, *)
//extension AppDelegate : UNUserNotificationCenterDelegate {
//
//  // Receive displayed notifications for iOS 10 devices.
//  func userNotificationCenter(_ center: UNUserNotificationCenter,
//                              willPresent notification: UNNotification,
//    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//    let userInfo = notification.request.content.userInfo
//
//    // With swizzling disabled you must let Messaging know about the message, for Analytics
//    // Messaging.messaging().appDidReceiveMessage(userInfo)
//
//    // Print message ID.
//    if let messageID = userInfo[gcmMessageIDKey] {
//      print("Message ID: \(messageID)")
//    }
//
//    // Print full message.
//    print(userInfo)
//
//    // Change this to your preferred presentation option
//    completionHandler([[.alert, .sound]])
//  }
//
//  func userNotificationCenter(_ center: UNUserNotificationCenter,
//                              didReceive response: UNNotificationResponse,
//                              withCompletionHandler completionHandler: @escaping () -> Void) {
//    let userInfo = response.notification.request.content.userInfo
//    // Print message ID.
//    if let messageID = userInfo[gcmMessageIDKey] {
//      print("Message ID: \(messageID)")
//    }
//
//    // With swizzling disabled you must let Messaging know about the message, for Analytics
//    // Messaging.messaging().appDidReceiveMessage(userInfo)
//
//    // Print full message.
//    print(userInfo)
//
//    completionHandler()
//  }
//}

