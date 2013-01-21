//
//  RepoSearchViewController.h
//  Gitos
//
//  Created by Tri Vuong on 1/15/13.
//  Copyright (c) 2013 Crafted By Tri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "User.h"
#import "SpinnerView.h"

@interface RepoSearchViewController : UIViewController <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>
{
    __weak IBOutlet UISearchBar *searchBar;
    __weak IBOutlet UITableView *searchResultsTable;
}

@property(nonatomic, strong) NSString *accessToken;
@property(nonatomic, strong) SpinnerView *spinnerView;
@property(nonatomic, strong) NSMutableArray *searchResults;
@property(nonatomic, strong) User *user;

- (void)performHouseKeepingTasks;
- (void)prepareTableView;

@end
