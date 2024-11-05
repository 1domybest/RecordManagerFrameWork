//
//  RecordManangerProtocol.swift
//  RecordManagerFrameWork
//
//  Created by 온석태 on 11/4/24.
//

import Foundation
import AVFoundation
import UIKit

/**
 ``RecordManagerFrameWorkDelegate``
 
   This is an observer that allows you to receive callbacks for the start and end of the capture process,
 
   as well as the current capture status.
 */
public protocol RecordManagerFrameWorkDelegate {
    
    /**
     ``RecordManagerFrameWorkDelegate/statusDidChange(captureStatus:)``
     
       Receives the capture status in real-time.
     
       - Parameters:
         - captureStatus: ``CaptureStatus``
     */
    func statusDidChange(captureStatus: CaptureStatus)
    
    
    /**
     ``RecordManagerFrameWorkDelegate/onStartRecord()``
     
     It is called when video recording starts.
     
     */
    func onStartRecord()
    
    /**
     ``RecordManagerFrameWorkDelegate/onFinishedRecord(fileURL:position:)``
     
       It is emitted along with the generated file's. ``URL`` and
     
       camera ``AVCaptureDevice.Position`` when the video recording ends.
     
       - Parameters:
         - fileURL: ``URL``
         - position: ``AVCaptureDevice.Position``
     */
    func onFinishedRecord(fileURL: URL, position: AVCaptureDevice.Position)
    
    /**
     ``RecordManagerFrameWorkDelegate/tookPhoto(image:)``
     
       When the photo capture ends, the captured ``UIImage`` is emitted.
     
       - Parameters:
         - image: ``UIImage``
     */
    func tookPhoto(image: UIImage)
}

