//
//  RecordManager.swift
//  HypyG
//
//  Created by 온석태 on 11/28/23.
//

import Foundation
import AVFoundation
import Photos
import UIKit

/// Main Class For ``RecordManager``
/// Base - [`AVFoundation`](https://developer.apple.com/documentation/avfoundation)
public class RecordManager {
    
    // public
    
    /**
     ``CMTime``
     */
    public var atSourceTime:CMTime?
    
    /**
     ``CMTime``
     */
    public var lastSourceTime:CMTime?
    
    /**
     ``CaptureStatus``
     */
    public var captureStatus: CaptureStatus = .idle
    
    /**
     ``RecordManagerFrameWorkDelegate``
     
     Observer based on capture status
     */
    public var recordManagerFrameWorkDelegate: RecordManagerFrameWorkDelegate?
    
    /**
     ``URL``
     */
    public var fileURL: URL?
    
    /**
     ``String``
     */
    public var fileName: String = ""
    
    /**
     ``RecordOptions``
     */
    public var recordOptions:RecordOptions?
    
    
    // protect
    
    /**
     ``AVAssetWriter``
     */
    var assetWriter: AVAssetWriter?
    
    /**
     ``AVAssetWriterInputPixelBufferAdaptor``
     */
    var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?
    
    /**
     ``AVAssetWriterInput``
     */
    var assetWriterVideoInput: AVAssetWriterInput?
    
    /**
     ``AVAssetWriterInput``
     */
    var assetWriterAudioInput: AVAssetWriterInput?
    
    /**
     ``CMSampleBuffer``
     */
    var audioSampleBufferList: [CMSampleBuffer] = []
    
    /**
     ``Int64``
     */
    var frameCount:Int64 = 0
    
    /**
     ``DispatchQueue``
     */
    let videoRecordThread = DispatchQueue(label: "VideoRecord")
    
    /**
     ``DispatchQueue``
     */
    let audioRecordThread = DispatchQueue(label: "AudioRecord")
    
    /**
     ``AVCaptureDevice.Position``
     */
    var position: AVCaptureDevice.Position?
    
    /**
     ``Bool``
     */
    var didRequestFinish: Bool = false
    
    
    
    public init(recordOptions: RecordOptions) {
        self.recordOptions = recordOptions
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setMode(.videoRecording)
            try audioSession.setActive(true)
        } catch let error {
            print("AudioSession Error:", error)
        }
    }
    
    deinit {
        print("RecordManager deinit")
    }
    
    /**
     initialize ``RecordManager``
     
     
     - Parameters:
       - filePath: filePath for save [should include / ] ex) file:///var/mobile/Containers/Data/Application/UUID/Documents/
       - fileName: fileName for save [should include extension] ex) "fileName.mp4"

     - Returns: A Bool Value return if it's "false" mean is failed set exposure
     */
    public func initialize (
        filePath: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!,
        fileName: String = UUID().uuidString + ".mp4"
    ) {
        guard let recordOptions = self.recordOptions else { return }
        self.fileName = fileName
        self.fileURL = filePath.appendingPathComponent(fileName)
        
        // 2. assetWriter로 파일경로, 파일타입 설정
        do {
            assetWriter = try AVAssetWriter(outputURL: fileURL!, fileType: .mp4)
        } catch {
            print("Error creating asset writer: \(error.localizedDescription)")
            return
        }
        
        
        // 3. 영상 화질 설정
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: recordOptions.codec,
            AVVideoWidthKey: recordOptions.frameWidth,
            AVVideoHeightKey: recordOptions.frameHeight
        ]
        
        
        let audioSettings: [String: Any] = [
          AVNumberOfChannelsKey: NSNumber(value: 2),
          //AVEncoderBitRatePerChannelKey: NSNumber(value: 64000),
          AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC),
          AVSampleRateKey: NSNumber(value: recordOptions.audioSampleRate),
        ]
        
        
        // 4. 미디어타입, 영상화질 input설정
        assetWriterVideoInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: videoSettings
        )
        
        assetWriterAudioInput = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: audioSettings
        )
        
        let sourcePixelBufferAttributes: [String: Any] = [
          kCVPixelBufferPixelFormatTypeKey as String : recordOptions.format,
          kCVPixelBufferWidthKey as String : recordOptions.frameWidth,
          kCVPixelBufferHeightKey as String : recordOptions.frameHeight
        ]

        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput!, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
        
        assetWriterVideoInput?.expectsMediaDataInRealTime = true
        assetWriterAudioInput?.expectsMediaDataInRealTime = true
        
        assetWriter?.add(assetWriterVideoInput!)
        assetWriter?.add(assetWriterAudioInput!)
        
        // 5. write 시작
        assetWriter?.startWriting()
        
        captureStatus = .ready
    }
    
    
    /**
     unreference for all memory
     
     you must use this function when you finished use this ``RecordManager``
     for memory leack
     */
    public func unreference() {
        self.assetWriter = nil
        self.assetWriterPixelBufferInput = nil
        self.assetWriterVideoInput = nil
        self.assetWriterAudioInput = nil
        self.atSourceTime = nil
        self.lastSourceTime = nil
        self.position = nil
        self.audioSampleBufferList = []
    }
}



