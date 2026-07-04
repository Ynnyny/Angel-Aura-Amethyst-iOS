#import "AudioLevelMeterView.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

#define BAR_WIDTH 24.0

static BOOL _gameRunning = NO;

@interface AudioLevelMeterView()
@property(nonatomic) AVAudioRecorder *recorder;
@property(nonatomic) CADisplayLink *displayLink;
@property(nonatomic) UIView *levelBar;
@property(nonatomic) UIView *levelBarContainer;
@end

@implementation AudioLevelMeterView

+ (void)setGameRunning:(BOOL)running {
    _gameRunning = running;
}

+ (BOOL)gameRunning {
    return _gameRunning;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor.systemGrayColor colorWithAlphaComponent:0.15];
        self.layer.cornerRadius = 4;
        self.clipsToBounds = YES;
        self.userInteractionEnabled = NO;

        CGFloat w = frame.size.width;

        self.levelBarContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, frame.size.height)];
        self.levelBarContainer.backgroundColor = UIColor.clearColor;
        self.levelBarContainer.clipsToBounds = YES;
        [self addSubview:self.levelBarContainer];

        self.levelBar = [[UIView alloc] initWithFrame:CGRectMake(2, frame.size.height - 4, w - 4, 4)];
        self.levelBar.backgroundColor = [UIColor systemGreenColor];
        self.levelBar.layer.cornerRadius = 2;
        self.levelBarContainer.clipsToBounds = YES;
        [self.levelBarContainer addSubview:self.levelBar];
    }
    return self;
}

- (void)startMonitoring {
    if (_monitoring) return;
    if (_gameRunning) {
        NSLog(@"[AudioLevelMeter] Game is running, not starting recorder to avoid mic conflict");
        return;
    }
    _monitoring = YES;

    [AVAudioSession.sharedInstance requestRecordPermission:^(BOOL granted) {
        if (!granted) {
            _monitoring = NO;
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupRecorder];
        });
    }];
}

- (void)setupRecorder {
    NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"level_meter.caf"]];
    NSDictionary *settings = @{
        AVFormatIDKey: @(kAudioFormatAppleIMA4),
        AVSampleRateKey: @(44100.0),
        AVNumberOfChannelsKey: @(1),
        AVLinearPCMBitDepthKey: @(16),
        AVLinearPCMIsBigEndianKey: @(NO),
        AVLinearPCMIsFloatKey: @(NO)
    };

    NSError *error = nil;
    self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    if (error) {
        NSLog(@"[AudioLevelMeter] Recorder init error: %@", error);
        _monitoring = NO;
        return;
    }

    self.recorder.meteringEnabled = YES;
    [self.recorder prepareToRecord];
    [self.recorder record];

    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateLevel)];
    if (@available(iOS 15.0, *)) {
        self.displayLink.preferredFrameRateRange = CAFrameRateRangeMake(15, 30, 30);
    }
    [self.displayLink addToRunLoop:NSRunLoop.currentRunLoop forMode:NSRunLoopCommonModes];
}

- (void)updateLevel {
    if (!self.recorder || !self.recorder.isRecording) return;

    [self.recorder updateMeters];
    float avgPower = [self.recorder averagePowerForChannel:0];
    float peakPower = [self.recorder peakPowerForChannel:0];

    float level = pow(10.0, avgPower / 20.0);
    float peak = pow(10.0, peakPower / 20.0);
    float displayLevel = MAX(level, peak * 0.3);

    CGFloat barHeight = MAX(4, (self.levelBarContainer.frame.size.height - 8) * displayLevel);
    CGFloat w = self.levelBarContainer.frame.size.width;
    self.levelBar.frame = CGRectMake(2, self.levelBarContainer.frame.size.height - 4 - barHeight, w - 4, barHeight + 4);

    UIColor *color;
    if (displayLevel < 0.3) {
        color = [UIColor systemGreenColor];
    } else if (displayLevel < 0.6) {
        color = [UIColor systemYellowColor];
    } else {
        color = [UIColor systemRedColor];
    }
    self.levelBar.backgroundColor = color;
}

- (void)stopMonitoring {
    _monitoring = NO;
    [self.displayLink invalidate];
    self.displayLink = nil;
    [self.recorder stop];
    self.recorder = nil;

    [UIView animateWithDuration:0.2 animations:^{
        self.levelBar.frame = CGRectMake(2, self.frame.size.height - 4, self.frame.size.width - 4, 4);
        self.levelBar.backgroundColor = [UIColor systemGreenColor];
    }];
}

- (void)dealloc {
    [self stopMonitoring];
}

@end
