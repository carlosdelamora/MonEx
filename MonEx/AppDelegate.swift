//
//  AppDelegate.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/3/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Firebase
import UIKit
import FBSDKCoreKit
import GoogleSignIn
import OneSignal
import CoreData
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate{
    
    var window: UIWindow?
    var stack = CoreDataStack(modelName: "Model")
    var isMessagesVC = false
    let appUser = AppUser.sharedInstance
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //we make the AppDelegete the notificaion ceneter delegate, so we can disable the alert when the messagesVC is present
        UNUserNotificationCenter.current().delegate = self
        
        //one signal
        OneSignal.initWithLaunchOptions(launchOptions, appId: "deb77a4d-ecbc-48c8-a559-a0e046ba05e8", handleNotificationReceived: { (notification) in
            print("Received Notification - \(notification?.payload.additionalData as? [String: String])")
            
            if let dictionary = notification?.payload.additionalData as? [String: String]{
                let bidId = dictionary["bidId"]
                let offerStatus = dictionary[Constants.offer.offerStatus]
                let pathUsers = "/Users/\(self.appUser.firebaseId)/Bid/\(bidId!)/offer/\(Constants.offer.offerStatus)"
                let offerLocationPath = "/\(Constants.offerBidLocation.offerBidsLocation)/\(bidId!)/lastOfferInBid/\(Constants.offer.offerStatus)"
                let values : [String: String] = [pathUsers: offerStatus!, offerLocationPath: offerStatus!]
                self.appUser.activateAndDeActivateOffersInFirebase(values: values)
                guard let imageUrl = dictionary[Constants.offer.imageUrl], let firebaseId = dictionary[Constants.offer.firebaseId], let name = dictionary[Constants.offer.name] else{
                    return
                }
                
                //UserDefaults.standard.set([imageUrl, firebaseId, name], forKey: bidId!)
                self.stack?.context.perform{
                    let _ = OtherOffer(bidId: bidId!, firebaseIdOther: firebaseId, imageUrlOfOther: imageUrl, name: name, context: (self.stack?.context)!)
                }
            }
            
            
            //notification?.payload.rawPayload
            //print("\(notification?.payload as? [String: Any]) we got ")
            
            
            
        }, handleNotificationAction: { (result) in
            let payload: OSNotificationPayload? = result?.notification.payload
            
            var fullMessage: String? = payload?.body
            if payload?.additionalData != nil {
                var additionalData: [AnyHashable: Any]? = payload?.additionalData
                if additionalData!["actionSelected"] != nil {
                    fullMessage = fullMessage! + "\nPressed ButtonId:\(additionalData!["actionSelected"])"
                }
            }
            
        }, settings: [kOSSettingsKeyAutoPrompt : true, kOSSettingsKeyInFocusDisplayOption: OSNotificationDisplayType.notification.rawValue])
        
        
        //facebook
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        //firebase
        FIRApp.configure()
        
        //google
        GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        //save every second 
        stack?.autoSave(1)
        return true
    }
    
    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        let handled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String!, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        
        GIDSignIn.sharedInstance().handle(url, sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                             annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        
        return handled
        
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask(rawValue: UInt(checkOrientation(viewController: self.window?.rootViewController)))
    }
    
    

    
    // we use this function to handle the notifications
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print(userInfo)
        
        completionHandler(.noData)
        
    }
    

    
    func checkOrientation(viewController:UIViewController?)-> Int{
        
        if(viewController == nil){
            
            return Int(UIInterfaceOrientationMask.all.rawValue)//All means all orientation
            
        }else if viewController! is InquiryViewController || viewController! is InquiryViewController {
            
            return Int(UIInterfaceOrientationMask.portrait.rawValue)//This is sign in view controller that i only want to set this to portrait mode only
            
        }else{
            // when the view controller is the login controller then viewController!.presentedViewController is nil and this returns the all.rawValue
            return checkOrientation(viewController: viewController!.presentedViewController)
        }
    }
}

extension AppDelegate: GIDSignInDelegate{
    
    public func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        
        if let _ = error {
            return
        }
        
        guard let authentication = user.authentication else { return }
        let credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                          accessToken: authentication.accessToken)
        
        FIRAuth.auth()?.signIn(with: credential){ (user, error) in
            
            if let error = error {
                print("there was an error \(error)")
                return
            }else{
                guard let user = user else {
                    return
                }
                print("\(user)")
            }
            
            print("login to firebase with google")
        }
        
    }
    
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
        print("app delegate GIDsignInDelegate didDisconnectWithUserWasCalled wit error \(error)")
    }

    
}

extension AppDelegate: UNUserNotificationCenterDelegate{
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let rootReference = FIRDatabase.database().reference()
        let requestidentifier = notification.request.identifier
        // the five minutes notifications are to read the current status of the bid, if you are the last one who wrote to it then there was no action and the offer should be cancelled. 
        if requestidentifier == "FiveMinNotification"{
            if let userInfo = notification.request.content.userInfo as? [String: Any]{
                guard let data = userInfo[Constants.notification.data] as? [String: String] else{
                    //there was no data thus a remote notification
                    return
                }
                
                guard let bidId = data[Constants.notification.bidId] else{
                    return
                }
                
                func deleteInfo(){
                    rootReference.child("bidIdStatus/\(bidId)").observeSingleEvent(of: .value, with:{ (snapshot) in
                        guard let dictionary = snapshot.value as? [String: Any] else{
                            return
                        }
                        guard let lastOneToWrite = dictionary[Constants.publicBidInfo.lastOneToWrite] as? String else{
                            return
                        }
                        
                        // if the last one to write was the user then everything that was created for the bid should be erased
                        if lastOneToWrite == self.appUser.firebaseId{
                            
                            self.appUser.getOtherOffer(bidId: (bidId)){ otherOffer in
                                
                                guard let otherOffer = otherOffer else{
                                    return
                                }
                                
                                let pathForBidStatus = "/bidIdStatus/\(bidId)" // set to Null
                                let pathForTranspose = "/transposeOfacceptedOffer/\(otherOffer.firebaseIdOther!)/\(bidId)"//set to null
                                let pathForBidLocation = "/offerBidsLocation/\(bidId)/lastOfferInBid/\(Constants.offer.offerStatus)" //update to non active
                                let pathToMyBids = "/Users/\(self.appUser.firebaseId)/Bid/\(bidId)" //set to null
                                
                                rootReference.updateChildValues([pathForBidStatus: NSNull(), pathForBidLocation: Constants.offerStatus.nonActive, pathForTranspose: NSNull(), pathToMyBids: NSNull()])
                            }
                        }
                        
                        print("we are here")
                    })
                }

                
                appUser.getBidStatus(bidId: bidId, completion: { status in
                   
                    switch status.rawValue{
                    case Constants.appUserBidStatus.noBid:
                        //this could happen if the bid was deleted by the author for example we need to delete everything we created
                        deleteInfo()
                    case Constants.appUserBidStatus.lessThanFive:
                        //this should not happen and there is nothing to do
                        break
                    case Constants.appUserBidStatus.moreThanFiveUserLastToWrite:
                        //there was no response to our request we then errase everything
                        deleteInfo()
                    case Constants.appUserBidStatus.moreThanFiveOtherLastToWrite:
                        //there is new informaton, we wait for the app to update
                        break
                    default:
                        break
                    }
                   
                })
                
                print(bidId)
            }
        }
        
        
        
        
        //if messages VC is present we want only sound othersie we can aler and sound 
        if isMessagesVC{
            completionHandler([.sound])
        }else{
            completionHandler([.alert,.sound])
        }
        
    }
    
}



