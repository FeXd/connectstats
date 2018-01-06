//
//  ExtensionDelegate.h
//  healthwatch Extension
//
//  Created by Brice Rosenzweig on 09/08/2015.
//  Copyright © 2015 Brice Rosenzweig. All rights reserved.
//

#import <WatchKit/WatchKit.h>
@import WatchConnectivity;

@class GCWSummaryInterfaceController;

@interface GCWExtensionDelegate : NSObject <WKExtensionDelegate,WCSessionDelegate>

@property (nonatomic,strong) GCWSummaryInterfaceController* mainInterface;
@end
