//  HAZendDeskMainViewController.m
//
//Copyright (c) 2014 HelpStack (http://helpstack.io)
//
//Permission is hereby granted, free of charge, to any person obtaining a cop
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in
//all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//THE SOFTWARE.

#import "IAHMainListViewController.h"
#import "IAHArticleDetailViewController.h"
#import "IAHNewIssueViewController.h"
#import "IAHUserDetailsViewController.h"
#import "IAHGroupViewController.h"
#import "IAHHelpDesk.h"
#import "IAHTicketReply.h"
#import "IAHIssueDetailViewController.h"
#import "IAHTicketDetailViewControlleriPad.h"
#import "IAHKBSource.h"
#import "IAHTicketSource.h"
#import "IAHAppearance.h"
#import "IAHTableView.h"
#import "IAHTableViewCell.h"
#import "IAHLabel.h"
#import "IAHTableViewHeaderCell.h"
#import <MessageUI/MessageUI.h>
#import "IAHActivityIndicatorView.h"
#import "IAHReportIssueCell.h"
#import "IAHUtility.h"

/*
 To report issue using email:
 ->If ticketDelegate is not set, default email client is open and mail is prepared using given companyEmailAddress.
 */

@interface IAHMainListViewController () <HSNewIssueViewControllerDelegate, MFMailComposeViewControllerDelegate> {
    UINavigationController* newTicketNavController;
}

@property(nonatomic, strong) IAHActivityIndicatorView *loadingView;

@end

@implementation IAHMainListViewController

BOOL finishedLoadingKB = NO;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.kbSource = [IAHKBSource createInstance];
    self.ticketSource = [IAHTicketSource instance];
    
    self.loadingView = [[IAHActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20.0, 20.0)];
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.loadingView];
    self.navigationItem.rightBarButtonItem = rightBarButton;
    
    IAHAppearance* appearance = [[IAHHelpDesk instance] appearance];
    self.view.backgroundColor = [appearance getBackgroundColor];
    self.tableView.tableFooterView = [UIView new];
    // Fetching KB and Tickets
    [self startLoadingAnimation];
    [self refreshKB];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

#pragma mark - KBArticles and Issues Fetch

- (void)refreshKB
{
    // Fetching latest KB article from server.
    [self.kbSource prepareKB:^{
        finishedLoadingKB = YES;
        [self onKBorTicketsFetched];
        [self reloadKBSection];
    } failure:^(NSError* e){
        finishedLoadingKB = YES;
        [self onKBorTicketsFetched];

        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Couldnt load articles" message:@"Error in loading articles. Please check your internet connection." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alertView show];
    }];
}

- (void)reloadKBSection
{
    NSIndexSet *sectionSet = [NSIndexSet indexSetWithIndex:0];
    [self.tableView reloadSections:sectionSet withRowAnimation:UITableViewRowAnimationNone];
}

- (void)reloadTicketsSection{
    [self.tableView reloadData];
}

- (void)onKBorTicketsFetched{
    [self stopLoadingAnimation];
}

- (void)startLoadingAnimation
{
    self.loadingView.hidden = NO;
    [self.loadingView startAnimating];
}

- (void)stopLoadingAnimation
{
    [self.loadingView stopAnimating];
    self.loadingView.hidden = YES;
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
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return 1;
    }else {
        return 3;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.kbSource kbCount:HAGearTableTypeSearch];
    }else{
        if (section == 0) {
            return [self.kbSource kbCount:HAGearTableTypeDefault];
        }
        else if (section == 1) {
            return 0;
        }
        else {
            return 1;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        
        static NSString *CellIdentifier = @"Cell";
        
        IAHTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[IAHTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
        
        IAHKBItem* article = [self.kbSource table:HAGearTableTypeSearch kbAtPosition:indexPath.row];
        cell.textLabel.text = article.title;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        
        return cell;
        
    } else {
        static NSString *CellIdentifier = @"HelpCell";
        static NSString *ReportCellIdentifier = @"Contact support";
        if (indexPath.section == 2) {
            IAHReportIssueCell *cell = [tableView dequeueReusableCellWithIdentifier:ReportCellIdentifier];
            if (cell == nil) {
                cell = [[IAHReportIssueCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ReportCellIdentifier];
            }
            if ([self.ticketSource shouldShowUserDetailsFormWhenCreatingTicket])
                cell.textLabel.text = @"Create Issue";
            else
                cell.textLabel.text = @"View Issue";

            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            
            return cell;
        }
        else {
            IAHTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[IAHTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            }
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            
            if (indexPath.section == 0) {
                IAHKBItem* article = [self.kbSource table:HAGearTableTypeDefault kbAtPosition:indexPath.row];
                cell.textLabel.text = article.title;
            }

            return cell;
        }
        return nil;
    }
    
}

#pragma mark - TableView Delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        [self table:HAGearTableTypeSearch articleSelectedAtIndexPath:indexPath.row];
        
    } else {
        if (indexPath.section == 0) {
            [self table:HAGearTableTypeDefault articleSelectedAtIndexPath:indexPath.row];
        } else {
            [self reportIssue];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{

    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return 0.0;
    }

    return 30.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{

    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return nil;
    }


    IAHTableViewHeaderCell* cell = nil;
    CGRect tableRect = CGRectMake(0, 0, self.tableView.frame.size.width, 30.0);
    if(section == 0){
        cell = [[IAHTableViewHeaderCell alloc] initWithFrame:tableRect];
        cell.titleLabel.text = @"FAQ";
    } else {
        return nil;
    }

    return cell;
}



- (void)table:(HAGearTableType)table articleSelectedAtIndexPath:(NSInteger) position
{
    IAHKBItem* selectedKB = [self.kbSource table:table kbAtPosition:position];
    HSKBItemType type = HSKBItemTypeArticle;
    type = selectedKB.itemType;

    // KB is section, so need to call another tableviewcontroller
    if (type == HSKBItemTypeSection) {
        IAHKBSource* newSource = [self.kbSource sourceForSection:selectedKB];
        IAHGroupViewController* controller = [self.storyboard instantiateViewControllerWithIdentifier:@"IAHGroupController"];
        controller.kbSource = newSource;
        controller.selectedKB = selectedKB;
        [self.navigationController pushViewController:controller animated:YES];
    }
    else {
        IAHArticleDetailViewController* controller = [self.storyboard instantiateViewControllerWithIdentifier:@"IAHArticleController"];
        controller.article = selectedKB;
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ReportIssue"]) {
        IAHNewIssueViewController* reportViewController = (IAHNewIssueViewController*) [segue destinationViewController];
        reportViewController.delegate = self;
        reportViewController.ticketSource = self.ticketSource;
    }
    else if ([[segue identifier] isEqualToString:@"MyIssueDetail"]) {
        IAHIssueDetailViewController* viewController = (IAHIssueDetailViewController*)segue.destinationViewController;
        viewController.user = sender;
        viewController.ticketSource = self.ticketSource;
    }
}

- (void)reportIssue{
    [self startReportAnIssue];
}

- (void) startReportAnIssue {
    IAHTicketReply* ticket = [[IAHTicketReply alloc] init];
    UIBarButtonItem* cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(newTicketCancelPressed:)];
    
    if ([self.ticketSource shouldShowUserDetailsFormWhenCreatingTicket] == true) {

        NSString* storyboardId = @"IAHUserDetailsController";
        
        IAHUserDetailsViewController* controller = [self.storyboard instantiateViewControllerWithIdentifier:storyboardId];
        controller.createNewTicket = ticket;
        controller.delegate = self;
        controller.ticketSource = self.ticketSource;
        controller.navigationItem.leftBarButtonItem = cancelItem;
        newTicketNavController = [[UINavigationController alloc] initWithNavigationBarClass:[UINavigationBar class] toolbarClass:[UIToolbar class]];
        newTicketNavController.viewControllers = [NSArray arrayWithObject:controller];
        newTicketNavController.modalPresentationStyle = UIModalPresentationCurrentContext;
        
        [self presentViewController:newTicketNavController animated:YES completion:nil];

    } else {
        [self performSegueWithIdentifier:@"MyIssueDetail" sender:[self.ticketSource user]];
    }
}


- (IBAction)cancelPressed:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)newTicketCancelPressed:(id)sender
{
    [newTicketNavController dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterArticlesforSearchString:searchString];
    return NO;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView
{
    UIView* footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 100)];

    UIButton* reportIssueButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 5, footerView.frame.size.width, 30)];
    [reportIssueButton setTitle:@"Report An Issue" forState:UIControlStateNormal];
    [reportIssueButton setTitleColor:[UIColor colorWithRed:233.0/255.0f green:76.0/255.0f blue:67.0/255.0f alpha:1.0] forState:UIControlStateNormal];
    [reportIssueButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [[reportIssueButton titleLabel] setFont:[UIFont boldSystemFontOfSize:14]];
    [reportIssueButton addTarget:self action:@selector(reportIssueFromSearch) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:reportIssueButton];

    tableView.tableFooterView = footerView;
}

- (void)reportIssueFromSearch {
    //dismiss search
    [self.searchDisplayController setActive:NO animated:NO];
    [self reportIssue];
}

- (void)filterArticlesforSearchString:(NSString*)string
{
    [self.kbSource filterKBforSearchString:string success:^{
        [self.searchDisplayController.searchResultsTableView reloadData];
    } failure:^(NSError* e){
        
    }];
}


- (void)onNewIssueSubmited:(IAHTicketReply *)createdTicket
{
    NSIndexSet *sectionSet = [NSIndexSet indexSetWithIndex:2];
    [self.tableView reloadSections:sectionSet withRowAnimation:UITableViewRowAnimationNone];
    
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Success." message:@"Your issue has been created and raised!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alertView show];
}

@end
