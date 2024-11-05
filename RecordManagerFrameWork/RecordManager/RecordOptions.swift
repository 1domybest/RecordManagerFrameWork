//
//  RecordOptions.swift
//  CameraManagerExample
//
//  Created by 온석태 on 11/5/24.
//

import Foundation
import AVFoundation

public struct RecordOptions {
    public var frameWidth: Int
    public var frameHeight: Int
    public var audioSampleRate: Int
    public var format: OSType
    public var codec: AVVideoCodecType
    
    public init(
        frameWidth: Int = 720,
        frameHeight: Int = 1280,
        audioSampleRate: Int = 44100,
        format: OSType = kCVPixelFormatType_32BGRA,
        codec: AVVideoCodecType = AVVideoCodecType.h264
    ) {
        self.frameWidth = frameWidth
        self.frameHeight = frameHeight
        self.audioSampleRate = audioSampleRate
        self.format = format
        self.codec = codec
    }
}
