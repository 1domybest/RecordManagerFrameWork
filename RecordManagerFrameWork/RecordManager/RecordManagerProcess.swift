//
//  RecordManagerProcess.swift
//  RecordManagerFrameWork
//
//  Created by 온석태 on 11/5/24.
//

import Foundation
import AVFoundation

extension RecordManager {
    /**
     finish Video Record
     */
    func finishVideoRecording () {
        // 1. video, audio write 작업 종료
        if self.didRequestFinish {
            return
        }
        
        self.didRequestFinish = true
        self.assetWriterVideoInput?.markAsFinished()
        self.assetWriterAudioInput?.markAsFinished()

        self.assetWriter?.finishWriting {
            self.frameCount = 0
            // writing 끝나고 작업할게 있으면 여기 추가.
            if let fileURL = self.fileURL, let position = self.position { // self.fileURL은 비디오 파일의 URL
                self.recordManagerFrameWorkDelegate?.onFinishedRecord(fileURL: fileURL, position: position)
            }
            
            // 2. assetWriter 초기화
            self.assetWriter = nil
            self.atSourceTime = nil
            self.assetWriterVideoInput = nil
            self.assetWriterAudioInput = nil
            self.assetWriterPixelBufferInput = nil
            self.audioSampleBufferList.removeAll()
            // 3. captureStatus 초기화
            self.didRequestFinish = false
            
            self.captureStatus = .idle
        }
        
    }

    
    /**
     append Video Buffer
     
     - Parameters:
       - pixelBuffer: ``CVPixelBuffer``
       - time: ``CMTime``
     */
    func appendVideoBuffer (pixelBuffer: CVPixelBuffer, time: CMTime) {
        if self.atSourceTime == nil {
            self.atSourceTime = time
            assetWriter?.startSession(atSourceTime: self.atSourceTime!)
        }
        if assetWriterVideoInput?.isReadyForMoreMediaData == true {
            assetWriterPixelBufferInput?.append(pixelBuffer, withPresentationTime: time)
        } else {
            print("failure")
        }
    }
    
    /**
     append Audio Buffer
     
     - Parameters:
       - sampleBuffer: ``CMSampleBuffer``
     */
    func appendAudioBuffer (sampleBuffer: CMSampleBuffer) {
        if self.atSourceTime == nil {
            self.audioSampleBufferList.append(sampleBuffer)
        } else {
            if (audioSampleBufferList.isEmpty) {
                if assetWriterAudioInput?.isReadyForMoreMediaData == true {
                    assetWriterAudioInput?.append(sampleBuffer)
                }
            } else {
                for sample_Buffer in self.audioSampleBufferList {
                    if assetWriterAudioInput?.isReadyForMoreMediaData == true {
                        assetWriterAudioInput?.append(sample_Buffer)
                    }
                }
                self.audioSampleBufferList.removeAll()
                
                if assetWriterAudioInput?.isReadyForMoreMediaData == true {
                    assetWriterAudioInput?.append(sampleBuffer)
                }
            }
        }
    }
    
    
    /**
     take Photo for inSide Manager
     
     - Parameters:
       - pixelBuffer: ``CVPixelBuffer``
     */
    func takePhoto (pixelBuffer: CVPixelBuffer) {
        if let image = createImage(from: pixelBuffer) {
            self.recordManagerFrameWorkDelegate?.tookPhoto(image: image)
        }
        captureStatus = .ready
    }
}

extension RecordManager {
    
    /**
     append VideoBuffer with SampleBuffer For Recording
     
     - Parameters:
       - sampleBuffer: ``CMSampleBuffer``
       - position: ``AVCaptureDevice/Position``
     */
    public func appendVideoQueue(sampleBuffer: CMSampleBuffer, position: AVCaptureDevice.Position) {
        
        guard var pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
              return
          }
        
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        
        self.recordManagerFrameWorkDelegate?.statusDidChange(captureStatus: self.captureStatus)
        self.position = position
        videoRecordThread.async {
            switch self.captureStatus {
            case .idle:
                self.initialize()
                break
            case .start:
                self.startVideoRecording()
                break
            case .capturing:
                self.appendVideoBuffer(pixelBuffer: pixelBuffer, time: time)
                break
            case .takePhoto:
                self.takePhoto(pixelBuffer: pixelBuffer)
                break
            case .end:
                self.finishVideoRecording()
                break
            default:
                break
            }
        }
    }
    
    
    /**
     append VideoBuffer with CVPixelBuffer For Recording
     
     - Parameters:
       - pixelBuffer: ``CVPixelBuffer``
       - time: ``CMTime``
       - position: ``AVCaptureDevice/Position``
     */
    public func appendVideoQueue(pixelBuffer: CVPixelBuffer, time: CMTime, position: AVCaptureDevice.Position) {
        self.recordManagerFrameWorkDelegate?.statusDidChange(captureStatus: self.captureStatus)
        self.position = position
        videoRecordThread.async {
            switch self.captureStatus {
            case .idle:
                self.initialize()
                break
            case .start:
                self.startVideoRecording()
                break
            case .capturing:
                self.appendVideoBuffer(pixelBuffer: pixelBuffer, time: time)
                break
            case .takePhoto:
                self.takePhoto(pixelBuffer: pixelBuffer)
                break
            case .end:
                self.finishVideoRecording()
                break
            default:
                break
            }
        }
    }
    
    
    /**
     append AudioBuffer with CVPixelBuffer For Recording
     
     - Parameters:
       - sampleBuffer: ``CMSampleBuffer``
     */
    public func appendAudioQueue(sampleBuffer: CMSampleBuffer) {
        audioRecordThread.async {
            switch self.captureStatus {
            case .capturing:
                self.appendAudioBuffer(sampleBuffer: sampleBuffer)
            case .idle:
                break
            case .start:
                break
            case .end:
                break
            default:
                break
            }
        }
    }
    
  
}
