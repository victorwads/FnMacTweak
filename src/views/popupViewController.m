#import "./popupViewController.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "../globals.h"

// Load settings from persistent storage
static void loadSettings() {
    NSDictionary* settings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kSettingsKey];
    if (settings) {
        BASE_XY_SENSITIVITY = [settings[kBaseXYKey] floatValue] ?: 6.4f;
        LOOK_SENSITIVITY_X = [settings[kLookXKey] floatValue] ?: 50.0f;
        LOOK_SENSITIVITY_Y = [settings[kLookYKey] floatValue] ?: 50.0f;
        SCOPE_SENSITIVITY_X = [settings[kScopeXKey] floatValue] ?: 50.0f;
        SCOPE_SENSITIVITY_Y = [settings[kScopeYKey] floatValue] ?: 50.0f;
        MACOS_TO_PC_SCALE = [settings[kScaleKey] floatValue] ?: 20.0f;
        
        // CRITICAL: Recalculate pre-computed sensitivities after loading
        recalculateSensitivities();
    }
}

@interface popupViewController ()
@property UITextField* baseXYField;
@property UITextField* lookXField;
@property UITextField* lookYField;
@property UITextField* scopeXField;
@property UITextField* scopeYField;
@property UITextField* scaleField;
@property UILabel* feedbackLabel;
@property UIScrollView* scrollView;
- (void)saveButtonTapped:(UIButton*)sender;
- (void)applyDefaultsTapped:(UIButton*)sender;
@end

@implementation popupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    loadSettings();
    
    // Modern dark background with blur effect
    self.view.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.95];
    
    // Scroll view for better UX on smaller screens
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.contentSize = CGSizeMake(330, 600);
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];
    
    CGFloat y = 16;
    CGFloat leftMargin = 20;
    CGFloat rightMargin = 20;
    CGFloat contentWidth = 330 - leftMargin - rightMargin;
    
    // ========================================
    // HEADER
    // ========================================
    UILabel* title = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, y, contentWidth, 24)];
    title.text = @"Sensitivity Settings";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    title.textAlignment = NSTextAlignmentCenter;
    [self.scrollView addSubview:title];
    y += 32;
    
    // Instruction banner
    UIView* instructionBanner = [[UIView alloc] initWithFrame:CGRectMake(leftMargin, y, contentWidth, 50)];
    instructionBanner.backgroundColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.8 alpha:0.2];
    instructionBanner.layer.cornerRadius = 8;
    [self.scrollView addSubview:instructionBanner];
    
    UILabel* instruction = [[UILabel alloc] initWithFrame:CGRectMake(12, 6, contentWidth - 24, 38)];
    instruction.text = @"Match your PC Fortnite sensitivity settings\nFormula: (Base ÷ 100) × (% ÷ 100) × Scale";
    instruction.textColor = [UIColor colorWithRed:0.6 green:0.8 blue:1.0 alpha:1.0];
    instruction.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    instruction.textAlignment = NSTextAlignmentCenter;
    instruction.numberOfLines = 2;
    [instructionBanner addSubview:instruction];
    y += 56;
    
    // ========================================
    // BASE SENSITIVITY SECTION
    // ========================================
    y = [self addSectionWithTitle:@"Base Sensitivity"
                           subtitle:@"X/Y-Axis Sensitivity (recommended: 6.4)"
                              atY:y
                           fields:@[@{@"label": @"X/Y", @"value": @(BASE_XY_SENSITIVITY), @"field": @"baseXYField"}]
                          isDouble:NO];
    
    // ========================================
    // HIP-FIRE SECTION
    // ========================================
    y = [self addSectionWithTitle:@"Hip-Fire (Look)"
                           subtitle:@"Targeting sensitivity when not aiming"
                              atY:y
                           fields:@[
                               @{@"label": @"X", @"value": @(LOOK_SENSITIVITY_X), @"field": @"lookXField"},
                               @{@"label": @"Y", @"value": @(LOOK_SENSITIVITY_Y), @"field": @"lookYField"}
                           ]
                          isDouble:YES];
    
    // ========================================
    // ADS SECTION
    // ========================================
    y = [self addSectionWithTitle:@"ADS (Scope)"
                           subtitle:@"Sensitivity when aiming down sights"
                              atY:y
                           fields:@[
                               @{@"label": @"X", @"value": @(SCOPE_SENSITIVITY_X), @"field": @"scopeXField"},
                               @{@"label": @"Y", @"value": @(SCOPE_SENSITIVITY_Y), @"field": @"scopeYField"}
                           ]
                          isDouble:YES];
    
    // ========================================
    // SCALE FACTOR SECTION (ADVANCED)
    // ========================================
    [self addDividerAtY:y];
    y += 12;
    
    UILabel* advancedLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, y, contentWidth, 20)];
    advancedLabel.text = @"ADVANCED";
    advancedLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    advancedLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    advancedLabel.textAlignment = NSTextAlignmentCenter;
    [self.scrollView addSubview:advancedLabel];
    y += 20;
    
    UIView* scaleSection = [[UIView alloc] initWithFrame:CGRectMake(leftMargin, y, contentWidth, 95)];
    scaleSection.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.8];
    scaleSection.layer.cornerRadius = 12;
    [self.scrollView addSubview:scaleSection];
    
    UILabel* scaleTitle = [[UILabel alloc] initWithFrame:CGRectMake(12, 10, contentWidth - 24, 18)];
    scaleTitle.text = @"Mouse Conversion Scale";
    scaleTitle.textColor = [UIColor whiteColor];
    scaleTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    [scaleSection addSubview:scaleTitle];
    
    UILabel* scaleSubtitle = [[UILabel alloc] initWithFrame:CGRectMake(12, 30, contentWidth - 24, 24)];
    scaleSubtitle.text = @"Converts macOS mouse movement to PC scale\nRecommended: 20 for balanced feel";
    scaleSubtitle.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
    scaleSubtitle.font = [UIFont systemFontOfSize:10];
    scaleSubtitle.numberOfLines = 2;
    [scaleSection addSubview:scaleSubtitle];
    
    self.scaleField = [[UITextField alloc] initWithFrame:CGRectMake(12, 58, contentWidth - 24, 28)];
    self.scaleField.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    self.scaleField.textColor = [UIColor whiteColor];
    self.scaleField.layer.cornerRadius = 6;
    self.scaleField.keyboardType = UIKeyboardTypeDecimalPad;
    self.scaleField.text = [NSString stringWithFormat:@"%.1f", MACOS_TO_PC_SCALE];
    self.scaleField.textAlignment = NSTextAlignmentCenter;
    self.scaleField.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    self.scaleField.delegate = self;
    
    // Add padding to text field
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 28)];
    self.scaleField.leftView = paddingView;
    self.scaleField.leftViewMode = UITextFieldViewModeAlways;
    [scaleSection addSubview:self.scaleField];
    
    y += 101;
    
    // ========================================
    // ACTION BUTTONS
    // ========================================
    
    // Apply Defaults button
    UIButton* defaultsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    defaultsButton.frame = CGRectMake(leftMargin, y, contentWidth, 40);
    defaultsButton.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.35 alpha:1.0];
    [defaultsButton setTitle:@"Apply Defaults" forState:UIControlStateNormal];
    [defaultsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    defaultsButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    defaultsButton.layer.cornerRadius = 10;
    [defaultsButton addTarget:self action:@selector(applyDefaultsTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:defaultsButton];
    y += 46;
    
    // Save button
    UIButton* saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    saveButton.frame = CGRectMake(leftMargin, y, contentWidth, 40);
    saveButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0];
    [saveButton setTitle:@"Save Settings" forState:UIControlStateNormal];
    [saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    saveButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    saveButton.layer.cornerRadius = 10;
    [saveButton addTarget:self action:@selector(saveButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:saveButton];
    y += 46;
    
    // Data folder button
    UIButton* folderButton = [UIButton buttonWithType:UIButtonTypeSystem];
    folderButton.frame = CGRectMake(leftMargin, y, contentWidth, 36);
    folderButton.backgroundColor = [UIColor colorWithWhite:0.25 alpha:0.8];
    [folderButton setTitle:@"Select Fortnite Data Folder" forState:UIControlStateNormal];
    [folderButton setTitleColor:[UIColor colorWithWhite:0.9 alpha:1.0] forState:UIControlStateNormal];
    folderButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    folderButton.layer.cornerRadius = 8;
    [folderButton addTarget:self action:@selector(selectFolderTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:folderButton];
    y += 42;
    
    // Feedback label
    self.feedbackLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, y, contentWidth, 30)];
    self.feedbackLabel.textColor = [UIColor colorWithRed:0.3 green:0.9 blue:0.3 alpha:1.0];
    self.feedbackLabel.textAlignment = NSTextAlignmentCenter;
    self.feedbackLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    self.feedbackLabel.alpha = 0;
    [self.scrollView addSubview:self.feedbackLabel];
    y += 35;
    
    // Update scroll view content size
    self.scrollView.contentSize = CGSizeMake(330, y);
    
    // Make window draggable
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handlePan:)];
    [self.view addGestureRecognizer:panGesture];
}

// Helper: Add a section with title, subtitle, and field(s)
- (CGFloat)addSectionWithTitle:(NSString*)title
                      subtitle:(NSString*)subtitle
                           atY:(CGFloat)y
                        fields:(NSArray<NSDictionary*>*)fields
                      isDouble:(BOOL)isDouble {
    
    CGFloat leftMargin = 20;
    CGFloat contentWidth = 330 - 40;
    
    // Calculate exact height needed based on content
    // Title (10) + Title height (18) + Subtitle (30-28=2) + Subtitle height (24) + Field spacing (59-54=5) + Field height (28) + Bottom padding (8)
    CGFloat sectionHeight = 10 + 18 + 2 + 24 + 5 + 28 + 8;  // = 95px total
    
    // CRITICAL FIX: Round Y to whole pixel to prevent blur
    y = floor(y);
    
    UIView* section = [[UIView alloc] initWithFrame:CGRectMake(leftMargin, y, contentWidth, sectionHeight)];
    section.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.8];
    section.layer.cornerRadius = 12;
    [self.scrollView addSubview:section];
    
    // Title
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 10, contentWidth - 24, 18)];
    titleLabel.text = title;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    [section addSubview:titleLabel];
    
    // Subtitle
    UILabel* subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 30, contentWidth - 24, 24)];
    subtitleLabel.text = subtitle;
    subtitleLabel.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
    subtitleLabel.font = [UIFont systemFontOfSize:10];
    subtitleLabel.numberOfLines = 2;
    [section addSubview:subtitleLabel];
    
    // Fields
    if (isDouble && fields.count == 2) {
        // Two fields side by side
        for (int i = 0; i < 2; i++) {
            NSDictionary* fieldInfo = fields[i];
            
            // CRITICAL FIX: Round field positions to whole pixels
            CGFloat fieldX = floor(12 + (i * ((contentWidth - 24) / 2 + 6)));
            CGFloat fieldWidth = floor((contentWidth - 24 - 12) / 2);
            
            UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(fieldX, 60, 20, 18)];
            label.text = fieldInfo[@"label"];
            label.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
            label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
            [section addSubview:label];
            
            UITextField* field = [[UITextField alloc] initWithFrame:CGRectMake(fieldX + 24, 59, fieldWidth - 24, 28)];
            field.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
            field.textColor = [UIColor whiteColor];
            field.layer.cornerRadius = 6;
            field.keyboardType = UIKeyboardTypeDecimalPad;
            field.text = [NSString stringWithFormat:@"%.1f", [fieldInfo[@"value"] floatValue]];
            field.textAlignment = NSTextAlignmentCenter;
            field.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
            field.delegate = self;
            
            [section addSubview:field];
            
            // Store reference
            [self setValue:field forKey:fieldInfo[@"field"]];
        }
    } else {
        // Single field
        NSDictionary* fieldInfo = fields[0];
        
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(12, 60, 40, 18)];
        label.text = fieldInfo[@"label"];
        label.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
        label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        [section addSubview:label];
        
        UITextField* field = [[UITextField alloc] initWithFrame:CGRectMake(56, 59, contentWidth - 68, 28)];
        field.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        field.textColor = [UIColor whiteColor];
        field.layer.cornerRadius = 6;
        field.keyboardType = UIKeyboardTypeDecimalPad;
        field.text = [NSString stringWithFormat:@"%.1f", [fieldInfo[@"value"] floatValue]];
        field.textAlignment = NSTextAlignmentCenter;
        field.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        field.delegate = self;
        
        [section addSubview:field];
        
        // Store reference
        [self setValue:field forKey:fieldInfo[@"field"]];
    }
    
    // CRITICAL FIX: Return whole pixel value
    return floor(y + sectionHeight + 8);
}

// Helper: Add a visual divider
- (void)addDividerAtY:(CGFloat)y {
    // CRITICAL FIX: Round divider position to whole pixel
    y = floor(y);
    UIView* divider = [[UIView alloc] initWithFrame:CGRectMake(40, y, 250, 1)];
    divider.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    [self.scrollView addSubview:divider];
}

// Handle dragging the window
- (void)handlePan:(UIPanGestureRecognizer*)gesture {
    CGPoint translation = [gesture translationInView:self.view];
    if (gesture.state == UIGestureRecognizerStateChanged) {
        CGRect newFrame = self.view.window.frame;
        newFrame.origin.x += translation.x;
        newFrame.origin.y += translation.y;
        
        // CRITICAL FIX: Round window position to whole pixels for crisp rendering
        newFrame.origin.x = floor(newFrame.origin.x);
        newFrame.origin.y = floor(newFrame.origin.y);
        
        self.view.window.frame = newFrame;
        [gesture setTranslation:CGPointZero inView:self.view];
    }
}

// Apply default settings
- (void)applyDefaultsTapped:(UIButton*)sender {
    // Set default values
    self.baseXYField.text = @"6.4";
    self.lookXField.text = @"50.0";
    self.lookYField.text = @"50.0";
    self.scopeXField.text = @"50.0";
    self.scopeYField.text = @"50.0";
    self.scaleField.text = @"20.0";
    
    // Update globals
    BASE_XY_SENSITIVITY = 6.4f;
    LOOK_SENSITIVITY_X = 50.0f;
    LOOK_SENSITIVITY_Y = 50.0f;
    SCOPE_SENSITIVITY_X = 50.0f;
    SCOPE_SENSITIVITY_Y = 50.0f;
    MACOS_TO_PC_SCALE = 20.0f;
    
    // CRITICAL: Recalculate pre-computed sensitivities after updating globals
    recalculateSensitivities();
    
    // Persist to storage
    NSDictionary* settings = @{
        kBaseXYKey: @(BASE_XY_SENSITIVITY),
        kLookXKey: @(LOOK_SENSITIVITY_X),
        kLookYKey: @(LOOK_SENSITIVITY_Y),
        kScopeXKey: @(SCOPE_SENSITIVITY_X),
        kScopeYKey: @(SCOPE_SENSITIVITY_Y),
        kScaleKey: @(MACOS_TO_PC_SCALE)
    };
    
    [[NSUserDefaults standardUserDefaults] setObject:settings forKey:kSettingsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Show feedback
    [self showFeedback:@"✓ Defaults Applied & Saved" color:[UIColor colorWithRed:0.3 green:0.9 blue:0.3 alpha:1.0]];
}

// Save settings
- (void)saveButtonTapped:(UIButton*)sender {
    // Update globals
    BASE_XY_SENSITIVITY = [self.baseXYField.text floatValue];
    LOOK_SENSITIVITY_X = [self.lookXField.text floatValue];
    LOOK_SENSITIVITY_Y = [self.lookYField.text floatValue];
    SCOPE_SENSITIVITY_X = [self.scopeXField.text floatValue];
    SCOPE_SENSITIVITY_Y = [self.scopeYField.text floatValue];
    MACOS_TO_PC_SCALE = [self.scaleField.text floatValue];
    
    // CRITICAL: Recalculate pre-computed sensitivities after updating globals
    recalculateSensitivities();
    
    // Persist to storage
    NSDictionary* settings = @{
        kBaseXYKey: @(BASE_XY_SENSITIVITY),
        kLookXKey: @(LOOK_SENSITIVITY_X),
        kLookYKey: @(LOOK_SENSITIVITY_Y),
        kScopeXKey: @(SCOPE_SENSITIVITY_X),
        kScopeYKey: @(SCOPE_SENSITIVITY_Y),
        kScaleKey: @(MACOS_TO_PC_SCALE)
    };
    
    [[NSUserDefaults standardUserDefaults] setObject:settings forKey:kSettingsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Show feedback
    [self showFeedback:@"✓ Settings Saved" color:[UIColor colorWithRed:0.3 green:0.9 blue:0.3 alpha:1.0]];
}

// Show feedback message with animation
- (void)showFeedback:(NSString*)message color:(UIColor*)color {
    self.feedbackLabel.text = message;
    self.feedbackLabel.textColor = color;
    self.feedbackLabel.alpha = 0;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.feedbackLabel.alpha = 1;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{
                self.feedbackLabel.alpha = 0;
            }];
        });
    }];
}

// Validate text input
- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
    NSCharacterSet *allowedChars = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
    NSCharacterSet *invalidChars = [allowedChars invertedSet];
    
    if ([string rangeOfCharacterFromSet:invalidChars].location != NSNotFound) {
        return NO;
    }
    
    // Prevent multiple decimal points
    if ([textField.text containsString:@"."] && [string isEqualToString:@"."]) {
        return NO;
    }
    
    return YES;
}

// Folder selection
- (void)selectFolderTapped:(UIButton*)sender {
    if (@available(iOS 14.0, *)) {
        UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc]
                                                   initForOpeningContentTypes:@[UTTypeFolder]
                                                   asCopy:NO];
        picker.delegate = self;
        picker.allowsMultipleSelection = NO;
        [self presentViewController:picker animated:YES completion:nil];
    }
}

// Handle folder selection
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (urls.count > 0) {
        NSURL *url = urls.firstObject;
        
        if ([url startAccessingSecurityScopedResource]) {
            NSError *error = nil;
            NSURLBookmarkCreationOptions options = (NSURLBookmarkCreationOptions)(1 << 11);
            NSData *bookmark = [url bookmarkDataWithOptions:options
                                   includingResourceValuesForKeys:nil
                                                    relativeToURL:nil
                                                            error:&error];
            
            if (bookmark) {
                [[NSUserDefaults standardUserDefaults] setObject:bookmark forKey:@"fnmactweak.datafolder"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                [self showFeedback:@"Restarting..." color:[UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0]];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    exit(0);
                });
            }
            
            [url stopAccessingSecurityScopedResource];
        }
    }
}

@end
