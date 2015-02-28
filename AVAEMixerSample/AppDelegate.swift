//
//  AppDelegate.swift
//  AVAEMixerSample
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/2/28.
//
//
///*
//    Copyright (C) 2015 Apple Inc. All Rights Reserved.
//    See LICENSE.txt for this sample’s licensing information
//
//    Abstract:
//    Application Delegate
//*/
//
//@import UIKit;
import UIKit
//
//@interface AppDelegate : UIResponder <UIApplicationDelegate>
@UIApplicationMain
@objc(AppDelegate)
class AppDelegate: UIResponder, UIApplicationDelegate {
//
//@property (strong, nonatomic) UIWindow *window;
    var window: UIWindow?
//
//
//@end
//
///*
//    Copyright (C) 2015 Apple Inc. All Rights Reserved.
//    See LICENSE.txt for this sample’s licensing information
//
//    Abstract:
//    Application Delegate
//*/
//
//#import "AppDelegate.h"
//
//@interface AppDelegate ()
//
//@end
//
//@implementation AppDelegate
//
//
//- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
//    // Override point for customization after application launch.
//
//    return YES;
        return true
//}
    }
//
//- (void)applicationWillResignActive:(UIApplication *)application {
    func applicationWillResignActive(application: UIApplication) {
//    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
//    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
//}
    }
//
//- (void)applicationDidEnterBackground:(UIApplication *)application {
    func applicationDidEnterBackground(application: UIApplication) {
//    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
//    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//}
    }
//
//- (void)applicationWillEnterForeground:(UIApplication *)application {
    func applicationWillEnterForeground(application: UIApplication) {
//    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
//}
    }
//
//- (void)applicationDidBecomeActive:(UIApplication *)application {
    func applicationDidBecomeActive(application: UIApplication) {
//    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//}
    }
//
//- (void)applicationWillTerminate:(UIApplication *)application {
    func applicationWillTerminate(application: UIApplication) {
//    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//}
    }
//
//@end
}