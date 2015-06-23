//  TicketDetailViewController.m
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


#import "IAHIssueDetailViewController.h"
#import "IAHAttachment.h"
#import "IAHHelpDesk.h"
#import "IAHAttachmentsViewController.h"
#import "IAHAttachmentsListViewController.h"
#import "IAHChatBubbleLeft.h"
#import "IAHChatBubbleRight.h"
#import "IAHLabel.h"
#import "IAHSmallLabel.h"
#import "UIImage+Extended.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface IAHIssueDetailViewController ()

@property (nonatomic, strong) NSMutableArray *attachments;
@property (nonatomic, strong) NSString *enteredMsg;
@property (nonatomic) CGRect messageFrame;
@property UIStatusBarStyle currentStatusBarStyle;

@end

@implementation IAHIssueDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    self.bubbleWidth = 240.0;
    
    self.chatTableView.backgroundColor = [UIColor clearColor];
   
    [self.loadingIndicator startAnimating];
    
    self.bottomMessageView.hidden = YES;
    self.sendReplyIndicator.hidden = YES;
    self.sendButton.enabled = NO;
    self.sendButton.alpha = 0.5;
    self.currentStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
    
    if (self.fromPush) {
        UINavigationBar *navbar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
        [[IAHAppearance instance] customizeNavigationBar:navbar];
        
        UINavigationItem *navigItem = [[UINavigationItem alloc] initWithTitle:@""];
        UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(closeButtonPressed)];
        navigItem.leftBarButtonItem = closeItem;
        navbar.items = [NSArray arrayWithObjects: navigItem,nil];
        [self.view addSubview:navbar];
    }
    [self addMessageView];

    /**
        Single tapping anywhere on the chat table view to hide the keyboard
     */
    UITapGestureRecognizer *hideKeyboard = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    hideKeyboard.numberOfTapsRequired = 1;
    [self.chatTableView addGestureRecognizer:hideKeyboard];
}

-(void)viewWillAppear:(BOOL)animated{
    [[UIApplication sharedApplication] setStatusBarStyle:self.currentStatusBarStyle];
    [self.ticketSource prepareTicket];
    [self getTicketUpdates];
    [[IAHHelpDesk instance] setConversationLaunched:YES];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if(self.enteredMsg){
        self.messageText.text = self.enteredMsg;
        self.enteredMsg = nil;
    }
  //  [self.messageText becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    /**
     To detect when user is sliding the screen to go back - iOS7 feature
     */
    [[IAHHelpDesk instance] setConversationLaunched:NO];
     if([self isMovingFromParentViewController]){
        self.messageText.text = @"";
        [self.messageText resignFirstResponder];
        [self removeInsetsOnChatTable];
    }
}


#pragma marks - View populating methods

- (void)addMessageView {
    if(!self.messageText){
        self.messageText = [[IAHGrowingTextView alloc] initWithFrame:CGRectMake(self.messageTextSuperView.frame.origin.x, self.messageTextSuperView.frame.origin.y, self.messageTextSuperView.frame.size.width, self.messageTextSuperView.frame.size.height)];
        self.messageText.editable = YES;
    }else{
        CGRect msgTextFrame = self.messageText.frame;
        msgTextFrame.size.width = self.messageTextSuperView.frame.size.width;
        msgTextFrame.size.height = self.messageTextSuperView.frame.size.height;
        self.messageText.frame = msgTextFrame;
    }
    self.messageText.isScrollable = NO;
    self.messageText.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
	self.messageText.minNumberOfLines = 1;
	self.messageText.maxNumberOfLines = 10;
    self.messageText.returnKeyType = UIReturnKeyDone;
    
    UIInterfaceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (UIInterfaceOrientationIsLandscape(currentOrientation)){
        self.messageText.maxHeight = 50.0f;
    }else{
        self.messageText.maxHeight = 200.0f;
    }
    
	self.messageText.returnKeyType = UIReturnKeyGo;
	self.messageText.font = [UIFont systemFontOfSize:14.0f];
	self.messageText.delegate = self;
    self.messageText.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
    
    self.messageText.textColor = [UIColor darkGrayColor];
    self.messageText.placeholder = @"Reply here";
    self.messageText.internalTextView.layer.cornerRadius = 5.0;
    [self.messageText removeFromSuperview];
    [self.bottomMessageView addSubview:self.messageText];
    
    self.sendButton.titleLabel.textColor = [UIColor darkGrayColor];
}

/**
    Callback method whenever the messageTextView increases in size, accordingly push the chat tableView up
 */
- (void)growingTextView:(IAHGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    float diff = (growingTextView.frame.size.height - height);
    
    CGRect msgViewFrame = self.bottomMessageView.frame;
    msgViewFrame.size.height -= diff;
    msgViewFrame.origin.y += diff;
    
    self.messageText.frame = growingTextView.frame;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, self.chatTableView.contentInset.bottom - diff , 0.0);
    self.chatTableView.contentInset = contentInsets;
    self.chatTableView.scrollIndicatorInsets = contentInsets;
    
    [self scrollDownToLastMessage:YES];
    
    self.bottomMessageView.frame = msgViewFrame;
	
}

-(void)growingTextViewDidChange:(IAHGrowingTextView *)growingTextView{
 
    IAHTextViewInternal* textView =(IAHTextViewInternal*)self.messageText.internalTextView;
    [textView textChanged:nil];
    
    if([growingTextView.text stringByReplacingOccurrencesOfString:@" " withString:@""].length > 0){
        self.sendButton.enabled = YES;
        self.sendButton.alpha = 1.0;
    }else{
        self.sendButton.enabled = NO;
        self.sendButton.alpha = 0.5;
    }
}

-(void)growingTextViewDidEndEditing:(IAHGrowingTextView *)growingTextView{
    
    if([growingTextView.text stringByReplacingOccurrencesOfString:@" " withString:@""].length > 0){
        self.sendButton.enabled = YES;
        self.sendButton.alpha = 1.0;
    }else{
        self.sendButton.enabled = NO;
        self.sendButton.alpha = 0.5;
    }
}

-(void)removeInsetsOnChatTable{
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, 0 , 0.0);
    self.chatTableView.contentInset = contentInsets;
    self.chatTableView.scrollIndicatorInsets = contentInsets;
    
    [self scrollDownToLastMessage:YES];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self removeInsetsOnChatTable];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
   // [self.chatTableView reloadData];
    CGRect msgTextFrame = self.messageText.frame;
    msgTextFrame.size.width = self.messageTextSuperView.frame.size.width;
    msgTextFrame.size.height = self.messageTextSuperView.frame.size.height;
    self.messageText.frame = msgTextFrame;
    UIInterfaceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (UIInterfaceOrientationIsLandscape(currentOrientation)){
        self.messageText.maxHeight = 50.0f;
    }else{
        self.messageText.maxHeight = 200.0f;
    }
    
    NSString *msgAdded = self.messageText.text;
    self.messageText.text = msgAdded;
    
    [self.messageText setNeedsDisplay];
    [self.messageText.internalTextView setNeedsDisplay];
}

-(void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    
    [[IAHAppearance instance] customizeNavigationBar:viewController.navigationController.navigationBar];
}

#pragma mark - Attachment functions

/**
    Shows the attachment selected when adding a reply
 */
- (void)showAttachments{
    
    if(self.attachments.count == 0){
        self.messageText.internalTextView.inputAccessoryView = nil;
        [self.messageText.internalTextView reloadInputViews];
        UIImage *attachImage = [UIImage imageNamed:@"attach.png"];
        [self.addAttachmentButton setImage:attachImage forState:UIControlStateNormal];
    }else{
        IAHAttachment *attachment = [self.attachments objectAtIndex:0];
        [self.addAttachmentButton setImage:attachment.attachmentImage forState:UIControlStateNormal];
    }
}

- (IBAction)addAttachment:(id)sender{
    
    if(self.attachments == nil || self.attachments.count == 0){
        [self openImagePicker];
    }else{
        //Show UIAction sheet menu
        UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:
                                @"Change",
                                @"Delete",
                                nil];
        if ([IAHAppearance isIPad]) {
            [popup showFromRect:[self.addAttachmentButton bounds] inView:self.addAttachmentButton animated:YES];
        }
        else {
            [popup showInView:[self.navigationController view]];
        }
    }
}

- (void) closeButtonPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    switch(buttonIndex){
        case 0:
            [self openImagePicker];
            break;
        case 1:
            [self.attachments removeAllObjects];
            [self showAttachments];
            break;
        case 2:
            [actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
            break;
        default:break;
    }
}

- (void)openImagePicker {
    
    self.enteredMsg = self.messageText.text;
    self.messageText.text = @"";
    [self.messageText resignFirstResponder];
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.allowsEditing = NO;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    
    if(self.attachments == nil){
        self.attachments = [[NSMutableArray alloc] init];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
        
    IAHAttachment *attachment = [[IAHAttachment alloc] init];
    attachment.mimeType = @"image/png";

    [self.attachments removeAllObjects]; // we are handling only 1 attachment for now.
    
    UIImage* img = [[info objectForKey:UIImagePickerControllerOriginalImage] fixOrientationAndSize];
    NSData *data = UIImagePNGRepresentation(img);
    attachment.attachmentData = data;
    attachment.fileName = @"attachment";
    attachment.attachmentImage = img;
    [self.attachments addObject:attachment];
    [self showAttachments];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    
    [self dismissViewControllerAnimated:YES completion:nil];
    self.messageText.text = self.enteredMsg;
}

- (void)openAttachment:(UIButton *)sender{
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.chatTableView];
    NSIndexPath *indexPath = [self.chatTableView indexPathForRowAtPoint:buttonPosition];

//    NSIndexPath *indexPath = [self.chatTableView indexPathForCell:cell];
    IAHUpdate* updateToShow = [self.ticketSource updateAtPosition:indexPath.section];
    if(updateToShow.attachments && updateToShow.attachments.count > 0){
        if(updateToShow.attachments.count > 1){
            [self performSegueWithIdentifier:@"showAttachments" sender:indexPath];
        }else{
            [self performSegueWithIdentifier:@"showOneAttachment" sender:indexPath];
        }
    }
}

#pragma mark - Keyboard functions
#pragma mark - keyboard movements
- (void)keyboardFrameWillChange:(NSNotification *)notification
{
    NSDictionary* info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.messageViewConstraint.constant = 0.0f + kbSize.height;
                         [self.view layoutIfNeeded];
                     }];
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.messageViewConstraint.constant = 0.0f;
                         [self.view layoutIfNeeded];
                     }];
    
}

- (void)hideKeyboard {
    [self.messageText resignFirstResponder];
}

#pragma mark - Ticket fetch and update functions

-(void)getTicketUpdates {
    __block NSUInteger oldCount = [self.ticketSource updateCount];
    [self.ticketSource prepareUpdate:self.user success:^{
        self.bottomMessageView.hidden = NO;
        [self.loadingIndicator stopAnimating];
         self.loadingIndicator.hidden = YES;
        
        if ([self.ticketSource updateCount] > oldCount) {
            [self.chatTableView reloadData];
            [self scrollDownToLastMessage:oldCount!=0];
        }
        
        if ([[IAHHelpDesk instance] conversationLaunched])
            [NSTimer scheduledTimerWithTimeInterval:10.0
                                         target:self
                                       selector:@selector(getTicketUpdates)
                                       userInfo:nil
                                        repeats:NO];

    } failure:^(NSError* e){
        self.bottomMessageView.hidden = NO;
        [self.loadingIndicator stopAnimating];
        self.loadingIndicator.hidden = YES;
        UIAlertView* errorAlert = [[UIAlertView alloc] initWithTitle:@"Couldnt get replies" message:@"There was some error loading the replies. Please check if your internet connection is ON." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        if ([[IAHHelpDesk instance] conversationLaunched])
            [errorAlert show];
    }];
}

-(void)updateTicket:(NSString *)ticketMessage{
    
    IAHTicketReply *tickUpdate = [[IAHTicketReply alloc] init];
    tickUpdate.content = self.messageText.text;
    if(self.attachments != nil && self.attachments.count > 0){
        tickUpdate.attachments = self.attachments;
    }
    self.sendButton.hidden = YES;
    self.sendReplyIndicator.hidden = NO;
    [self.sendReplyIndicator startAnimating];
    [self.messageText resignFirstResponder];
    IAHIssueDetailViewController *weakSelf = self;

    [self.ticketSource addReply:tickUpdate byUser:self.user getUpdatesFromTime:0l success:^{
        [weakSelf onTicketUpdated];
    }failure:^(NSError* e){
        [weakSelf onTicketUpdateFailed];
    }];
}

-(void)onTicketUpdated{
    [self.sendReplyIndicator stopAnimating];
    self.sendReplyIndicator.hidden = YES;
    self.sendButton.hidden = NO;
    [self.attachments removeAllObjects];
    [self showAttachments];
    [self.chatTableView reloadData];
    self.messageText.text = @"";
    [self.messageText resignFirstResponder];
    [self removeInsetsOnChatTable];
}

-(void)onTicketUpdateFailed{
    [self.sendReplyIndicator stopAnimating];
    self.sendReplyIndicator.hidden = YES;
    self.sendButton.hidden = NO;
    [self removeInsetsOnChatTable];
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Oops! Some error." message:@"There was some error in sending your reply. Is your internet ON? Can you try after sometime?" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alertView show];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.ticketSource updateCount];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if(indexPath.row == 2){
        UITableViewCell *cell = [self getInfoCellForTable:tableView forIndexPath:indexPath];
        return cell;
    }else if(indexPath.row == 1){
        UITableViewCell *cell = [self getMessageCellForTable:tableView forIndexPath:indexPath];
        return cell;
    }else{
        UITableViewCell *cell = [self getSenderInfoCellForTable:tableView forIndexPath:indexPath];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 2 || indexPath.row == 0){
        return 32.0;
    }
    IAHUpdate* updateToShow = [self.ticketSource updateAtPosition:indexPath.section];
    NSString *messageText = updateToShow.content;
    
    if(messageText.length > 0){
        UIFont *bubbleTextFont = [[[IAHHelpDesk instance] appearance] getBubbleTextFont];
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                bubbleTextFont, NSFontAttributeName,
                                                [UIColor blackColor], NSForegroundColorAttributeName,
                                                nil];
     
        NSAttributedString *msgText = [[NSAttributedString alloc] initWithString:messageText attributes:attrsDictionary];
        CGSize maximumLabelSize = CGSizeMake(self.bubbleWidth - 20, CGFLOAT_MAX);
        CGRect newTextSize = [msgText boundingRectWithSize:maximumLabelSize options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
        return newTextSize.size.height + 15;
    }
    return 50.0;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [self.chatTableView cellForRowAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    IAHUpdate* updateToShow = [self.ticketSource updateAtPosition:indexPath.section];
    if(updateToShow.attachments != nil && updateToShow.attachments.count > 0){
        [self performSegueWithIdentifier:@"showAttachments" sender:indexPath];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.chatTableView.frame.size.width, 5.0)];
    footerView.backgroundColor = [UIColor clearColor];
    return footerView;
}

- (void)refreshCell:(UITableViewCell *)cell{

    UILabel *senderLabel = (UILabel *)[cell viewWithTag:1];
    UITextView *messageLabel = (UITextView *)[cell viewWithTag:2];
    UILabel *timeLabel = (UILabel *)[cell viewWithTag:3];
    UIView *messageView = (UIView *)[cell viewWithTag:4];
    UILabel *attachmentLabel = (UILabel *)[cell viewWithTag:5];

    if(senderLabel){
        [senderLabel removeFromSuperview];
    }

    if(messageLabel){
        [messageLabel removeFromSuperview];
    }

    if(timeLabel){
        [timeLabel removeFromSuperview];
    }
    
    if(messageView){
        [messageView removeFromSuperview];
    }
    
    if(attachmentLabel){
        [attachmentLabel removeFromSuperview];
    }
}

-(UITableViewCell *)getInfoCellForTable:(UITableView *)tableView forIndexPath:(NSIndexPath *)indexPath{
    
    IAHUpdate* updateToShow = [self.ticketSource updateAtPosition:indexPath.section];
    static NSString *CellIdentifier; // = @"InfoCell";
    
    if(updateToShow.updateType == HATypeStaffReply) {
        CellIdentifier = @"MessageDetails_Left";
    }else {
        CellIdentifier = @"MessageDetails_Right";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    
    UIView *cellView = [cell viewWithTag:3];
    NSArray *subviews = [cellView subviews];
    for(UIView *view in subviews){
        [view removeFromSuperview];
    }
    
    cellView.backgroundColor = [UIColor clearColor];
    IAHSmallLabel *timestamp = [[IAHSmallLabel alloc] initWithFrame:CGRectMake(cellView.frame.size.width - 120.0, -6.0, 120.0, 20.0)];
    timestamp.font = [UIFont fontWithName:timestamp.font.fontName size:10.0];
    timestamp.textAlignment = NSTextAlignmentRight;
    timestamp.text =   [updateToShow updatedAtString];
    [cellView addSubview:timestamp];
    
    if(updateToShow.attachments != nil && updateToShow.attachments.count > 0){
        UIButton *attachmentBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30.0, 25.0)];
        UIImage *btnImage = [UIImage imageNamed:@"attach.png"];
        [attachmentBtn setBackgroundImage:btnImage forState:UIControlStateNormal];
        [attachmentBtn addTarget:self action:@selector(openAttachment:) forControlEvents:UIControlEventTouchUpInside];
        [cellView addSubview:attachmentBtn];
    }
    [cell.contentView addSubview:cellView];
    return cell;
}

-(UITableViewCell *)getMessageCellForTable:(UITableView *)tableView forIndexPath:(NSIndexPath *)indexPath{
    
    IAHUpdate* updateToShow = [self.ticketSource updateAtPosition:indexPath.section];
    static NSString *CellIdentifier; // = @"MessageCell";
    
    if(updateToShow.updateType == HATypeStaffReply) {
        CellIdentifier = @"MessageCell_Left";
    }else {
        CellIdentifier = @"MessageCell_Right";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    UIView *messageView;
    UITextView *messageTextView;
    
    messageView = [cell viewWithTag:3];
    CGRect bubbleFrame = messageView.frame;
    bubbleFrame.size.height = cell.frame.size.height;
    messageView.frame = bubbleFrame;
    
    if(updateToShow.updateType == HATypeStaffReply){
        messageTextView = [((IAHChatBubbleLeft *)messageView) getChatTextView];
    }else{
        messageTextView = [((IAHChatBubbleRight *)messageView) getChatTextView];
    }
    
    cell.contentView.backgroundColor = [UIColor clearColor];
    
    NSString *messageContent = [updateToShow content];
    if([messageContent stringByReplacingOccurrencesOfString:@" " withString:@""].length == 0){
        messageContent = @"No Message";
        messageTextView.textColor = [UIColor grayColor];
        messageTextView.font = [UIFont fontWithName:messageTextView.font.fontName size:12.0];
    }
    
    messageTextView.text = messageContent;
    
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

-(UITableViewCell *)getSenderInfoCellForTable:(UITableView *)tableView forIndexPath:(NSIndexPath *)indexPath{
    
    IAHUpdate* updateToShow = [self.ticketSource updateAtPosition:indexPath.section];
    
    static NSString *CellIdentifier; // = @"MessageDetails_Right";
    
    if(updateToShow.updateType == HATypeStaffReply) {
        CellIdentifier = @"InfoCell_Left";
    }else {
        CellIdentifier = @"InfoCell_Right";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    
    UIView *cellView = [cell viewWithTag:3];
    NSArray *subviews = [cellView subviews];
    for(UIView *view in subviews){
        [view removeFromSuperview];
    }
    
    IAHSmallLabel *nameLabel = [[IAHSmallLabel alloc] init];
    nameLabel.tag = 1;
    
    NSString *nameString = @"";
    nameLabel.frame = CGRectMake(0, 4.0, 120.0, 20.0);
    if(updateToShow.updateType == HATypeStaffReply){
        if(updateToShow.from){
            nameString = updateToShow.from;
        }else{
            nameString = @"Staff";
        }
    }else{
        nameString = @"Me";
    }
    [cellView addSubview:nameLabel];
    //Overriding timestamp font and size
    nameLabel.font = [UIFont fontWithName:nameLabel.font.fontName size:10.0];
    nameLabel.text = nameString;
    
    return cell;
}

/**
    Scrolls the table view to the last item
 */
- (void)scrollDownToLastMessage:(BOOL)animated
{
    NSIndexPath *lastIndexPath = [self lastIndexPath];
    if([self.chatTableView numberOfSections] > 0){
        [self.chatTableView scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

/**
    Gets the last index path of the table view
 */
- (NSIndexPath *)lastIndexPath
{
    NSInteger lastSectionIndex = MAX(0, [self.chatTableView numberOfSections] - 1);
    NSInteger lastRowIndex = MAX(0, [self.chatTableView numberOfRowsInSection:lastSectionIndex] - 1);
    return [NSIndexPath indexPathForRow:lastRowIndex inSection:lastSectionIndex];
}

- (IBAction)sendReply:(id)sender{
    NSString *replyMsg = self.messageText.text;
    [self updateTicket:replyMsg];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    NSIndexPath *indexPath = (NSIndexPath *)sender;
    IAHUpdate *update = [self.ticketSource updateAtPosition:indexPath.section];
    if(update.attachments.count > 1){
        IAHAttachmentsListViewController *viewController = (IAHAttachmentsListViewController *)[segue destinationViewController];
        viewController.attachmentsList = update.attachments;
    }else if(update.attachments.count == 1){
        IAHAttachmentsViewController *attachmentsVC = (IAHAttachmentsViewController *)[segue destinationViewController];
        IAHAttachment *attachment = [update.attachments objectAtIndex:0];
        attachmentsVC.attachment = attachment;
    }
   
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

