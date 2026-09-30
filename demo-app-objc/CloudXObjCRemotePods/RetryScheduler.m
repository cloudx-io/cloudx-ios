#import "RetryScheduler.h"

static NSTimeInterval const kBaseDelay = 2;
static NSTimeInterval const kMaxDelay = 60;
static NSInteger const kMaxShift = 5;

@interface RetryScheduler ()
@property (nonatomic, copy, nullable) dispatch_block_t work;
@property (nonatomic) NSInteger count;
@end

@implementation RetryScheduler

- (void)dealloc {
    if (_work) dispatch_block_cancel(_work);
}

- (BOOL)isPending {
    return self.work != nil;
}

- (NSInteger)scheduleAction:(dispatch_block_t)action {
    NSTimeInterval delay = MIN(kBaseDelay * (1 << self.count), kMaxDelay);
    self.count = MIN(self.count + 1, kMaxShift);
    if (self.work) dispatch_block_cancel(self.work);
    __weak typeof(self) weakSelf = self;
    dispatch_block_t work = dispatch_block_create(0, ^{
        weakSelf.work = nil;
        action();
    });
    self.work = work;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), work);
    return (NSInteger)delay;
}

- (void)reset {
    if (self.work) dispatch_block_cancel(self.work);
    self.work = nil;
    self.count = 0;
}

@end
