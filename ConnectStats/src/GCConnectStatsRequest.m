//  MIT License
//
//  Created on 28/05/2019 for ConnectStats
//
//  Copyright (c) 2019 Brice Rosenzweig
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//



#import "GCConnectStatsRequest.h"
#import "GCAppGlobal.h"
#import "GCWebUrl.h"
@import RZUtils;
@import RZExternal;

@interface GCConnectStatsRequest ()
@property (nonatomic,retain) NSString * oauthTokenSecret;
@property (nonatomic,retain) NSString * oauthToken;
@property (nonatomic,assign) NSUInteger tokenId;
@property (nonatomic,assign) NSUInteger userId;
@property (nonatomic,retain) OAuth1Controller * oauth1Controller;
@property (nonatomic,retain) UIWebView * webView;
@end

@implementation GCConnectStatsRequest

-(instancetype)init{
    self = [super init];
    if( self ){
        [self checkToken];
    }
    return self;
}

-(instancetype)initNextWith:(GCConnectStatsRequest*)current{
    if( self = [super init] ){
        self.oauth1Controller = current.oauth1Controller;
        self.oauthToken = current.oauthToken;
        self.userId = current.userId;
        self.tokenId = current.tokenId;
        self.oauthTokenSecret = current.oauthTokenSecret;
        self.webView = nil;
        self.navigationController = nil;
    }
    return self;
}
-(void)checkToken{
    self.oauthToken = [[GCAppGlobal profile] configGetString:CONFIG_CONNECTSTATS_TOKEN defaultValue:@""];
    self.oauthTokenSecret = [[GCAppGlobal profile] currentPasswordForService:gcServiceConnectStats];
    
    self.userId = [[GCAppGlobal profile] configGetInt:CONFIG_CONNECTSTATS_USER_ID defaultValue:0];
    self.tokenId = [[GCAppGlobal profile] configGetInt:CONFIG_CONNECTSTATS_TOKEN_ID defaultValue:0];
    
    if ((self.oauthTokenSecret).length==0) {
        self.oauthTokenSecret = nil;
        self.oauthToken = nil;
        self.userId = 0;
        self.tokenId = 0;
    }

}

-(BOOL)isSignedIn{
    return self.oauthToken != nil && self.oauthTokenSecret != nil;
}

-(void)signIn{
    if (self.oauthToken) {
        [self processDone];
    }else{
        [self signInGarminStep];
    }
    
}

-(void)signInConnectStatsStep{
    NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:GCWebConnectStatsRegisterUser(self.oauthToken, self.oauthTokenSecret)]];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
      ^(NSData * _Nullable data,
        NSURLResponse * _Nullable response,
        NSError * _Nullable error) {
          if( error ){
              RZLog(RZLogError, @"Error %@", error);
              
          }else{
              NSDictionary * response = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
              if( [response isKindOfClass:[NSDictionary class]]){
                  NSNumber * responseTokenId = response[@"token_id"];
                  if( [responseTokenId respondsToSelector:@selector(integerValue)] ){
                      self.tokenId = responseTokenId.integerValue;
                  }else{
                      self.tokenId = 0;
                  }
                  
                  NSNumber * responseUserId = response[@"cs_user_id"];
                  if( [responseUserId respondsToSelector:@selector(integerValue)] ){
                      self.userId = responseUserId.integerValue;
                  }else{
                      self.userId = 0;
                  }
                  
                  [[GCAppGlobal profile] configSet:CONFIG_CONNECTSTATS_TOKEN_ID intVal:self.tokenId];
                  [[GCAppGlobal profile] configSet:CONFIG_CONNECTSTATS_USER_ID intVal:self.userId];
                  
                  if( self.userId != 0 && self.tokenId !=0){
                      [[GCAppGlobal profile] serviceSuccess:gcServiceConnectStats set:YES];
                  }
                  [GCAppGlobal saveSettings];
              }
          }
          [self processDone];
          
      }] resume];
    
}

-(void)signInGarminStep{
    UIViewController * webCont = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    UIWebView * webView = [[UIWebView alloc] initWithFrame:self.navigationController.view.frame];
    // keep hold so we can clear the delegate.
    self.webView = webView;
    webCont.view = webView;
    [self.navigationController pushViewController:webCont animated:YES];
    [webCont release];
    [webView release];
    NSError * error = nil;
    NSData * credentials = [NSData dataWithContentsOfFile:[RZFileOrganizer bundleFilePath:@"credentials.json"] options:0 error:&error];
    if( ! credentials ){
        RZLog(RZLogError,@"Failed to read credentials.json %@", error);
    }
    NSDictionary * params = [OAuth1Controller serviceParametersFromJson:credentials forServiceName:@"garmin"];
    
    self.oauth1Controller = [[[OAuth1Controller alloc] initWithServiceParameters:params] autorelease];
    [self.oauth1Controller loginWithWebView:webView completion:^(NSDictionary *oauthTokens, NSError *error) {
        if (error != nil) {
            RZLog(RZLogError, @"ConnectStats identification error %@", error);
            self.status = GCWebStatusLoginFailed;
            [[GCAppGlobal profile] serviceSuccess:gcServiceConnectStats set:NO];
            [self processDone];
        } else {
            self.oauthToken = oauthTokens[@"oauth_token"];
            self.oauthTokenSecret = oauthTokens[@"oauth_token_secret"];
            [[GCAppGlobal profile] configSet:CONFIG_CONNECTSTATS_TOKEN stringVal:self.oauthToken];
            [[GCAppGlobal profile] setPassword:self.oauthTokenSecret forService:gcServiceConnectStats];
            
            [GCAppGlobal saveSettings];
            
            dispatch_async([GCAppGlobal worker], ^(){
                [self signInConnectStatsStep];
            });
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self.navigationController popViewControllerAnimated:YES];
        });
    }];

}

-(NSURLRequest*)preparedUrlRequest:(NSString*)path params:(NSDictionary*)parameters{
    NSURLRequest *preparedRequest = [self.oauth1Controller preparedRequestForPath:path
                                                                       parameters:parameters
                                                                       HTTPmethod:@"GET"
                                                                       oauthToken:self.oauthToken
                                                                      oauthSecret:self.oauthTokenSecret];
    return preparedRequest;
}

@end
