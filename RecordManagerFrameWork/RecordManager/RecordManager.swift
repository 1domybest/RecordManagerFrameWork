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

///
/// 촬영, 녹화 매니저
///
/// - Parameters:
/// - Returns:
///
public class RecordManager {
    
    public var assetWriter: AVAssetWriter?
    public var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor!
    public var assetWriterVideoInput: AVAssetWriterInput?
    public var assetWriterAudioInput: AVAssetWriterInput?
    public let fileManager = FileManager.default
    public var fileURL: URL?
    public var fileName: String = ""
    public var atSourceTime:CMTime?
    public var lastSourceTime:CMTime?
    public var audioSampleBufferList: [CMSampleBuffer] = []
    public var frameCount:Int64 = 0
    public let videoRecordThread = DispatchQueue(label: "VideoRecord")
    public let audioRecordThread = DispatchQueue(label: "AudioRecord")
    
    public var captureStatus: CaptureStatus = .idle
    public var recordManangerFrameWorkDelegate: RecordManangerFrameWorkDelegate?
    public var position: AVCaptureDevice.Position?
    
    public var didRequestFinish: Bool = false
    
    deinit {
        print("RecordManager deinit")
    }
    
    public init() {
        
    }
    ///
    /// 촬영전 AVAssetWriter 초기화 해주는 함수
    ///
    /// - Parameters:
    /// - Returns:
    ///
    public func initialize () {
        
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileName = UUID().uuidString + ".mp4"
        fileURL = documentDirectory.appendingPathComponent(fileName)
        
        // 2. assetWriter로 파일경로, 파일타입 설정
        do {
            assetWriter = try AVAssetWriter(outputURL: fileURL!, fileType: .mp4)
        } catch {
            print("Error creating asset writer: \(error.localizedDescription)")
            return
        }
        
        
        // 3. 영상 화질 설정
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 720,
            AVVideoHeightKey: 1280
        ]
        
        
        let audioSettings: [String: Any] = [
          AVNumberOfChannelsKey: NSNumber(value: 1),
          //AVEncoderBitRatePerChannelKey: NSNumber(value: 64000),
          AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC),
          AVSampleRateKey: NSNumber(value: 44100),
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
          kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA,
          kCVPixelBufferWidthKey as String : 720,
          kCVPixelBufferHeightKey as String : 1280 ]

        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput!, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
        
        assetWriterVideoInput?.expectsMediaDataInRealTime = true
        assetWriterAudioInput?.expectsMediaDataInRealTime = true
        
        assetWriter?.add(assetWriterVideoInput!)
        assetWriter?.add(assetWriterAudioInput!)
        
        // 5. write 시작
        assetWriter?.startWriting()
        
        captureStatus = .ready
    }
    
    ///
    /// 콜백 등록
    ///
    /// - Parameters:
    /// - Returns:
    ///
    public func setRecordManangerFrameWorkDelegate(recordManangerFrameWorkDelegate: RecordManangerFrameWorkDelegate) {
        self.recordManangerFrameWorkDelegate = recordManangerFrameWorkDelegate
    }
    
    ///
    /// 비디오 촬영 시작 함수 [변수로 상태  변환]
    ///
    /// - Parameters:
    /// - Returns:
    ///
    public func startVideoRecording () {
        self.captureStatus = .capturing
        self.recordManangerFrameWorkDelegate?.onStartRecord()
    }
    
    ///
    /// 비디오 촬영 종료 함수 [변수로 상태  변환]
    ///
    /// - Parameters:
    /// - Returns:
    ///
    public func stopVideoRecording () {
        captureStatus = .end
    }
    
    ///
    /// 비디오 촬영 종료후 후처리 함수
    ///
    /// - Parameters:
    /// - Returns:
    ///
    public func finishVideoRecording () {
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
                self.recordManangerFrameWorkDelegate?.onFinishedRecord(fileURL: fileURL, position: position)
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

    ///
    /// 비디오 관련 버퍼를 파일에 append 해주는 함수
    ///
    /// - Parameters:
    ///    - pixelBuffer ( CVPixelBuffer ) : 카메라에서 받아온 프레임 버퍼
    ///    - time ( CMTime ) : SampleBuffer에 등록된 타임스탬프
    /// - Returns:
    ///
    public func appendVideoBuffer (pixelBuffer: CVPixelBuffer, time: CMTime) {
        if self.atSourceTime == nil {
            self.atSourceTime = time
            assetWriter?.startSession(atSourceTime: self.atSourceTime!)
        }
        if assetWriterVideoInput?.isReadyForMoreMediaData == true {
            assetWriterPixelBufferInput.append(pixelBuffer, withPresentationTime: time)
        } else {
            print("failure")
        }
    }
    
    ///
    /// 오디오  관련 버퍼를 파일에 append 해주는 함수
    ///
    /// - Parameters:
    ///    - sampleBuffer ( CMSampleBuffer ) : 마이크에서 받아온 프레임 버퍼
    /// - Returns:
    ///
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
    
    
    ///
    /// 사진  촬영 시작 함수 [변수로 상태  변환]
    ///
    /// - Parameters:
    /// - Returns:
    ///
    public func takePhoto () {
        captureStatus = .takePhoto
    }
    
    ///
    /// 사진  촬영 처리 함수 [변수로 상태  변환]
    ///
    /// - Parameters:
    /// - Returns:
    ///
    public func takePhoto (pixelBuffer: CVPixelBuffer) {
        if let image = createImage(from: pixelBuffer) {
                saveImageToPhotos(image)
        }
        captureStatus = .ready
    }
    
    ///
    /// 촬영한 비디오를 사진앱에 저장해주는 함수
    ///
    /// - Parameters:
    ///    - url ( URL ) : 촬영된 비디오의 경로
    /// - Returns:
    ///
    public func saveVideoToPhotos(url: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }) { success, error in
                    if success {
                        print("비디오가 사진 라이브러리에 저장되었습니다.")
                    } else {
                        print("비디오 저장 실패: \(String(describing: error))")
                    }
                }
            } else {
                print("사진 라이브러리 접근 권한이 없습니다.")
            }
        }
    }
    
    ///
    /// 촬영한 사진을 사진앱에 저장해주는 함수
    ///
    /// - Parameters:
    ///    - image ( image ) : 촬영된 사진
    /// - Returns:
    ///
    public func saveImageToPhotos(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            } else {
                print("사진 라이브러리 접근 권한이 없습니다.")
            }
        }
    }
    
    ///
    /// CVPixelBuffer -> UIImage 변환 함수
    ///
    /// - Parameters:
    ///    - pixelBuffer ( CVPixelBuffer ) : 저장할 사진에대한 CVPixelBuffer
    /// - Returns:
    ///
    public func createImage(from pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
}

///
/// 카메라/마이크 에서  매 프레임마다 sampleBuffer 가 넘어오는 callback extension
///
/// - Parameters:
/// - Returns:
///
extension RecordManager {
    
    public func appendVideoQueue(sampleBuffer: CMSampleBuffer, position: AVCaptureDevice.Position) {
        
        guard var pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
              return
          }
        
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        
        self.recordManangerFrameWorkDelegate?.statusDidChange(captureStatus: self.captureStatus)
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
    
    public func appendVideoQueue(pixelBuffer: CVPixelBuffer, time: CMTime, position: AVCaptureDevice.Position) {
        self.recordManangerFrameWorkDelegate?.statusDidChange(captureStatus: self.captureStatus)
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
