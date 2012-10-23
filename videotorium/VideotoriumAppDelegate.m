//
//  VideotoriumAppDelegate.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.26..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumAppDelegate.h"
#import "VideotoriumPlayerViewControllerPad.h"

@implementation VideotoriumAppDelegate


- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    NSArray *components = url.pathComponents;
    if ([[components objectAtIndex:1] isEqual:@"recording"]) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[components objectAtIndex:2] forKey:@"recording"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"openURL" object:nil userInfo:userInfo];
        return YES;
    }
    return NO;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UIImage *image = [UIImage imageNamed:@"videotorium-gradient.png"];
    [(UINavigationBar*)[UINavigationBar appearance] setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    [(UISearchBar*)[UISearchBar appearance] setBackgroundImage:image];
    [(UIToolbar*)[UIToolbar appearanceWhenContainedIn:[UINavigationController class], nil] setBackgroundImage:image forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [(UIToolbar*)[UIToolbar appearanceWhenContainedIn:[VideotoriumPlayerViewControllerPad class], nil] setBackgroundImage:image forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [(UIBarButtonItem*)[UIBarButtonItem appearanceWhenContainedIn:[UINavigationController class], nil] setTintColor:[UIColor colorWithRed:0 green:0.5 blue:0.73 alpha:1]];
    [(UIToolbar*)[UIToolbar appearanceWhenContainedIn:[VideotoriumRecordingInfoViewController class], nil] setBackgroundImage:image forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [(UIBarButtonItem*)[UIBarButtonItem appearanceWhenContainedIn:[VideotoriumRecordingInfoViewController class], nil] setTintColor:[UIColor colorWithRed:0 green:0.5 blue:0.73 alpha:1]];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // On the iPad the player view can only recieve the remote control events if it's the first responder.
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UIViewController *playerViewController = [splitViewController.viewControllers objectAtIndex:1];
        [playerViewController becomeFirstResponder];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
