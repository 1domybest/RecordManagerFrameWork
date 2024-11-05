//
//  RecordManagerUtility.swift
//  RecordManagerFrameWork
//
//  Created by 온석태 on 11/5/24.
//

import Foundation
import UIKit

extension RecordManager {
    /**
     make ``UIImage`` from ``CVPixelBuffer``
     
     - Parameters:
       - pixelBuffer: ``CVPixelBuffer``
     */
    func createImage(from pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
}
