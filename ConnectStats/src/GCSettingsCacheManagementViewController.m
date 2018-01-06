//  MIT Licence
//
//  Created on 15/11/2012.
//
//  Copyright (c) 2012 Brice Rosenzweig.
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

#import "GCSettingsCacheManagementViewController.h"
#import "GCCellGrid+Templates.h"

@interface GCSettingsCacheManagementViewController ()

@end

@implementation GCSettingsCacheManagementViewController
@synthesize cacheManagement;

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)dealloc{
    [cacheManagement release];
    [super dealloc];
}
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.cacheManagement = [[[GCActivitiesCacheManagement alloc] init] autorelease];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return gcCacheFileEnd;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"GridCell";
    GCCellGrid *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[GCCellGrid alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    if (indexPath.row < gcCacheFileEnd) {
        NSArray * typeNames = [GCActivitiesCacheManagement typeNames];
        gcCacheFile cfile = (gcCacheFile)indexPath.row;

        NSString * typename = typeNames[cfile];
        NSArray * infos = cacheManagement.cacheFiles[cfile];
        [cell setupForRows:2 andCols:2];
        if ( cfile == gcCacheFileActivityDb) {
            int n = 0;
            for (int i = 0; i<infos.count; i++) {
                n += [infos[i] activities];
            }
            [cell labelForRow:1 andCol:0].text = [NSString stringWithFormat:@"%d activities",n];
        }
        [cell labelForRow:0 andCol:0].text = typename;
        double size = cacheManagement.sizes[cfile];
        NSString * sizeStr = nil;
        if (size < 1024*1024) {
            sizeStr = [NSString stringWithFormat:@"%.0f Kb",size/1024.];
        }else{
            sizeStr = [NSString stringWithFormat:@"%.1f Mb",size/1024./1024.];
        }

        [cell labelForRow:0 andCol:1].text = sizeStr;
        [cell labelForRow:1 andCol:1].attributedText =
        [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d files",(int)infos.count] attributes:[GCViewConfig attribute14Gray]] autorelease];


    }

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0) {
        NSString * msg= NSLocalizedString(@"Are you sure you want to delete files from the cache?",@"Cache");
        if (indexPath.row == gcCacheFileTrackDb) {
            msg = NSLocalizedString(@"It is highly discouraged to delete track files, are you sure?",@"Cache");
        }
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Delete Files", @"Cache Management")
                                                                        message:msg
                                                                 preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cache Management") style:UIAlertActionStyleCancel
                                                handler:^(UIAlertAction*action){

                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"Cache Management")
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction*action){
                                                    gcCacheFile type = (gcCacheFile)indexPath.row;
                                                    [cacheManagement cleanupFiles:type];
                                                    [cacheManagement analyze];
                                                    [self.tableView reloadData];

                                                }]];
        [self presentViewController:alert animated:YES completion:^(){}];
    }
}

@end
