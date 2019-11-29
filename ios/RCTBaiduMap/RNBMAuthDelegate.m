//
//  RNBMAuthDelegate.m
//  CodePush
//
//  Created by n on 2019/11/29.
//

#import "RNBMAuthDelegate.h"

@implementation RNBMAuthDelegate
- (void)onCheckPermissionState:(BMKLocationAuthErrorCode)iError{
    NSLog(@"onCheckPermissionState %ld",iError);
}
@end
