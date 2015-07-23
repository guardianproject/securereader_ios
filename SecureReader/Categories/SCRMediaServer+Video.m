
//
//  SCRMediaServer+SecureReader.m
//  SecureReader
//
//  Created by David Chiles on 7/23/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRMediaServer+Video.h"

#import "SCRMediaItem.h"

@import AVFoundation;

@implementation SCRMediaServer (Video)

- (UIImage *)videoThumbnail:(SCRMediaItem *)mediaItem
{
    AVURLAsset *asset = [AVURLAsset assetWithURL:[mediaItem localURLWithPort:self.port]];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    NSError *error = nil;
    //Grab middle frame
    CMTime time = CMTimeMultiplyByFloat64(asset.duration, 0.5);
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:&error];
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return image;
}

@end
