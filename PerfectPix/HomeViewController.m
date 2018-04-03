//
//  HomeViewController.m
//  PerfectPix
//
//  Created by Atif Imran on 9/5/17.
//  Copyright © 2017 Atif Imran. All rights reserved.
//

#import "HomeViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import <QuartzCore/QuartzCore.h>
#import "MarqueeLabel.h"
#import "FilterUtil.h"
#import "BWSegmentedControl.h"

typedef enum {
    kScale,
    kRadius,
    kCenterX,
    kCenterY,
    kAngle,
    kFocusFall,
    kBottomFocus,
    kTopFocus,
    kRange,
    kSaturation,
    kDownsample,
    kQuantize,
    kThreshold,
    kRefractiveIndex
}CustomFilterName;

@interface HomeViewController ()

@property (strong, nonatomic) IBOutlet GPUImageView *primaryView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (strong, nonatomic) IBOutlet UIButton *photoCaptureButton;
@property (strong, nonatomic) IBOutlet UIView *filtersView;
@property (weak, nonatomic) IBOutlet UIView *sampleFilterView;
@property (weak, nonatomic) IBOutlet UIScrollView *filterScrollView;
@property (weak, nonatomic) IBOutlet UIButton *flashBtn;
@property (weak, nonatomic) IBOutlet UIImageView *selectedImageView;
@property (weak, nonatomic) IBOutlet UILabel *filterLabel;
@property (strong, nonatomic) IBOutlet UISlider *filterSettingSlider;
@property (weak, nonatomic) IBOutlet UIView *customizeFilterView;
@property (strong, nonatomic) IBOutlet UISegmentedControl *filterSegment;

@property (strong, nonatomic) UIImageView *tickIcon;
@property (strong, nonatomic) UIImage *filteredImage;
@property (strong, nonatomic) UIImage *selectedImage;
@property (assign, nonatomic) BOOL isFlashOn, isGallery;
@property (assign, nonatomic) float widthOfContent, centerX, centerY;
@property (assign, nonatomic) GPUImageShowcaseFilterType filterType;
@property (assign, nonatomic) CustomFilterName customFilterName;

- (IBAction)switchCamera:(UIButton *)sender;
- (IBAction)openGallery:(UIButton *)sender;
- (IBAction)share:(UIButton *)sender;
- (IBAction)toggleFlash:(UIButton *)sender;
- (IBAction)openSettings:(UIButton *)sender;
- (IBAction)close:(UIButton *)sender;
- (IBAction)updateSliderValue:(id)sender;
- (IBAction)pullDownCustomFilterView:(UIButton *)sender;
- (IBAction)segmentTapped:(UISegmentedControl*)sender;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self populateFilters];
    
    if(_isGallery){
        _selectedImageView.image = _selectedImage;
    }else{
        _isFlashOn = NO;
        stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
        stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        
        filter = [[GPUImageGrayscaleFilter alloc] init];
        
        [stillCamera addTarget:filter];
        [filter addTarget:_primaryView];
        
        [stillCamera startCameraCapture];
    }
}

- (void)populateFilters {
    //Set fancy filter name
    _filterLabel.textColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"kl.jpeg"]];
    
    //Add filters to horizontal scrollview
    _widthOfContent = _sampleFilterView.frame.size.width ;
    [_filtersView removeFromSuperview];
    for(int i=0; i<[FilterUtil filtersList].count; i++){
        MarqueeLabel * name = [[MarqueeLabel alloc] initWithFrame:CGRectMake(12, 63, 50, 15) rate:15 andFadeLength:4];
        name.text = [[FilterUtil filtersList] objectAtIndex:i];
        [name setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:9.0f]];
        [name setTextColor:[UIColor darkGrayColor]];
        name.textAlignment = NSTextAlignmentCenter;
        
        
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(7, 0, 60, 60)];
        [button setTag:i+1];
        [button addTarget:self action:@selector(filterClicked:) forControlEvents:UIControlEventTouchUpInside];
        [button setImage:[UIImage imageNamed:@"7.jpg"] forState:UIControlStateNormal];
        
        button.layer.cornerRadius = 30;
        button.clipsToBounds = YES;
        
        CGRect viewframe = CGRectMake(_sampleFilterView.frame.size.width*(i), _sampleFilterView.frame.origin.y, _sampleFilterView.frame.size.width, _sampleFilterView.frame.size.height);
        UIView *subView = [[UIView alloc] initWithFrame:viewframe];
        [subView addSubview:button];
        [subView addSubview:name];
        
        [_filterScrollView addSubview:subView];
        _widthOfContent +=  subView.frame.size.width  ;
    }
    
}

-(void)viewDidLayoutSubviews{
    _filterScrollView.contentSize = CGSizeMake(_widthOfContent, _filterScrollView.frame.size.height);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Orientation Handle

- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
    if([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationMaskPortrait)
        stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    else if([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft)
        stillCamera.outputImageOrientation = UIInterfaceOrientationMaskLandscapeLeft;
    else if([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight)
        stillCamera.outputImageOrientation = UIInterfaceOrientationMaskLandscapeRight;
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Picker delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    _selectedImage = [info valueForKey:UIImagePickerControllerOriginalImage];
    if(_selectedImage){
        [picker dismissViewControllerAnimated:YES completion:nil];
        if(!_isGallery){
            HomeViewController *home = [self.storyboard instantiateViewControllerWithIdentifier:@"HomeViewGallery"];
            home.selectedImage = _selectedImage;
            home.isGallery = YES;
            [self presentViewController:home animated:YES completion:nil];
        }else{
            _selectedImageView.image = _selectedImage;
        }
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Actions

- (void)openCustomFilterView{
    [UIView animateWithDuration:0
                          delay:0
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         _customizeFilterView.frame = CGRectMake(_customizeFilterView.frame.origin.x, _bottomView.frame.origin.y, _customizeFilterView.frame.size.width, _customizeFilterView.frame.size.height);
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:.3
                                               delay:.1
                              usingSpringWithDamping:.6
                               initialSpringVelocity:.8
                                             options:UIViewAnimationOptionCurveEaseOut animations:^{
                                                 _customizeFilterView.frame = CGRectMake(_customizeFilterView.frame.origin.x, _bottomView.frame.origin.y, _customizeFilterView.frame.size.width, _customizeFilterView.frame.size.height);
                                             }
                                          completion:^(BOOL finished) {}];
                     }];
}

- (IBAction)pullDownCustomFilterView:(UIButton *)sender {
    NSInteger outofView = 300;
    [UIView animateWithDuration:.3
                          delay:.1
         usingSpringWithDamping:.8
          initialSpringVelocity:.8
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            _customizeFilterView.frame = CGRectMake(_customizeFilterView.frame.origin.x, _bottomView.frame.origin.y + outofView /*_bottomView.frame.size.height*/ , _customizeFilterView.frame.size.width, _customizeFilterView.frame.size.height);
                        }
                     completion:^(BOOL finished) {
                     }];
}

- (IBAction)segmentTapped:(UISegmentedControl*)sender{
    switch (_filterType) {
        case GPUIMAGE_BULGE_OUT:{
            if (sender.selectedSegmentIndex == 0){//scale
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.5;
                _customFilterName = kScale;
            }else if (sender.selectedSegmentIndex == 1){//radius
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.25;
                _customFilterName = kRadius;
            }else if (sender.selectedSegmentIndex == 2){//centerX
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.5;
                _customFilterName = kCenterX;
            }else if (sender.selectedSegmentIndex == 3){//centerY
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.5;
                _customFilterName = kCenterY;
            }
            break;
        }
        case GPUIMAGE_PINCH:{
            if (sender.selectedSegmentIndex == 0){//scale
                _filterSettingSlider.minimumValue = -2;
                _filterSettingSlider.maximumValue = 2;
                _filterSettingSlider.value = 1;
                _customFilterName = kScale;
            }else if (sender.selectedSegmentIndex == 1){//radius
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 2;
                _filterSettingSlider.value = 1;
                _customFilterName = kRadius;
            }else if (sender.selectedSegmentIndex == 2){//centerX
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.5;
                _customFilterName = kCenterX;
            }else if (sender.selectedSegmentIndex == 3){//centerY
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.5;
                _customFilterName = kCenterY;
            }
            break;
        }
        case GPUIMAGE_SWIRL:{
            if (sender.selectedSegmentIndex == 0){//angle
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.4;
                _customFilterName = kAngle;
            }else if (sender.selectedSegmentIndex == 1){//radius
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.5;
                _customFilterName = kRadius;
            }else if (sender.selectedSegmentIndex == 2){//centerX
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.5;
                _customFilterName = kCenterX;
            }else if (sender.selectedSegmentIndex == 3){//centerY
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.5;
                _customFilterName = kCenterY;
            }
            break;
        }
        case GPUIMAGE_GAMMA:{
            _filterSettingSlider.minimumValue = 0;
            _filterSettingSlider.maximumValue = 3;
            _filterSettingSlider.value = 1;
            break;
        }
        case GPUIMAGE_TILTSHIFT:{
            if (sender.selectedSegmentIndex == 0){
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.2;
                _customFilterName = kFocusFall;
            }else if (sender.selectedSegmentIndex == 1){
                _filterSettingSlider.minimumValue = 0.6;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.6;
                _customFilterName = kBottomFocus;
            }else if (sender.selectedSegmentIndex == 2){
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 0.5;
                _filterSettingSlider.value = 0.4;
                _customFilterName = kTopFocus;
            }else{
                _filterSettingSlider.minimumValue = 1;
                _filterSettingSlider.maximumValue = 10;
                _filterSettingSlider.value = 7;
                _customFilterName = kRadius;
            }
            break;
        }
        case GPUIMAGE_IOSBLUR:{
            if (sender.selectedSegmentIndex == 0){
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.6;
                _customFilterName = kRange;
            }else if (sender.selectedSegmentIndex == 1){
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 2;
                _filterSettingSlider.value = 0.8;
                _customFilterName = kSaturation;
            }else if (sender.selectedSegmentIndex == 2){
                _filterSettingSlider.minimumValue = 2;
                _filterSettingSlider.maximumValue = 8;
                _filterSettingSlider.value = 4;
                _customFilterName = kDownsample;
            }else{
                _filterSettingSlider.minimumValue = 2;
                _filterSettingSlider.maximumValue = 30;
                _filterSettingSlider.value = 12;
                _customFilterName = kRadius;
            }
            break;
        }
        case GPUIMAGE_PIXELLATE:{
            _filterSettingSlider.minimumValue = 0.000;
            _filterSettingSlider.maximumValue = 0.050;
            _filterSettingSlider.value = 0.010;
            break;
        }
        case GPUIMAGE_POLKADOT:{
            _filterSettingSlider.minimumValue = 0;
            _filterSettingSlider.maximumValue = 1;
            _filterSettingSlider.value = 0.5;
            break;
        }
        case GPUIMAGE_SMOOTHTOON:{
            if (sender.selectedSegmentIndex == 0){
                _filterSettingSlider.minimumValue = 1;
                _filterSettingSlider.maximumValue = 20;
                _filterSettingSlider.value = 10;
                _customFilterName = kQuantize;
            }else if (sender.selectedSegmentIndex == 1){
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.2;
                _customFilterName = kThreshold;
            }else if (sender.selectedSegmentIndex == 2){
                _filterSettingSlider.minimumValue = 1;
                _filterSettingSlider.maximumValue = 10;
                _filterSettingSlider.value = 2;
                _customFilterName = kRadius;
            }
            break;
        }
        case GPUIMAGE_POSTERIZE:{
            _filterSettingSlider.minimumValue = 1;
            _filterSettingSlider.maximumValue = 256;
            _filterSettingSlider.value = 10;
            break;
        }
        case GPUIMAGE_SPHEREREFRACTION:{
            if (sender.selectedSegmentIndex == 0){//refractive
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.71;
                _customFilterName = kRefractiveIndex;
            }else if (sender.selectedSegmentIndex == 1){//radius
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.25;
                _customFilterName = kRadius;
            }else if (sender.selectedSegmentIndex == 2){//centerX
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.5;
                _customFilterName = kCenterX;
            }else if (sender.selectedSegmentIndex == 3){//centerY
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.5;
                _customFilterName = kCenterY;
            }
            break;
        }
        case GPUIMAGE_KUWAHARA:{
            _filterSettingSlider.minimumValue = 0;
            _filterSettingSlider.maximumValue = 6;
            _filterSettingSlider.value = 3;
            break;
        }
        case GPUIMAGE_EMBOSS:{
            _filterSettingSlider.minimumValue = 0;
            _filterSettingSlider.maximumValue = 4;
            _filterSettingSlider.value = 1;
            break;
        }
        case GPUIMAGE_ADAPTIVETHRESHOLD:{
            _filterSettingSlider.minimumValue = 0;
            _filterSettingSlider.maximumValue = 10;
            _filterSettingSlider.value = 4;
            break;
        }
        case GPUIMAGE_STRETCH:{
            if (sender.selectedSegmentIndex == 2){//centerX
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.5;
                _customFilterName = kCenterX;
            }else if (sender.selectedSegmentIndex == 3){//centerY
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.5;
                _customFilterName = kCenterY;
            }
            break;
        }
        default:
            break;
    }
}

- (IBAction)updateSliderValue:(UISlider*)sender {
    
    if(!_filteredImage)
        _filteredImage = _selectedImage;
    
    if(_filteredImage){
        switch (_filterType) {
            case GPUIMAGE_BULGE_OUT:{
                if(_customFilterName == kScale)
                    [(GPUImageBulgeDistortionFilter *)filter setScale:sender.value];
                else if(_customFilterName == kRadius)
                    [(GPUImageBulgeDistortionFilter *)filter setRadius:sender.value];
                else if(_customFilterName == kCenterX){
                    _centerX = sender.value;
                    [(GPUImageBulgeDistortionFilter *)filter setCenter:CGPointMake(_centerX, _centerY)];
                }else if(_customFilterName == kCenterY){
                    _centerY = sender.value;
                    [(GPUImageBulgeDistortionFilter *)filter setCenter:CGPointMake(_centerX, _centerY)];
                }
                break;
            }case GPUIMAGE_PINCH:{
                if(_customFilterName == kScale)
                    [(GPUImagePinchDistortionFilter *)filter setScale:sender.value];
                else if(_customFilterName == kRadius)
                    [(GPUImagePinchDistortionFilter *)filter setRadius:sender.value];
                else if(_customFilterName == kCenterX){
                    _centerX = sender.value;
                    [(GPUImagePinchDistortionFilter *)filter setCenter:CGPointMake(_centerX, _centerY)];
                }else if(_customFilterName == kCenterY){
                    _centerY = sender.value;
                    [(GPUImagePinchDistortionFilter *)filter setCenter:CGPointMake(_centerX, _centerY)];
                }
                break;
            }case GPUIMAGE_SWIRL:{
                if(_customFilterName == kAngle)
                    [(GPUImageSwirlFilter *)filter setAngle:sender.value];
                else if(_customFilterName == kRadius)
                    [(GPUImageSwirlFilter *)filter setRadius:sender.value];
                else if(_customFilterName == kCenterX){
                    _centerX = sender.value;
                    [(GPUImageSwirlFilter *)filter setCenter:CGPointMake(_centerX, _centerY)];
                }else if(_customFilterName == kCenterY){
                    _centerY = sender.value;
                    [(GPUImageSwirlFilter *)filter setCenter:CGPointMake(_centerX, _centerY)];
                }
                break;
            }case GPUIMAGE_BULGE_IN:{
                if(_customFilterName == kScale)
                    [(GPUImageBulgeDistortionFilter *)filter setScale:sender.value];
                else if(_customFilterName == kRadius)
                    [(GPUImageBulgeDistortionFilter *)filter setRadius:sender.value];
                else if(_customFilterName == kCenterX){
                    _centerX = sender.value;
                    [(GPUImageBulgeDistortionFilter *)filter setCenter:CGPointMake(_centerX, _centerY)];
                }else if(_customFilterName == kCenterY){
                    _centerY = sender.value;
                    [(GPUImageBulgeDistortionFilter *)filter setCenter:CGPointMake(_centerX, _centerY)];
                }
                break;
            }case GPUIMAGE_GAMMA:{
                [(GPUImageGammaFilter *)filter setGamma:sender.value];
                break;
            }case GPUIMAGE_TILTSHIFT:{
                if(_customFilterName == kFocusFall)
                    [(GPUImageTiltShiftFilter *)filter setFocusFallOffRate:sender.value];
                else if(_customFilterName == kBottomFocus)
                    [(GPUImageTiltShiftFilter *)filter setBottomFocusLevel:sender.value];
                else if(_customFilterName == kTopFocus)
                    [(GPUImageTiltShiftFilter *)filter setTopFocusLevel:sender.value];
                else if(_customFilterName == kRadius)
                    [(GPUImageTiltShiftFilter *)filter setBlurRadiusInPixels:sender.value];
                break;
            }case GPUIMAGE_IOSBLUR:{
                if(_customFilterName == kRange)
                    [(GPUImageiOSBlurFilter *)filter setRangeReductionFactor:sender.value];
                else if(_customFilterName == kSaturation)
                    [(GPUImageiOSBlurFilter *)filter setSaturation:sender.value];
                else if(_customFilterName == kDownsample)
                    [(GPUImageiOSBlurFilter *)filter setDownsampling:sender.value];
                else if(_customFilterName == kRadius)
                    [(GPUImageiOSBlurFilter *)filter setBlurRadiusInPixels:sender.value];
                break;
            }case GPUIMAGE_PIXELLATE:{
                [(GPUImagePixellateFilter *)filter setFractionalWidthOfAPixel:sender.value];
                break;
            }case GPUIMAGE_POLKADOT:{
                [(GPUImagePolkaDotFilter *)filter setDotScaling:sender.value];
                break;
            }case GPUIMAGE_SMOOTHTOON:{
                if(_customFilterName == kQuantize)
                    [(GPUImageSmoothToonFilter *)filter setQuantizationLevels:sender.value];
                else if(_customFilterName == kThreshold)
                    [(GPUImageSmoothToonFilter *)filter setThreshold:sender.value];
                else if(_customFilterName == kRadius)
                    [(GPUImageSmoothToonFilter *)filter setBlurRadiusInPixels:sender.value];
                break;
            }case GPUIMAGE_POSTERIZE:{
                [(GPUImagePosterizeFilter *)filter setColorLevels:sender.value];
                break;
            }case GPUIMAGE_SPHEREREFRACTION:{
                if(_customFilterName == kRefractiveIndex)
                    [(GPUImageSphereRefractionFilter *)filter setRefractiveIndex:sender.value];
                else if(_customFilterName == kRadius)
                    [(GPUImageSphereRefractionFilter *)filter setRadius:sender.value];
                else if(_customFilterName == kCenterX){
                    _centerX = sender.value;
                    [(GPUImageSphereRefractionFilter *)filter setCenter:CGPointMake(_centerX, _centerY)];
                }else if(_customFilterName == kCenterY){
                    _centerY = sender.value;
                    [(GPUImageSphereRefractionFilter *)filter setCenter:CGPointMake(_centerX, _centerY)];
                }
                break;
            }case GPUIMAGE_KUWAHARA:{
                [(GPUImageKuwaharaFilter *)filter setRadius:sender.value];
                break;
            }case GPUIMAGE_EMBOSS:{
                [(GPUImageEmbossFilter *)filter setIntensity:sender.value];
                break;
            }case GPUIMAGE_ADAPTIVETHRESHOLD:{
                [(GPUImageAdaptiveThresholdFilter *)filter setBlurRadiusInPixels:sender.value];
                break;
            }case GPUIMAGE_STRETCH:{
                if(_customFilterName == kCenterX){
                    _centerX = sender.value;
                    [(GPUImageStretchDistortionFilter *)filter setCenter:CGPointMake(_centerX, _centerY)];
                }else if(_customFilterName == kCenterY){
                    _centerY = sender.value;
                    [(GPUImageStretchDistortionFilter *)filter setCenter:CGPointMake(_centerX, _centerY)];
                }
                break;
            }
            default:
                break;
        }
    }else{
        [FilterUtil showErrorShutterWithMessage:@"Oops! Capture photo to edit" andController:self andYOrigin:[[UIScreen mainScreen] bounds].origin.y];
    }
    _selectedImageView.image = [filter imageByFilteringImage:_filteredImage];
}

- (IBAction)takePhoto:(id)sender {
    [_photoCaptureButton setEnabled:NO];
    
    [stillCamera capturePhotoAsJPEGProcessedUpToFilter:filter withCompletionHandler:^(NSData *processedJPEG, NSError *error){
        
        // Save to assets library
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        NSMutableDictionary* metadata = [NSMutableDictionary dictionaryWithDictionary:stillCamera.currentCaptureMetadata];
        if([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationMaskPortrait)
            metadata[(__bridge NSString*)kCGImagePropertyOrientation] = @(UIImageOrientationUp);
        else if([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft
                || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight)
            metadata[(__bridge NSString*)kCGImagePropertyOrientation] = @(UIImageOrientationLeft);
        [library writeImageDataToSavedPhotosAlbum:processedJPEG metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error2)
         {
             if (error2) {
                 NSLog(@"ERROR: the image failed to be written");
             }
             else {
                 NSLog(@"PHOTO SAVED - assetURL: %@", assetURL);
             }
             
             runOnMainQueueWithoutDeadlocking(^{
                 [_photoCaptureButton setEnabled:YES];
             });
         }];
    }];
}


- (IBAction)toggleFlash:(UIButton *)sender {
    if([stillCamera.inputCamera isFlashAvailable]){
        if(_isFlashOn){
            [stillCamera.inputCamera lockForConfiguration:nil];
            [stillCamera.inputCamera setFlashMode:AVCaptureFlashModeOff];
            [stillCamera.inputCamera unlockForConfiguration];
            
            [_flashBtn setImage:[UIImage imageNamed:@"flash-off.png"] forState:UIControlStateNormal];
        }else{
            [stillCamera.inputCamera lockForConfiguration:nil];
            [stillCamera.inputCamera setFlashMode:AVCaptureFlashModeOn];
            [stillCamera.inputCamera unlockForConfiguration];
            
            [_flashBtn setImage:[UIImage imageNamed:@"flash-on.png"] forState:UIControlStateNormal];
        }
        _isFlashOn=!_isFlashOn;
    }
}

- (IBAction)openSettings:(UIButton *)sender {
}

- (IBAction)close:(UIButton *)sender {
    _isGallery = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)switchCamera:(UIButton *)sender {
    if([stillCamera isFrontFacingCameraPresent])
        [stillCamera rotateCamera];
}

- (IBAction)share:(UIButton *)sender{
    if(_filteredImage){
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[_filteredImage] applicationActivities:nil];
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
}

- (IBAction)openGallery:(UIButton *)sender{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

-(void)filterClicked:(UIButton*)sender{
    
    _filterLabel.text = [[FilterUtil filtersList] objectAtIndex:sender.tag-1];
    
    CGRect newFrame = CGRectMake((sender.tag)*sender.superview.frame.size.width-30,sender.frame.origin.y+10,30,30);
    if(!_tickIcon){
        _tickIcon = [[UIImageView alloc] initWithFrame:newFrame];
        _tickIcon.image =[UIImage imageNamed:@"tick.png"];
        _tickIcon.layer.shadowColor = [[UIColor redColor] CGColor];
        _tickIcon.layer.shadowOffset = CGSizeMake(0.0, 0.0);
        _tickIcon.layer.shadowRadius = 4.0;
        _tickIcon.layer.shadowOpacity = 1;
        [_filterScrollView addSubview:_tickIcon];
    }

    [UILabel animateWithDuration:.3
                      animations:^{
                          _filterLabel.alpha = 1;
                          _filterLabel.layer.shadowColor = [[UIColor redColor] CGColor];
                          _filterLabel.layer.shadowOffset = CGSizeMake(0.0, 0.0);
                          _filterLabel.layer.shadowRadius = 4.0;
                          _filterLabel.layer.shadowOpacity = 0.8;
                          _filterLabel.transform = CGAffineTransformMakeScale(3.5, 3.5);
                          _tickIcon.frame = newFrame;
                      }
                      completion:^(BOOL finished) {
                          [UIView animateWithDuration:0.2
                                                delay:0.4
                                              options: UIViewAnimationOptionTransitionNone
                                           animations:^{
                                               _filterLabel.transform = CGAffineTransformIdentity;
                                               _filterLabel.alpha = 0;
                                           }
                                           completion:nil];
                      }];
    
    if(!_isGallery || _selectedImage){
        _filteredImage = _selectedImage;
        
        //the switch cases are laid as they appear in [FilterUtil filtersList]
        switch (sender.tag) {
            case 1:{
                NSLog(@"grayscale");
                _filterType = GPUIMAGE_GRAYSCALE;
                filter = [[GPUImageGrayscaleFilter alloc] init];
                
                
                break;
            }case 2:{
                NSLog(@"bloater - bulge out");
                [self openCustomFilterView];
                _filterType = GPUIMAGE_BULGE_OUT;
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.5;
                
                [_filterSegment removeAllSegments];
                [_filterSegment insertSegmentWithTitle:@"SCALE" atIndex:0 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"RADIUS" atIndex:1 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"⇄" atIndex:2 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"⇅" atIndex:3 animated:NO];

                filter = [[GPUImageBulgeDistortionFilter alloc] init];
                ((GPUImageBulgeDistortionFilter*)filter).scale = _filterSettingSlider.value;
                
                break;
            }case 3:{
                NSLog(@"spink - pinch");
                [self openCustomFilterView];
                _filterType = GPUIMAGE_PINCH;
                _filterSettingSlider.minimumValue = -2;
                _filterSettingSlider.maximumValue = 2;
                _filterSettingSlider.value = 0.5;
                
                [_filterSegment removeAllSegments];
                [_filterSegment insertSegmentWithTitle:@"SCALE" atIndex:0 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"RADIUS" atIndex:1 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"⇄" atIndex:2 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"⇅" atIndex:3 animated:NO];
                
                filter = [[GPUImagePinchDistortionFilter alloc] init];
                ((GPUImagePinchDistortionFilter*)filter).scale = _filterSettingSlider.value;
                
                break;
            }case 4:{
                NSLog(@"twistrr - swirl");
                [self openCustomFilterView];
                _filterType = GPUIMAGE_SWIRL;
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.5;
                
                [_filterSegment removeAllSegments];
                [_filterSegment insertSegmentWithTitle:@"ANGLE" atIndex:0 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"RADIUS" atIndex:1 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"⇄" atIndex:2 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"⇅" atIndex:3 animated:NO];
                
                filter = [[GPUImageSwirlFilter alloc] init];
                ((GPUImageSwirlFilter*)filter).angle = _filterSettingSlider.value;
                
                break;
            }case 5:{
                NSLog(@"blackhole - bulge in");
                [self openCustomFilterView];
                _filterType = GPUIMAGE_BULGE_IN;
                _filterSettingSlider.minimumValue = -1;
                _filterSettingSlider.maximumValue = 0;
                _filterSettingSlider.value = -0.5;
                
                [_filterSegment removeAllSegments];
                [_filterSegment insertSegmentWithTitle:@"SCALE" atIndex:0 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"RADIUS" atIndex:1 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"⇄" atIndex:2 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"⇅" atIndex:3 animated:NO];
                
                filter = [[GPUImageBulgeDistortionFilter alloc] init];
                ((GPUImageBulgeDistortionFilter*)filter).scale = _filterSettingSlider.value;
                
                break;
            }case 6:{
                NSLog(@"gamma");
                [self openCustomFilterView];
                _filterType = GPUIMAGE_GAMMA;
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 3;
                _filterSettingSlider.value = 1;
                
                [_filterSegment removeAllSegments];
                [_filterSegment insertSegmentWithTitle:@"GAMMA" atIndex:0 animated:NO];
                
                filter = [[GPUImageGammaFilter alloc] init];
                ((GPUImageGammaFilter*)filter).gamma = _filterSettingSlider.value;
                
                break;
            }case 7:{
                NSLog(@"sepia");
                _filterType = GPUIMAGE_SEPIA;
                
                filter = [[GPUImageSepiaFilter alloc] init];
                
                break;
            }case 8:{
                NSLog(@"invert");
                _filterType = GPUIMAGE_COLORINVERT;
                
                filter = [[GPUImageColorInvertFilter alloc] init];
                
                break;
            }case 9:{
                NSLog(@"amatorka");
                _filterType = GPUIMAGE_AMATORKA;
                
                filter = [[GPUImageAmatorkaFilter alloc] init];
                
                break;
            }case 10:{
                NSLog(@"etikate");
                _filterType = GPUIMAGE_MISSETIKATE;
                
                filter = [[GPUImageMissEtikateFilter alloc] init];
                
                break;
            }case 11:{
                NSLog(@"soft elegance");
                _filterType = GPUIMAGE_SOFTELEGANCE;
                
                _filteredImage = _selectedImage;
                filter = [[GPUImageSoftEleganceFilter alloc] init];
                
                break;
            }case 12:{
                NSLog(@"tilt shift");
                [self openCustomFilterView];
                _filterType = GPUIMAGE_TILTSHIFT;
                _filterSettingSlider.minimumValue = 0.41;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.5;
                
                [_filterSegment removeAllSegments];
                [_filterSegment insertSegmentWithTitle:@"FOCUS" atIndex:0 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"BOTTOM" atIndex:1 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"TOP" atIndex:2 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"RADIUS" atIndex:3 animated:NO];
                
                filter = [[GPUImageTiltShiftFilter alloc] init];
                ((GPUImageTiltShiftFilter*)filter).bottomFocusLevel = _filterSettingSlider.value;
                
                
                [self openCustomFilterView];
                break;
            }case 13:{
                NSLog(@"erosion");
                _filterType = GPUIMAGE_EROSION;
                
                filter = [[GPUImageErosionFilter alloc] init];
                
                break;
            }case 14:{
                NSLog(@"blur");
                [self openCustomFilterView];
                _filterType = GPUIMAGE_IOSBLUR;
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 2;
                _filterSettingSlider.value = .8;
                
                [_filterSegment removeAllSegments];
                [_filterSegment insertSegmentWithTitle:@"RANGE" atIndex:0 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"SATURATE" atIndex:1 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"DOWNSAMPLE" atIndex:2 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"RADIUS" atIndex:3 animated:NO];
                
                filter = [[GPUImageiOSBlurFilter alloc] init];
                ((GPUImageiOSBlurFilter*)filter).saturation = _filterSettingSlider.value;
                
                break;
            }case 15:{
                NSLog(@"haze");
                _filterType = GPUIMAGE_HAZE;
                
                filter = [[GPUImageHazeFilter alloc] init];
                
                break;
            }case 16:{
                NSLog(@"mosaic");
                _filterType = GPUIMAGE_MOSAIC;
                
                filter = [[GPUImageMosaicFilter alloc] init];
                
                break;
            }case 17:{
                NSLog(@"pixellate");
                [self openCustomFilterView];
                _filterType = GPUIMAGE_PIXELLATE;
                _filterSettingSlider.minimumValue = 0.000;
                _filterSettingSlider.maximumValue = 0.050;
                _filterSettingSlider.value = 0.010;
                
                [_filterSegment removeAllSegments];
                [_filterSegment insertSegmentWithTitle:@"INTENSITY" atIndex:0 animated:NO];
                
                filter = [[GPUImagePixellateFilter alloc] init];
                ((GPUImagePixellateFilter*)filter).fractionalWidthOfAPixel = _filterSettingSlider.value;
                
                break;
            }case 18:{
                NSLog(@"polka dots");
                [self openCustomFilterView];
                _filterType = GPUIMAGE_POLKADOT;
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.9;
                
                [_filterSegment removeAllSegments];
                [_filterSegment insertSegmentWithTitle:@"SCALE" atIndex:0 animated:NO];
                
                filter = [[GPUImagePolkaDotFilter alloc] init];
                ((GPUImagePolkaDotFilter*)filter).dotScaling = _filterSettingSlider.value;
                
                break;
            }case 19:{
                NSLog(@"sketch");
                _filterType = GPUIMAGE_SKETCH;
                
                filter = [[GPUImageSketchFilter alloc] init];
                
                break;
            }case 20:{
                NSLog(@"toon");
                [self openCustomFilterView];
                _filterType = GPUIMAGE_SMOOTHTOON;
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.2;
                
                [_filterSegment removeAllSegments];
                [_filterSegment insertSegmentWithTitle:@"QUANTIZE" atIndex:0 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"THRESHOLD" atIndex:1 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"RADIUS" atIndex:2 animated:NO];

                filter = [[GPUImageSmoothToonFilter alloc] init];
                ((GPUImageSmoothToonFilter*)filter).threshold = _filterSettingSlider.value;
                
                break;
            }case 21:{
                NSLog(@"posterize");
                [self openCustomFilterView];
                _filterType = GPUIMAGE_POSTERIZE;
                _filterSettingSlider.minimumValue = 1;
                _filterSettingSlider.maximumValue = 256;
                _filterSettingSlider.value = 10;
                
                [_filterSegment removeAllSegments];
                [_filterSegment insertSegmentWithTitle:@"LEVEL" atIndex:0 animated:NO];
                
                filter = [[GPUImagePosterizeFilter alloc] init];
                ((GPUImagePosterizeFilter*)filter).colorLevels = _filterSettingSlider.value;
                
                break;
            }case 22:{
                NSLog(@"stretch");
                [self openCustomFilterView];
                _filterType = GPUIMAGE_STRETCH;
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.5;
                
                [_filterSegment insertSegmentWithTitle:@"⇄" atIndex:0 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"⇅" atIndex:1 animated:NO];
                
                filter = [[GPUImageStretchDistortionFilter alloc] init];
                
                break;
            }case 23:{
                NSLog(@"sphere");
                [self openCustomFilterView];
                _filterType = GPUIMAGE_SPHEREREFRACTION;
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 1;
                _filterSettingSlider.value = 0.25;
                
                [_filterSegment removeAllSegments];
                [_filterSegment insertSegmentWithTitle:@"INDEX" atIndex:0 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"RADIUS" atIndex:1 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"⇄" atIndex:2 animated:NO];
                [_filterSegment insertSegmentWithTitle:@"⇅" atIndex:3 animated:NO];
                
                filter = [[GPUImageSphereRefractionFilter alloc] init];
                ((GPUImageSphereRefractionFilter*)filter).radius = _filterSettingSlider.value;
                
                break;
            }case 24:{
                NSLog(@"glass");
                _filterType = GPUIMAGE_GLASSSPHERE;
                
                filter = [[GPUImageGlassSphereFilter alloc] init];
                
                break;
            }case 25:{
                NSLog(@"kuwahara");
                [self openCustomFilterView];
                _filterType = GPUIMAGE_KUWAHARA;
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 6;
                _filterSettingSlider.value = 3;
                
                [_filterSegment removeAllSegments];
                [_filterSegment insertSegmentWithTitle:@"RADIUS" atIndex:0 animated:NO];
                
                filter = [[GPUImageKuwaharaFilter alloc] init];
                ((GPUImageKuwaharaFilter*)filter).radius = _filterSettingSlider.value;
                
                break;
            }case 26:{
                NSLog(@"vignette");
                _filterType = GPUIMAGE_VIGNETTE;
                
                filter = [[GPUImageVignetteFilter alloc] init];
                
                break;
            }case 27:{
                NSLog(@"false");
                _filterType = GPUIMAGE_FALSECOLOR;
                
                filter = [[GPUImageFalseColorFilter alloc] init];
                
                break;
            }case 28:{
                NSLog(@"emboss");
                [self openCustomFilterView];
                _filterType = GPUIMAGE_EMBOSS;
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 4;
                _filterSettingSlider.value = 1;
                
                [_filterSegment removeAllSegments];
                [_filterSegment insertSegmentWithTitle:@"INTENSITY" atIndex:0 animated:NO];
                
                filter = [[GPUImageEmbossFilter alloc] init];
                ((GPUImageEmbossFilter*)filter).intensity = _filterSettingSlider.value;
                
                break;
            }case 29:{
                NSLog(@"halftone");
                _filterType = GPUIMAGE_HALFTONE;
                
                filter = [[GPUImageHalftoneFilter alloc] init];
                
                break;
            }case 30:{
                NSLog(@"threshold");
                [self openCustomFilterView];
                _filterType = GPUIMAGE_ADAPTIVETHRESHOLD;
                _filterSettingSlider.minimumValue = 0;
                _filterSettingSlider.maximumValue = 10;
                _filterSettingSlider.value = 4;
                
                [_filterSegment removeAllSegments];
                [_filterSegment insertSegmentWithTitle:@"RADIUS" atIndex:0 animated:NO];
                
                
                filter = [[GPUImageAdaptiveThresholdFilter alloc] init];
                ((GPUImageAdaptiveThresholdFilter*)filter).blurRadiusInPixels = _filterSettingSlider.value;
                
                break;
            }case 31:{
                NSLog(@"monochrome");
                _filterType = GPUIMAGE_MONOCHROME;
                
                filter = [[GPUImageMonochromeFilter alloc] init];
                
                break;
            }default:{
                NSLog(@"default grayscale");
                _filterType = GPUIMAGE_GRAYSCALE;
                
                filter = [[GPUImageGrayscaleFilter alloc] init];
                
                break;
            }
        }
        _centerX = 0.5; _centerY = 0.5;
        [_filterSegment setSelectedSegmentIndex:0];
        if(!_isGallery){
            [stillCamera removeAllTargets];
            [stillCamera stopCameraCapture];
            [stillCamera useNextFrameForImageCapture];
            [stillCamera imageFromCurrentFramebufferWithOrientation:UIImageOrientationUp];
        
            [stillCamera addTarget:filter];
            [filter addTarget:_primaryView];
            [stillCamera startCameraCapture];
        }else{
            _selectedImageView.image = [filter imageByFilteringImage:_filteredImage];
        }
    }
}


@end
