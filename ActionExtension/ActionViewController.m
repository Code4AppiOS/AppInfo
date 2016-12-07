//
//  ActionViewController.m
//  ActionExtension
//
//  Created by cyan on 07/12/2016.
//  Copyright © 2016 cyan. All rights reserved.
//

#import "ActionViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <SafariServices/SafariServices.h>
#import "Masonry.h"

@interface ActionViewController ()<SFSafariViewControllerDelegate>

@end

@implementation ActionViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    void(^downloadCompletionHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            NSLog(@"error: %@", error.localizedDescription);
            return;
        }
        
        NSString *storeUrl = response.URL.absoluteString;
        NSRange searchedRange = NSMakeRange(0, [storeUrl length]);
        NSString *pattern = @"[0-9]{5,}";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                               options:0
                                                                                 error:&error];
        NSArray *matches = [regex matchesInString:storeUrl options:0 range:searchedRange];
        
        for (NSTextCheckingResult *match in matches) {
            NSString *identifier = [storeUrl substringWithRange:[match range]];
            dispatch_async(dispatch_get_main_queue(), ^{
                // appannie: https://www.appannie.com/apps/ios/app/identifier/details/
                // aso100: https://aso100.com/app/baseinfo/appid/identifier
                NSURL *url = [NSURL URLWithString:[@"https://aso100.com/app/baseinfo/appid/" stringByAppendingString:identifier]];
                SFSafariViewController *controller = [[SFSafariViewController alloc] initWithURL:url];
                controller.delegate = self;
                [self addChildViewController:controller];
                [self.view addSubview:controller.view];
                [controller didMoveToParentViewController:self];
                [controller.view mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.edges.equalTo(self.view);
                }];
            });
        }
    };
    
    void(^loadCompletionHandler)(NSURL *, NSError *) = ^(NSURL *original, NSError *error) {
        
        if (error) {
            NSLog(@"error: %@", error.localizedDescription);
            return;
        }
        
        NSString *path = [[original.absoluteString stringByReplacingOccurrencesOfString:@"https://appsto.re"
                                                                             withString:@""] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        NSURL *url = [NSURL URLWithString:[@"https://itunes.apple.com/WebObjects/MZStore.woa/wa/redirectToContent?path=" stringByAppendingString:path]];
        [[[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:url]
                                         completionHandler:downloadCompletionHandler] resume];
    };
    
    NSString *identifier = (NSString *)kUTTypeURL;
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            if ([itemProvider hasItemConformingToTypeIdentifier:identifier]) {
                [itemProvider loadItemForTypeIdentifier:identifier options:nil completionHandler:loadCompletionHandler];
                return;
            }
        }
    }
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
}

@end
