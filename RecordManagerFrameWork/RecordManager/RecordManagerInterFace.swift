//
//  RecordManagerInterface.swift
//  CameraManagerExample
//
//  Created by 온석태 on 11/5/24.
//

import Foundation
import AVFoundation

extension RecordManager {
    
    /**
     ``setRecordOptions()``
     
     set New RecordOptions
     
     but only works when ``CaptureStatus`` not ``CaptureStatus/capturing``
     
     - Parameters:
       - recordOptions: ``RecordOptions``
     */
    public func setRecordOptions(recordOptions: RecordOptions) {
        if self.captureStatus != .capturing {
            self.recordOptions = recordOptions
            self.initialize()
        } else {
            print("you should stop recording first")
        }
    }
    
    /**
     ``setNewRecordFileInfo()``
     
     set New RecordFileInfo
     
     this is for when you make new Video
     
     you should set new info after ``RecordManagerFrameWorkDelegate/onFinishedRecord(fileURL:position:)``
     
     - Parameters:
       - recordOptions: ``RecordOptions``
     */
    public func setNewRecordFileInfo(
        filePath: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!,
        fileName: String = UUID().uuidString + ".mp4"
    ) {
        self.fileName = fileName
        self.fileURL = filePath.appendingPathComponent(fileName)
    }
    
    /**
     Sets ``RecordManager`` Delegate

     - Parameters:
       - recordManagerFrameWorkDelegate: ``RecordManagerFrameWorkDelegate``
     */
    public func setRecordManagerFrameWorkDelegate(recordManagerFrameWorkDelegate: RecordManagerFrameWorkDelegate) {
        self.recordManagerFrameWorkDelegate = recordManagerFrameWorkDelegate
    }
    
    /**
     start Video Record
     */
    public func startVideoRecording () {
        self.captureStatus = .capturing
        self.recordManagerFrameWorkDelegate?.onStartRecord()
    }
    
    /**
     stop Video Record
     */
    public func stopVideoRecording () {
        captureStatus = .end
    }
    
    
    /**
     takePhoto
     
     When the photo capture is successful,
     
     a callback will be sent to ``RecordManagerFrameWorkDelegate/tookPhoto(image:)``
     */
    public func takePhoto () {
          captureStatus = .takePhoto
    }
}



