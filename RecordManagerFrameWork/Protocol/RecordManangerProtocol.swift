//
//  RecordManangerProtocol.swift
//  RecordManagerFrameWork
//
//  Created by 온석태 on 11/4/24.
//

import Foundation
import AVFoundation

protocol RecordManangerProtocol {
    func statusDidChange(captureStatus: CaptureStatus)
    func onStartRecord()
    func onFinishedRecord(fileURL: URL, position: AVCaptureDevice.Position)
}

