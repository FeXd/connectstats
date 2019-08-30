//  MIT Licence
//
//  Created on 14/09/2012.
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

#import "GCActivityDetailViewController.h"
#import "GCAppGlobal.h"
#import "GCMapViewController.h"
#import "GCCellMap.h"
#import "GCViewConfig.h"
#import "GCStatsOneFieldViewController.h"
#import "GCFields.h"
#import "GCCellGrid+Templates.h"
#import "GCActivityLapViewController.h"
#import "GCActivityTrackGraphViewController.h"
#import "GCSimpleGraphCachedDataSource+Templates.h"
#import "Flurry.h"
#import "GCActivitySwimLapViewController.h"
#import "GCSharingViewController.h"
#import <RZExternal/RZExternal.h>
#import "GCActivityTrackGraphOptionsViewController.h"
#import "GCActivity+ExportText.h"
#import "GCActivityTennisDetailSource.h"
#import "GCWebConnect+Requests.h"
#import "GCActivity+CSSearch.h"
#import "GCActivityOrganizedFields.h"
#import "GCActivity+Fields.h"
#import "GCFormattedField.h"
#import "GCHealthOrganizer.h"
#import "ConnectStats-Swift.h"

#define GCVIEW_DETAIL_TITLE_SECTION     0
#define GCVIEW_DETAIL_LOAD_SECTION      1
#define GCVIEW_DETAIL_MAP_SECTION       2
#define GCVIEW_DETAIL_GRAPH_SECTION     3
#define GCVIEW_DETAIL_AVGMINMAX_SECTION 4
#define GCVIEW_DETAIL_EXTRA_SECTION     5
#define GCVIEW_DETAIL_WEATHER_SECTION   6
#define GCVIEW_DETAIL_HEALTH_SECTION    7
#define GCVIEW_DETAIL_LAPS_HEADER       8
#define GCVIEW_DETAIL_LAPS_SECTION      9
#define GCVIEW_DETAIL_SECTIONS          10

@interface GCActivityDetailViewController ()

@property (nonatomic,retain) NSObject<UITableViewDataSource,UITableViewDelegate> * implementor;
@property (nonatomic,retain) GCActivitiesOrganizer * organizer;
@property (nonatomic,retain) GCTrackStats * trackStats;
@property (nonatomic,assign) BOOL waitingDownload;
@property (nonatomic,retain) GCActivityAutoLapChoices * autolapChoice;
@property (nonatomic,retain) GCTrackFieldChoices * choices;
@property (nonatomic,retain) GCActivity * activity;
@property (nonatomic,retain) GCTrackStats * compareTrackStats;
@property (nonatomic,assign) BOOL initialized;

@property (nonatomic,retain) GCActivityOrganizedFields * organizedFields;
@property (nonatomic,retain) NSArray<NSArray*>*organizedAttributedStrings;
/**
 NSArray of either graph GCField or something else if no graph field @(0)
 */
@property (nonatomic,retain) NSArray*organizedMatchingField;
@end

@implementation GCActivityDetailViewController

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.organizer = [GCAppGlobal organizer];
        [self.organizer attach:self];
        [[GCAppGlobal web] attach:self];
        self.initialized = false;
        // Custom initialization
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyCallBack:) name:kNotifySettingsChange object:nil];
    }
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_organizer detach:self];
    [[GCAppGlobal web] detach:self];
    [_autolapChoice release];
    [_choices release];

    [_organizedFields release];
    [_organizedAttributedStrings release];
    [_organizedMatchingField release];
    [_organizer release];
    [_trackStats release];
    [_activity release];
    [_implementor release];

    [super dealloc];
}

- (void)viewDidLoad
{
    RZLogTrace(@"");
    [super viewDidLoad];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    //self.tableView.backgroundColor = [GCViewConfig defaultBackgroundColor];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.refreshControl = [[[UIRefreshControl alloc] init] autorelease];
    self.refreshControl.attributedTitle = nil;
    [self.refreshControl addTarget:self action:@selector(refreshData) forControlEvents:UIControlEventValueChanged];

    [self selectNewActivity:[[GCAppGlobal organizer] currentActivity]];

    if ([UIViewController useIOS7Layout]) {
        CGFloat height = 20.;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            height = 64.;
        }
        self.tableView.tableHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0., 0., 320., height)] autorelease];
    }
    if ([GCViewConfig uiStyle] == gcUIStyleIOS7) {
        self.tableView.tableHeaderView.backgroundColor = [GCViewConfig cellBackgroundLighterForActivity:self.activity];
    }
    self.initialized = true;
    self.view.backgroundColor = [GCViewConfig defaultColor:gcSkinDefaultColorBackground];
    self.tableView.backgroundColor = [GCViewConfig defaultColor:gcSkinDefaultColorBackground];
}

- (void)viewWillAppear:(BOOL)animated
{
    RZLogTrace(@"");

    [super viewWillAppear:animated];

    if (self.slidingViewController) {
        [self.view addGestureRecognizer:self.slidingViewController.panGesture];
        (self.slidingViewController).anchorRightRevealAmount = self.view.frame.size.width*0.875;
        //FIXME:
        self.slidingViewController.topViewAnchoredGesture = ECSlidingViewControllerAnchoredGesturePanning;
        self.slidingViewController.panGesture.delegate = self;
        //[self.slidingViewController setShouldAddPanGestureRecognizerToTopViewSnapshot:YES];
    }
    self.tableView.tableHeaderView.backgroundColor = [GCViewConfig cellBackgroundLighterForActivity:self.activity];

#ifdef GC_USE_FLURRY
    [self publishEvent];
#endif

}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.slidingViewController.panGesture.delegate = nil;
}

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    // With the menu open, let any gesture pass.
    if (self.slidingViewController.currentTopViewPosition == ECSlidingViewControllerTopViewPositionAnchoredRight) return YES;
    // With a closed Menu, only let the bordermost gestures pass.
    return ([gestureRecognizer locationInView:gestureRecognizer.view].x < 40.);

}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}

-(void)refreshData{
    if( [NSThread isMainThread]){
        [self selectNewActivity:[[GCAppGlobal organizer] currentActivity]];
        [self.activity forceReloadTrackPoints];

        [self.refreshControl beginRefreshing];
        self.refreshControl.attributedTitle = [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Refreshing",@"RefreshControl")] autorelease];
        [self.tableView reloadData];
    }else{
        [self performSelectorOnMainThread:@selector(refreshData) withObject:nil waitUntilDone:NO];
    }
}

-(void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection{
    [self notifyCallBack:nil info:nil];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.implementor) {
        return [self.implementor numberOfSectionsInTableView:tableView];
    }
    // Return the number of sections.
    //return [[self fieldsToDisplay] count];
    return GCVIEW_DETAIL_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.implementor) {
        return [self.implementor tableView:tableView numberOfRowsInSection:section];
    }

    // Return the number of rows in the section.
    //return [[[self fieldsToDisplay] objectAtIndex:section] count];
    if (section == GCVIEW_DETAIL_MAP_SECTION ) {
        BOOL valid = [self.activity validCoordinate];
        if (valid) {
            self.waitingDownload = ![self.activity trackpointsReadyOrLoad];

            return self.waitingDownload ? 0 : 1;
        }
        return  0 ;
    }else if (section == GCVIEW_DETAIL_LOAD_SECTION){
        self.waitingDownload = [self.activity trackPointsRequireDownload];
        if (self.waitingDownload) {
            return 1;
        }else{
            return 0;
        }
    }else if (section == GCVIEW_DETAIL_GRAPH_SECTION){
        return self.waitingDownload || [self.activity trackpoints].count==0 ? 0 : 1;
    }else if (section == GCVIEW_DETAIL_TITLE_SECTION){
        return 1;
    }else if (section == GCVIEW_DETAIL_LAPS_SECTION){
        return [self.activity lapCount];
    }else if ( section == GCVIEW_DETAIL_WEATHER_SECTION ){
        return [self.activity hasWeather] ? 1 : 0;
    }else if (section == GCVIEW_DETAIL_LAPS_HEADER){
        if ([self.activity laps]) {
            return 1;
        }else{
            return 0;
        }
    }else if (section == GCVIEW_DETAIL_EXTRA_SECTION){
        if ((self.activity).metaData.count) {
            return 1;
        }
        return 0;
    }else if (section == GCVIEW_DETAIL_HEALTH_SECTION){
        if ([[GCAppGlobal health] hasHealthData]) {
            return 1;
        }else{
            return 0;
        }
    }

    return [self displayPrimaryAttributedStrings].count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView dayGraphCellForRowAtIndexPath:(NSIndexPath *)indexPath{
    GCCellSimpleGraph * cell = [GCCellSimpleGraph graphCell:tableView];
    cell.cellDelegate = self;
    GCActivity * activity = self.activity;
    GCTrackStats * s = [[GCTrackStats alloc] init];
    s.activity = activity;
    if (!self.choices || (self.choices).choices.count==0) {
        self.choices = [GCTrackFieldChoices trackFieldChoicesWithDayActivity:activity];
    }
    //s.x_movingAverage = 60.*10.;
    s.movingSumForUnit = 60.*5.;
    s.bucketUnit = 60.*5.;
    [self.choices setupTrackStats:s];
    self.trackStats = s;
    GCSimpleGraphCachedDataSource * ds = [GCSimpleGraphCachedDataSource trackFieldFrom:s];
    GCActivity * compare = [self compareActivity];
    if (compare) {
        if ([self.choices validForActivity:compare]) {
            self.compareTrackStats = [[[GCTrackStats alloc] init] autorelease];
            self.compareTrackStats.activity = compare;
            [self.choices setupTrackStats:self.compareTrackStats];
            GCSimpleGraphCachedDataSource * dsc = [GCSimpleGraphCachedDataSource trackFieldFrom:self.compareTrackStats];
            [dsc setupAsBackgroundGraph];
            [ds addDataSource:dsc];
        }

    }
    [cell setDataSource:ds andConfig:ds];

    [s release];

    return cell;
}

-(UITableViewCell*)tableView:(UITableView *)tableView activityGraphCellForRowAtIndexPath:(NSIndexPath *)indexPath{
    GCCellSimpleGraph * cell = [GCCellSimpleGraph graphCell:tableView];
    cell.cellDelegate = self;
    GCActivity * activity = self.activity;
    GCTrackStats * s = [[GCTrackStats alloc] init];
    s.activity = activity;
    if (!self.choices || (self.choices).choices.count==0) {
        self.choices = [GCTrackFieldChoices trackFieldChoicesWithActivity:activity];
    }
    [self.choices setupTrackStats:s];
    self.trackStats = s;
    GCSimpleGraphCachedDataSource * ds = [GCSimpleGraphCachedDataSource trackFieldFrom:s];
    GCActivity * compare = [self compareActivity];
    if (compare) {
        if ([self.choices validForActivity:compare]) {
            self.compareTrackStats = [[[GCTrackStats alloc] init] autorelease];
            self.compareTrackStats.activity = compare;
            [self.choices setupTrackStats:self.compareTrackStats];
            GCSimpleGraphCachedDataSource * dsc = [GCSimpleGraphCachedDataSource trackFieldFrom:self.compareTrackStats];
            [dsc setupAsBackgroundGraph];
            [ds addDataSource:dsc];
        }
    }
    [cell setDataSource:ds andConfig:ds];

    [s release];

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.implementor) {
        return [self.implementor tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    UITableViewCell * rv = nil;


    if (indexPath.section == GCVIEW_DETAIL_TITLE_SECTION) {
        GCCellGrid * cell = [GCCellGrid gridCell:tableView];
        [cell setupDetailHeader:self.activity];

        rv = cell;
    }else if (indexPath.section == GCVIEW_DETAIL_AVGMINMAX_SECTION) {
        GCCellGrid * cell = [GCCellGrid gridCell:tableView];

        //GCActivity * act=self.activity;
        NSArray<NSArray*>*primary = [self displayPrimaryAttributedStrings];
        if( indexPath.row < primary.count){
            NSArray<NSAttributedString*>* attrStrings = primary[indexPath.row];

            //[cell setupForField:field andActivity:act width:tableView.frame.size.width];
            BOOL graphIcon = false;
            if (indexPath.row < self.organizedMatchingField.count && [self.organizedMatchingField[indexPath.row] isKindOfClass:[GCField class]]) {
                graphIcon = true;
            }
            [cell setupForAttributedStrings:attrStrings graphIcon:graphIcon width:tableView.frame.size.width];
        }
        rv = cell;
    }else if(indexPath.section == GCVIEW_DETAIL_LOAD_SECTION){
        GCCellActivityIndicator *cell = [GCCellActivityIndicator activityIndicatorCell:tableView parent:[GCAppGlobal web]];
        if ([[GCAppGlobal web] isProcessing]) {
            cell.label.text = [[GCAppGlobal web] currentDescription];
        }else{
            cell.label.text = nil;
        }
        rv = cell;
    }else if(indexPath.section == GCVIEW_DETAIL_MAP_SECTION){
        GCCellMap *cell = (GCCellMap*)[tableView dequeueReusableCellWithIdentifier:@"GCMap"];
        if (cell == nil) {
            cell = [[[GCCellMap alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"GCMap"] autorelease];
        }
        GCActivity * act=self.activity;
        (cell.mapController).activity = act;
        if ([GCAppGlobal configGetBool:CONFIG_MAPS_INLINE_GRADIENT defaultValue:true]) {
            if (!self.choices || (self.choices).choices.count==0) {
                self.choices = [GCTrackFieldChoices trackFieldChoicesWithActivity:self.activity];
            }
            cell.mapController.gradientField = self.choices.current.field;
            if(self.choices.current.statsStyle == gcTrackStatsCompare && self.compareActivity){
                cell.mapController.compareActivity = self.compareActivity;
            }else{
                cell.mapController.compareActivity = nil;
            }
        }else{
            cell.mapController.gradientField = nil;
        }
        [cell.mapController notifyCallBack:nil info:nil];
        rv = cell;
    }else if(indexPath.section == GCVIEW_DETAIL_GRAPH_SECTION){
        if ([self.activity.activityType isEqualToString:GC_TYPE_DAY]) {
            rv = [self tableView:tableView dayGraphCellForRowAtIndexPath:indexPath];
        }else{
            rv = [self tableView:tableView activityGraphCellForRowAtIndexPath:indexPath];
        }
    }else if(indexPath.section == GCVIEW_DETAIL_LAPS_HEADER){
        GCCellGrid * cell = (GCCellGrid*)[tableView dequeueReusableCellWithIdentifier:@"GCGrid"];
        if (cell == nil) {
            cell = [[[GCCellGrid alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"GCGrid"] autorelease];
        }
        [cell setupForRows:2 andCols:1];

        if (self.autolapChoice==nil) {
            self.autolapChoice = [[[GCActivityAutoLapChoices alloc] initWithActivity:self.activity] autorelease];
        }else{
            [self.autolapChoice changeActivity:self.activity];
        }
        [cell labelForRow:0 andCol:0].attributedText = [GCActivityAutoLapChoices currentDescription:self.activity];
        if (self.autolapChoice) {
            [cell labelForRow:1 andCol:0].attributedText = [self.autolapChoice currentDetailledDescription];
        }else{
            [cell labelForRow:1 andCol:0].attributedText = [GCActivityAutoLapChoices defaultDescription];
        }
        [GCViewConfig setupGradientForDetails:cell];
        rv = cell;
    }else if(indexPath.section == GCVIEW_DETAIL_LAPS_SECTION){
        GCCellGrid * cell = (GCCellGrid*)[tableView dequeueReusableCellWithIdentifier:@"GCGrid"];
        if (cell == nil) {
            cell = [[[GCCellGrid alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"GCGrid"] autorelease];
        }

        GCActivity * act=self.activity;

        [cell setupForLap:indexPath.row andActivity:act width:tableView.frame.size.width];
        rv = cell;

    }else if (indexPath.section == GCVIEW_DETAIL_EXTRA_SECTION){
        GCCellGrid * cell = [GCCellGrid gridCell:tableView];
        GCActivity * act=self.activity;
        [cell setupForExtraSummary:act width:tableView.frame.size.width];
        rv = cell;
    }else if (indexPath.section == GCVIEW_DETAIL_WEATHER_SECTION){
        GCCellGrid * cell = [GCCellGrid gridCell:tableView];

        GCActivity * act=self.activity;
        [cell setupForWeather:act width:tableView.frame.size.width];
        rv = cell;
    }else if (indexPath.section == GCVIEW_DETAIL_HEALTH_SECTION){
        GCCellGrid * cell = [GCCellGrid gridCell:tableView];

        GCActivity * act=self.activity;
        GCHealthMeasure * meas=[[GCAppGlobal health] measureForDate:act.date andType:gcMeasureWeight];
        [cell setupForHealthMeasureSummary:meas];
        rv = cell;
    }else{
        rv = [GCCellGrid gridCell:tableView];
    }
	return rv;

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.implementor) {
        return [self.implementor tableView:tableView heightForRowAtIndexPath:indexPath];
    }
    BOOL high = self.tableView.frame.size.height > 600.;

    if (indexPath.section == GCVIEW_DETAIL_AVGMINMAX_SECTION) {
        return 58.;
    }else if(indexPath.section==GCVIEW_DETAIL_MAP_SECTION){
        return high ? 200. : 150.;
    }else if(indexPath.section==GCVIEW_DETAIL_LOAD_SECTION){
        return 100.;
    }else if(indexPath.section==GCVIEW_DETAIL_GRAPH_SECTION){
        return high ? 200. : 150.;
    }else if(indexPath.section == GCVIEW_DETAIL_TITLE_SECTION){
        return 64.;
    }
    return 58.;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.implementor) {
        return [self.implementor tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
    // go into stat page
    // stats page:
    // history/activity either accross  time or for this activity points
    // graph
    // table aggregated by week/month/all, sum or avg
    if (indexPath.section == GCVIEW_DETAIL_MAP_SECTION) {

        [self showMap:self.choices.current.field];
    }else if( indexPath.section == GCVIEW_DETAIL_TITLE_SECTION){
        
    }else if( indexPath.section == GCVIEW_DETAIL_AVGMINMAX_SECTION){
        if (indexPath.row < self.organizedMatchingField.count) {
            GCField * field = self.organizedMatchingField[indexPath.row];
            if ([field isKindOfClass:[GCField class]]) {
                [self showTrackGraph:field];
            }
        }
    }else if(indexPath.section == GCVIEW_DETAIL_GRAPH_SECTION){
        [self.choices nextStyle];
        [self notifyCallBack:nil info:nil];
    }else if( indexPath.section == GCVIEW_DETAIL_LAPS_SECTION){
        UIViewController * ctl = nil;
        if (self.activity.garminSwimAlgorithm) {
            GCActivitySwimLapViewController * lapView = [[GCActivitySwimLapViewController alloc] initWithStyle:UITableViewStylePlain];
            lapView.activity = self.activity;
            lapView.lapIndex = indexPath.row;
            ctl = lapView;
        }else{
            GCActivityLapViewController * lapView = [[GCActivityLapViewController alloc] initWithStyle:UITableViewStylePlain];
            lapView.activity = self.activity;
            lapView.lapIndex = indexPath.row;
            ctl = lapView;
        }
        if ([UIViewController useIOS7Layout]) {
            [UIViewController setupEdgeExtendedLayout:ctl];
        }

        [self.navigationController pushViewController:ctl animated:YES];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        [ctl release];
    }else if( indexPath.section == GCVIEW_DETAIL_HEALTH_SECTION){

    }else if( indexPath.section == GCVIEW_DETAIL_LAPS_HEADER){

        GCActivity * act  = self.activity;
        if (act.garminSwimAlgorithm==false) {
            if (self.autolapChoice==nil) {
                self.autolapChoice = [[[GCActivityAutoLapChoices alloc] initWithActivity:act] autorelease];
            }

            GCCellEntryListViewController * list = [GCViewConfig standardEntryListViewController:[self.autolapChoice choicesDescriptions]
                                                                                                 selected:self.autolapChoice.selected];
            list.entryFieldDelegate = self;
            [self.navigationController pushViewController:list animated:YES];
            [self.navigationController setNavigationBarHidden:NO animated:YES];
        }
    }else if( indexPath.section == GCVIEW_DETAIL_EXTRA_SECTION){
        GCActivityMetaValue * desc = (self.activity).metaData[@"activityDescription"];
        CGFloat width = self.tableView.frame.size.width;
        NSUInteger maxSize = width>321.? 50 : 30;

        if (desc && (desc.display).length>maxSize) {
            [self presentSimpleAlertWithTitle:NSLocalizedString(@"Activity Description", @"Activity Description")
                                      message:desc.display];
        }
    }
}

#pragma mark - Table Header

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (self.implementor) {
        return [self.implementor tableView:tableView viewForHeaderInSection:section];
    }
    return nil;
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (self.implementor) {
        return [self.implementor tableView:tableView heightForHeaderInSection:section];
    }
    return 0.;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (self.implementor) {
        return [self.implementor tableView:tableView titleForHeaderInSection:section];
    }
    return nil;
}

#pragma mark - Setup and call back

-(NSArray<NSAttributedString*>*)attributedStringsForFieldInput:(id)input{
    NSMutableArray * rv = [NSMutableArray array];
    GCActivity * activity = self.activity;
    GCFormattedField * mainF = nil;
    GCField * field = nil;

    if([input isKindOfClass:[NSArray class]]){
        NSArray<GCField*> * inputs = input;
        if (inputs.count>0) {
            field = inputs[0];
            GCNumberWithUnit * mainN = [activity numberWithUnitForField:field];
            mainF = [GCFormattedField formattedField:field.key activityType:activity.activityType forNumber:mainN forSize:16.];
            [rv addObject:mainF.attributedString];

            for (NSUInteger i=1; i<inputs.count; i++) {
                GCField * addField = inputs[i];
                GCNumberWithUnit * addNumber = [activity numberWithUnitForField:addField];
                if (addNumber) {
                    GCFormattedField* theOne = [GCFormattedField formattedField:addField.key activityType:activity.activityType forNumber:addNumber forSize:14.];
                    theOne.valueColor = [GCViewConfig defaultColor:gcSkinDefaultColorSecondaryText];
                    theOne.labelColor = [GCViewConfig defaultColor:gcSkinDefaultColorSecondaryText];
                    if ([addNumber sameUnit:mainN]) {
                        theOne.noUnits = true;
                    }
                    [rv addObject:[theOne attributedString]];
                }
            }
        }
    }else {
        field = [GCField field:input forActivityType:activity.activityType];
        if (field) {
            NSArray<GCField*> * related = [field relatedFields];

            GCNumberWithUnit * mainN = [activity numberWithUnitForField:field];
            mainF = [GCFormattedField formattedField:field.key activityType:activity.activityType forNumber:mainN forSize:16.];
            [rv addObject:mainF];
            for (NSUInteger i=0; i<related.count; i++) {
                GCField * addField = related[i];
                GCNumberWithUnit * addNumber = [activity numberWithUnitForField:addField];
                if (addNumber) {
                    GCFormattedField* theOne = [GCFormattedField formattedField:addField.key activityType:activity.activityType forNumber:addNumber forSize:14.];
                    theOne.valueColor = [GCViewConfig defaultColor:gcSkinDefaultColorSecondaryText];
                    theOne.labelColor = [GCViewConfig defaultColor:gcSkinDefaultColorSecondaryText];
                    if ([addNumber sameUnit:mainN]) {
                        theOne.noUnits = true;
                    }
                    [rv addObject:theOne];
                }
            }
        }else{
            RZLog(RZLogError, @"Invalid input %@", NSStringFromClass([input class]));
        }
    }
    return rv;
}


-(NSArray<NSArray*>*)fitOrBreakupWide:(NSArray<NSAttributedString*>*)attrStrings{
    return @[ attrStrings];
}

-(NSArray<NSArray*>*)fitOrBreakupNarrow:(NSArray<NSAttributedString*>*)attrStrings{
    if (attrStrings.count == 0) {
        return nil;
    }
    NSMutableArray * rv =[NSMutableArray array];
    CGFloat tablewidth = self.tableView.frame.size.width - 35. -10.5;//35 for icon space, 10. for margins

    NSAttributedString * topLeft = attrStrings[0];
    NSAttributedString * bottomLeft = nil;
    NSAttributedString * bottomRight = nil;
    NSAttributedString * topRight = nil;

    NSMutableArray * firstCell = [NSMutableArray arrayWithObject:topLeft];

    if (attrStrings.count > 1) {
        bottomLeft = attrStrings[1];
        [firstCell addObject:bottomLeft];
    }
    BOOL breakup = false;

    if (attrStrings.count > 2) {
        bottomRight = attrStrings[2];
        if (bottomLeft.size.width + bottomRight.size.width > tablewidth) {
            breakup = true;
        }
    }
    if (attrStrings.count > 3) {
        topRight = attrStrings[3];
        if (topRight.size.width + topLeft.size.width > tablewidth*0.95) {
            breakup = true;
        }
    }

    if (breakup) {
        [rv addObject:firstCell];
        if (bottomRight) {
            NSMutableArray * secondCell = [NSMutableArray arrayWithObject:bottomRight];
            if (topRight) {
                [secondCell addObject:topRight];
            }
            [rv addObject:secondCell];
        }
    }else{
        // Keep it together.
        [rv addObject:attrStrings];
    }

    return rv;
}

-(GCActivityOrganizedFields*)displayOrganizedFields{
    if (!self.organizedFields) {
        self.organizedFields = [self.activity groupedFields];

        CGFloat tablewidth = self.tableView.frame.size.width;
        NSMutableArray * packed = [NSMutableArray array];
        NSMutableArray * fields = [NSMutableArray array];
        // Start Packing
        for (NSArray * input in self.organizedFields.groupedPrimaryFields) {
            GCField * field = [GCField field:input[0] forActivityType:_activity.activityType];
            if(field.fieldFlag == gcFieldFlagSumDistance){
                field = [GCField fieldForFlag:gcFieldFlagAltitudeMeters andActivityType:_activity.activityType];
            }
            BOOL validForGraph =( [_activity hasTrackForField:field] && [field validForGraph] );
            NSArray<NSAttributedString*> * attrStrings = [self attributedStringsForFieldInput:input];
            NSArray<NSArray*>* splitUp = tablewidth > 600. ? [self fitOrBreakupWide:attrStrings] : [self fitOrBreakupNarrow:attrStrings];
            [packed addObjectsFromArray:splitUp];
            for (NSUInteger i=0; i<splitUp.count; i++) {
                if(validForGraph && i==0){
                    [fields addObject:field];
                }else{
                    [fields addObject:@(0)];
                }
            }
        }
        self.organizedAttributedStrings = packed;
        self.organizedMatchingField = fields;
        if (self.organizedMatchingField.count != self.organizedAttributedStrings.count) {
            RZLog(RZLogWarning, @"Organized Arrays be equals size");
        }
    }
    return _organizedFields;
}

-(NSArray<NSArray*>*)displayPrimaryAttributedStrings{
    [self displayOrganizedFields];
    return self.organizedAttributedStrings;
}

-(void)publishEvent{
    GCActivity * act = self.activity;
    if (act) {
#ifdef GC_USE_FLURRY
        NSString * actType = act.activityType;
        [Flurry logEvent:EVENT_ACTIVITY_DETAIL withParameters:@{@"Type":actType ?: @"Unknown"}];
        GCActivityMetaValue * deviceVal = [act metaValueForField:GC_META_DEVICE];
        [Flurry logEvent:EVENT_DEVICE withParameters:@{@"device":deviceVal ? (deviceVal.display ?: @"Unknown") : @"Unknown"}];
#endif
        RZLog(RZLogInfo, @"%@", act);
    }
}

/**
 @brief Set alternative implementor if activity needs it, for example tennis
 */
-(void)setupImplementor{
    self.implementor = [GCActivityTennisDetailSource tennisDetailSourceFor:self.activity];
}


-(GCActivity*)compareActivity{
    return [self.organizer validCompareActivityFor:self.activity];
}

-(void)tableReloadData{
    RZLogTrace(@"");

    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

-(void)notifyCallBack:(NSNotification*)notification{
    self.trackStats = nil;

    [self.activity.settings setupWithGlobalConfig:self.activity];
    dispatch_async(dispatch_get_main_queue(), ^(){
        [self.tableView reloadData];
    });
}

-(void)updateUserActivityState:(NSUserActivity *)activity{
    [self.activity updateUserActivity:activity];
}
-(void)selectNewActivity:(GCActivity*)act{

    // THis only needed if brand new activity
    if (![act.activityId isEqualToString:self.activity.activityId]) {
        if (act) {
            RZLog(RZLogInfo, @"%@",act);
        }
        self.activity = act;
        [self setupImplementor];

        self.userActivity = [self.activity spotLightUserActivity];
        [self.userActivity becomeCurrent];
    }

    // Below always do in case the activity change.
    self.organizedFields = nil; // Force regeneration of list of fields to display

    if (self.trackStats && ![_trackStats.activity.activityId isEqualToString:(self.activity).activityId]) {
        self.choices = nil; // Force build of graphs to rotate through in graph cell
        self.trackStats = nil; // Force build of trackstats
    }
    if (![self.choices trackFlagSameAs:self.activity]) {
        self.choices = nil;
        self.trackStats = nil;
    }
    self.autolapChoice = nil;

    [self tableReloadData];
}

-(void)notifyCallBack:(id)theParent info:(RZDependencyInfo*)theInfo{
    NSString * stringInfo = theInfo.stringInfo;
    NSString * compareId  = [self compareActivity].activityId;

    BOOL sameActivityId = [stringInfo isEqualToString:(self.activity).activityId] || (compareId && [stringInfo isEqualToString:compareId]);

    // If notification for a different activityId, don't do anything
    if ((theParent == self.organizer &&
         (sameActivityId || stringInfo == nil)) || // organizer either nil -> all or specific activity Id
        theParent == nil ) {// Use for focusOnactivity -> parent = nil
        // Don't bother if not initialized(view didn't load yet)
        if (self.initialized) {
            [self selectNewActivity:[self.organizer currentActivity]];
        }else{
            self.choices = nil;
        }
    }else{ // Web Update
        if ([theInfo.stringInfo isEqualToString:NOTIFY_ERROR] ||
            [theInfo.stringInfo isEqualToString:NOTIFY_END]) {

            [self performRefreshControl];
        }
    }
}


-(void)performRefreshControl{
    if ([NSThread isMainThread]) {
        [self.refreshControl endRefreshing];
        [self.tableView setContentOffset:CGPointZero animated:YES];
    }else{
        [self performSelectorOnMainThread:@selector(performRefreshControl) withObject:nil waitUntilDone:NO];
    }

}

#pragma mark - Actions

-(UIImage*)exportImage{
    return [GCViewConfig imageWithView:self.view];
}

-(void)showMap:(GCField*)field{
    GCMapViewController *detailViewController = [[GCMapViewController alloc] initWithNibName:nil bundle:nil];
    ECSlidingViewController * detailSliding = [[ECSlidingViewController alloc] initWithNibName:nil bundle:nil];

    detailViewController.gradientField = field;
    detailViewController.activity = self.activity;
    detailViewController.mapType = (gcMapType)[GCAppGlobal configGetInt:CONFIG_USE_MAP defaultValue:gcMapBoth];
    detailViewController.enableTap = true;

    detailSliding.topViewController = detailViewController;
    detailSliding.underLeftViewController = [[[GCSharingViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];

    [UIViewController setupEdgeExtendedLayout:detailViewController];
    [UIViewController setupEdgeExtendedLayout:detailSliding];

    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController pushViewController:detailSliding animated:YES];

    [detailViewController release];
    [detailSliding release];
}

-(void)showTrackGraph:(GCField*)afield{
    GCField * field = afield;

    if (field.fieldFlag == gcFieldFlagSumDistance) {
        field = [GCField fieldForFlag:gcFieldFlagAltitudeMeters andActivityType:self.activity.activityType];
    }

    if (self.trackStats && [self.activity hasTrackForField:field]) {

        ECSlidingViewController * sliding = [[ECSlidingViewController alloc] initWithNibName:nil bundle:nil];
        GCActivityTrackGraphViewController * graphViewController = [[GCActivityTrackGraphViewController alloc] initWithNibName:nil bundle:nil];
        GCActivityTrackGraphOptionsViewController * optionController = [[GCActivityTrackGraphOptionsViewController alloc] initWithStyle:UITableViewStyleGrouped];
        optionController.viewController = graphViewController;
        GCTrackStats * ts = [[[GCTrackStats alloc] init] autorelease];
        [ts updateConfigFrom:self.trackStats];
        [ts setupForField:field xField:nil andLField:nil];

        graphViewController.trackStats = ts;
        graphViewController.activity = self.activity;
        graphViewController.field = field;
        sliding.topViewController = graphViewController;
        sliding.underLeftViewController = [[[UINavigationController alloc] initWithRootViewController:optionController] autorelease];
        [optionController.navigationController setNavigationBarHidden:YES];

        [UIViewController setupEdgeExtendedLayout:sliding];
        [UIViewController setupEdgeExtendedLayout:graphViewController];
        [UIViewController setupEdgeExtendedLayout:sliding.underLeftViewController];

        [self.navigationController pushViewController:sliding animated:YES];
        [self.navigationController setNavigationBarHidden:NO animated:YES];

        [graphViewController release];
        [sliding release];
        [optionController release];
    }
}

#pragma mark - Configure

-(void)swipeRight:(GCCellSimpleGraph *)cell{
    [self.choices previous];
    [self notifyCallBack:nil info:nil];
}
-(void)swipeLeft:(GCCellSimpleGraph*)cell{
    [self.choices next];
    [self notifyCallBack:nil info:nil];
}
-(void)nextGraphField{
    [self.choices next];
}


-(void)cellWasChanged:(id<GCEntryFieldProtocol>)cell{
    [self.autolapChoice changeSelectedTo:[cell selected]];
    [self.tableView reloadData];
}

-(UINavigationController*)baseNavigationController{
    return self.navigationController;
}
-(UINavigationItem*)baseNavigationItem{
    return (self.navigationController).navigationItem;
}

@end
