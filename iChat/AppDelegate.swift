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
import PushKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate,
        SINClientDelegate, SINCallClientDelegate, SINManagedPushDelegate,
        PKPushRegistryDelegate {
    var window: UIWindow?
    var authListener: AuthStateDidChangeListenerHandle?
    var locationManager: CLLocationManager?
    var coordinates: CLLocationCoordinate2D?
    var _client: SINClient!
    var push: SINManagedPush!

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
        voipRegistration()
        push = Sinch.managedPush(with: .development)
        push.delegate = self
        push.setDesiredPushTypeAutomatically()

        func userDidLogin(userId: String) {
            push.registerUserNotificationSettings()
            initSinchWithUserId(userId: userId)
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
        if FUser.currentUser() != nil {
            updateCurrentUserInFirestore(withValues: [kISONLINE: true]) { error in
                if error != nil {
                    print("error updating user status \(error!.localizedDescription)")
                }
            }
        }
        locationManagerStart()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        if FUser.currentUser() != nil {
            updateCurrentUserInFirestore(withValues: [kISONLINE: false]) { error in
                if error != nil {
                    print("error updating user status \(error!.localizedDescription)")
                }
            }
        }
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

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        push.application(application,
                didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let firebaseAuth = Auth.auth()
        if firebaseAuth.canHandleNotification(userInfo) {
            return
        } else {
            push.application(application, didReceiveRemoteNotification: userInfo)
        }
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

    func initSinchWithUserId(userId: String) {
        if _client == nil {
            _client = Sinch.client(withApplicationKey: kSINCHKEY,
                    applicationSecret: kSINCHSECRET,
                    environmentHost: "sandbox.sinch.com", userId: userId)
            _client.delegate = self
            _client.call().delegate = self
            _client.setSupportCalling(true)
            _client.enableManagedPushNotifications()
            _client.start()
            _client.startListeningOnActiveConnection()
        }
    }

    func managedPush(_ managedPush: SINManagedPush!, didReceiveIncomingPushWithPayload payload: [AnyHashable: Any]!, forType pushType: String!) {
        let result = SINPushHelper.queryPushNotificationPayload(payload)!
        if result.isCall() {
            handleRemoteNotification(userInfo: payload as NSDictionary)
        }
    }

    func handleRemoteNotification(userInfo: NSDictionary) {
        if _client == nil {
            let userId = UserDefaults.standard.object(forKey: kUSERID)
            if userId != nil {
                initSinchWithUserId(userId: userId as! String)
            }
        }
        let result = _client.relayRemotePushNotification((userInfo as!
                [AnyHashable: Any]))!
        if result.isCall() {

        }
        if result.isCall() && result.call().isCallCanceled {
            presentMissedCallNotificationWithRemoteUserId(userId: result.call().callId)
        }
    }

    func presentMissedCallNotificationWithRemoteUserId(userId: String) {
        if UIApplication.shared.applicationState == .background {
            let center = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = "Missed Call"
            content.body = "From \(userId)"
            content.sound = UNNotificationSound.default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1,
                    repeats: false)
            let request = UNNotificationRequest(identifier: "ContentIdentifier",
                    content: content, trigger: trigger)
            center.add(request) { error in
                if error != nil {
                    print("error on notification \(error!.localizedDescription)")
                }
            }
        }
    }

    func client(_ client: SINCallClient!, willReceiveIncomingCall call: SINCall!) {
        print("will receive incoming call")
    }

    func client(_ client: SINCallClient!, didReceiveIncomingCall call: SINCall!) {
        var top = window!.rootViewController!
        while (top.presentedViewController != nil) {
            top = top.presentedViewController!
        }
        let callVC = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "CallVC")
                as! CallViewController
        callVC._call = call
        top.present(callVC, animated: true)
    }

    func clientDidStart(_ client: SINClient!) {
        print("Sinch did start")
    }

    func clientDidStop(_ client: SINClient!) {
        print("Sinch did stop")
    }

    func clientDidFail(_ client: SINClient!, error: Error!) {
        print("Sinch did fail \(error.localizedDescription)")
    }

    func voipRegistration() {
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [PKPushType.voIP]
    }

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {

    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        handleRemoteNotification(userInfo: payload.dictionaryPayload as NSDictionary)
    }
}
