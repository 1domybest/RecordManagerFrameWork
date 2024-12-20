//
//  CaptureStatus.swift
//  RecordManagerFrameWork
//
//  Created by 온석태 on 11/4/24.
//

import Foundation
///
/// 현재 녹음 상태에대한 enum
///
/// - Parameters:
///  - idle : 기본
///  - ready : 촬영준비
///  - start : 촬영시작
///  - capturing : 촬영중
///  - end : 촬영종료
///  - takePhoto : 사진촬영
/// - Returns:
///
public enum CaptureStatus:String {
    case idle = "idle"
    case ready = "ready"
    case start = "start"
    case capturing = "capturing"
    case end = "end"
    case takePhoto = "takePhoto"
}
