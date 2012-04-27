//
//  Videotorium.h
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.26..
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideotoriumRecording.h"

@interface VideotoriumClient : NSObject

- (VideotoriumRecording *)recordingWithID:(NSString *)ID;

@end
