//  HAZendDeskReportViewController.m
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

#import "IAHNewIssueViewController.h"
#import "IAHTextViewInternal.h"
#import "IAHUserDetailsViewController.h"
#import "IAHHelpDesk.h"
#import "IAHAttachment.h"
#import "IAHNewIssueAttachmentViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "IAHUtility.h"
#import "UIImage+Extended.h"
#import "IAHActivityIndicatorView.h"

@interface IAHNewIssueViewController ()<UITextFieldDelegate, UITextViewDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate> {
    IAHTextViewInternal* messageField;
    UIButton *attachmentImageBtn;
    UIBarButtonItem* submitBarItem;
    UIBarButtonItem* loadingBarItem;
}

@property (nonatomic, strong) UIView *messageAttachmentView;
@property (nonatomic, strong) UIButton *addAttachment;
@property (nonatomic, strong) NSMutableArray *attachments;
@property UIStatusBarStyle currentStatusBarStyle;
@property(nonatomic, strong) IAHActivityIndicatorView *loadingView;


@end

@implementation IAHNewIssueViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    submitBarItem = [[UIBarButtonItem alloc] initWithTitle:@"Submit" style:UIBarButtonItemStyleDone target:self action:@selector(submitPressed:)];
    self.navigationItem.rightBarButtonItem = submitBarItem;
    
    
    self.loadingView = [[IAHActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20.0, 20.0)];
    loadingBarItem = [[UIBarButtonItem alloc] initWithCustomView:self.loadingView];

    IAHAppearance* appearance = [[IAHHelpDesk instance] appearance];
    self.view.backgroundColor = [appearance getBackgroundColor];

    self.currentStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
}

-(void)viewWillAppear:(BOOL)animated{
    [[UIApplication sharedApplication] setStatusBarStyle:self.currentStatusBarStyle];
}

-(void)setInputAccessoryView{
    self.messageAttachmentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)nextPressed:(id)sender {
    [self performSegueWithIdentifier:@"NameAndEmailSegue" sender:self];
}

- (IBAction)addAttachments:(id)sender {
    if(self.attachments != nil && self.attachments.count > 0){

        //remove attachment.

        self.attachments = nil;
    }else{

        //add attachment.

        [self startMediaBrowserFromViewController: self
                                usingDelegate: self];
    }
}

- (void)startLoadingAnimation
{
    self.loadingView.hidden = NO;
    [self.loadingView startAnimating];
    self.navigationItem.rightBarButtonItem = loadingBarItem;
}

- (void)stopLoadingAnimation
{
    [self.loadingView stopAnimating];
    self.loadingView.hidden = YES;
    self.navigationItem.rightBarButtonItem = submitBarItem;
}

- (IBAction)submitPressed:(id)sender {
    //Validate for name, email, subject and message

    UIBarButtonItem* submitButton = sender;
    if([self checkValidity]) {
        submitButton.enabled = NO;
        self.createNewTicket.content = messageField.text;
        self.createNewTicket.attachments = self.attachments;

        [self startLoadingAnimation];
        [self.ticketSource createNewTicket:self.createNewTicket success:^{
            [self stopLoadingAnimation];
            submitButton.enabled = YES;
            [self.delegate onNewIssueSubmited:self.createNewTicket];
            [self dismissViewControllerAnimated:YES completion:nil];
        } failure:^(NSError* e){
            [self stopLoadingAnimation];
            submitButton.enabled = YES;
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Oops! Some error." message:@"There was some error in reporting your issue. Is your internet ON? Can you try after sometime?" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alertView show];
            
        }];
    }
}

- (IBAction)cancelPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL) checkValidity {
    if(messageField.text.length == 0) {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Missing Message" message:@"Please enter a message" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        return NO;
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    IAHAttachment *attachment = [self.attachments objectAtIndex:0];

    IAHNewIssueAttachmentViewController *attachmentsView = (IAHNewIssueAttachmentViewController *)[segue destinationViewController];
    attachmentsView.attachmentImage = attachment.attachmentImage;
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
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *MessageCellIdentifier = @"Cell_Message";
    if(indexPath.row == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MessageCellIdentifier forIndexPath:indexPath];
        messageField = (IAHTextViewInternal*) [cell viewWithTag:12];
        messageField.delegate = self;
        [messageField setPlaceholder:@"Message"];
        messageField.displayPlaceHolder = YES;
        messageField.placeholderColor = [UIColor lightGrayColor];

        attachmentImageBtn = (UIButton *) [cell viewWithTag:2];
        [attachmentImageBtn addTarget:self action:@selector(handleAttachment) forControlEvents:UIControlEventTouchUpInside];
        [messageField becomeFirstResponder];

        CGRect messageFrame = messageField.frame;
        messageFrame.size.height = cell.frame.size.height - 40.0;
        messageField.frame = messageFrame;
        return cell;
    }
    
    return nil;
    
}

- (void) textViewDidChange:(UITextView *)textView{
     [((IAHTextViewInternal*) textView) textChanged:nil];
 }

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if([IAHAppearance isIPad]) {
        //For iPad
        if(indexPath.row == 0){
            return self.view.frame.size.height;
        }else{
            return 44.0;
        }
    } else{
        if(indexPath.row == 0) {
            float messageHeight;
            //Instead, get the keyboard height and calculate the message field height
            UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
            if (UIInterfaceOrientationIsLandscape(orientation))
            {
                messageHeight = 68.0;
            }
            else {
                
                if ([IAHAppearance isTall]) {
                    messageHeight = 249.0f;
                }else{
                    messageHeight = 155.0f + 44.0;
                }
            }
            // return self.view.bounds.size.height - 88.0;
            return messageHeight;
        }
        return 0.0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 1.0;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    [[IAHAppearance instance] customizeNavigationBar:viewController.navigationController.navigationBar];
}


- (BOOL)startMediaBrowserFromViewController: (UIViewController*) controller
                               usingDelegate: (id <UIImagePickerControllerDelegate,
                                               UINavigationControllerDelegate>) delegate {
    
    if (([UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypeSavedPhotosAlbum] == NO)
        || (delegate == nil)
        || (controller == nil))
        return NO;
    
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    
    // Displays saved pictures and movies, if both are available, from the
    // Camera Roll album.
    mediaUI.mediaTypes =
    [UIImagePickerController availableMediaTypesForSourceType:
     UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    
    // Hides the controls for moving & scaling pictures, or for
    // trimming movies. To instead show the controls, use YES.
    mediaUI.allowsEditing = NO;
    
    mediaUI.delegate = self;
    
    mediaUI.modalPresentationStyle = UIModalPresentationCurrentContext;
    
    [controller presentViewController:mediaUI animated:YES completion:nil];
    return YES;
}

- (void)handleAttachment {
    if (self.attachments != nil && self.attachments.count > 0) {
        UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:
                                @"Change",
                                @"Delete",
                                nil];
        if ([IAHAppearance isIPad]) {
            [popup showFromRect:[attachmentImageBtn bounds] inView:attachmentImageBtn animated:YES];
        }
        else {
            [popup showInView:[UIApplication sharedApplication].keyWindow];
        }
        
    } else {
        [self startMediaBrowserFromViewController: self
                                    usingDelegate: self];
    }
}

- (void)refreshAttachmentsImage {
    if (self.attachments != nil && self.attachments.count > 0) {
        IAHAttachment *attachment = [self.attachments objectAtIndex:0];
        [attachmentImageBtn setImage:attachment.attachmentImage forState:UIControlStateNormal];
    } else {
        UIImage *attachImage = [UIImage imageNamed:@"attach.png"];
        [attachmentImageBtn setImage:attachImage forState:UIControlStateNormal];
    }
}

#pragma mark - UIActionSheet delegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch(buttonIndex){
        case 0:
            [self startMediaBrowserFromViewController: self
                                        usingDelegate: self];
            break;
        case 1:
            [self.attachments removeAllObjects];
            [self refreshAttachmentsImage];
            break;
        case 2:
            [actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
            break;
        default:break;
    }
}

#pragma mark - UIImagePicker delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if(self.attachments == nil){
        self.attachments = [[NSMutableArray alloc] init];
    }
    
    [self.attachments removeAllObjects]; // handling only one attachments
    [self refreshAttachmentsImage];
    
    IAHAttachment *attachment = [[IAHAttachment alloc] init];
    attachment.fileName = @"attachment";

    UIImage* img = [[info objectForKey:UIImagePickerControllerOriginalImage] fixOrientationAndSize];
    NSData *data = UIImagePNGRepresentation(img);
    attachment.attachmentData = data;
    attachment.fileName = @"attachment";
    attachment.attachmentImage = img;
    attachment.mimeType = @"image/png";
    [self.attachments addObject:attachment];
    
    [self refreshAttachmentsImage];
    [messageField becomeFirstResponder];
}

@end
