//
//  AppDelegate.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 23/07/19.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import OneSignal

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
    var window: UIWindow?
    var authListener: AuthStateDidChangeListenerHandle?
    var locationManager: CLLocationManager?
    var coordinates: CLLocationCoordinate2D?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions
    launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()

        authListener = Auth.auth().addStateDidChangeListener { auth, user in
            Auth.auth().removeStateDidChangeListener(self.authListener!)
            if user != nil {
                if UserDefaults.standard.object(forKey: kCURRENTUSER) != nil {
                    DispatchQueue.main.async {
                        self.goToApp()
                    }
                }
            }
        }

        func userDidLogin(userId: String) {
            startOneSignal()
        }

        NotificationCenter.default.addObserver(
                forName: NSNotification.Name(USER_DID_LOGIN_NOTIFICATION),
                object: nil, queue: nil) { notification in
            let userId = notification.userInfo![kUSERID] as! String
            UserDefaults.standard.setValue(userId, forKey: kUSERID)
            UserDefaults.standard.synchronize()
            userDidLogin(userId: userId)
        }
        OneSignal.initWithLaunchOptions(launchOptions, appId: kONESIGNALAPPID)
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        locationManagerStart()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        locationManagerStop()
    }

    func goToApp() {
        NotificationCenter.default.post(name: NSNotification.Name(
                rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil,
                userInfo: [kUSERID: FUser.currentId()])
        let mainView = UIStoryboard.init(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "mainApplication")
                as! UITabBarController
        self.window?.rootViewController = mainView
    }

    func locationManagerStart() {
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager!.delegate = self
            locationManager!.desiredAccuracy = kCLLocationAccuracyBest
            locationManager!.requestWhenInUseAuthorization()
        }
        locationManager!.startUpdatingLocation()
    }

    func locationManagerStop() {
        if locationManager != nil {
            locationManager!.stopUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("failed to get location")
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .authorizedAlways:
            manager.startUpdatingLocation()
        case .restricted:
            print("restricted")
        case .denied:
            locationManager = nil
            print("denied location access")
        default:
            print("unknown status")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        coordinates = locations.last!.coordinate
    }

    func startOneSignal() {
        let status: OSPermissionSubscriptionState = OneSignal
                .getPermissionSubscriptionState()
        let userID = status.subscriptionStatus.userId
        let pushToken = status.subscriptionStatus.pushToken
        if pushToken != nil {
            if let playerID = userID {
                UserDefaults.standard.setValue(playerID, forKey: kPUSHID)
            } else {
                UserDefaults.standard.removeObject(forKey: kPUSHID)
            }
            UserDefaults.standard.synchronize()
        }
        updateOneSignalId()
    }
}
