//
//  AVPlayerView.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.06.05..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "AVPlayerView.h"

@implementation AVPlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer*)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

@end
