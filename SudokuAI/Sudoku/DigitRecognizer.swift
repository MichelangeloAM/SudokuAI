//
//  DigitRecognizer.swift
//  SudokuAI
//
//  Created by Claude on 03/06/25.
//

import UIKit
import Vision
import CoreML

class DigitRecognizer {
    
    // Recognize a digit in a single cell image
    // Returns the recognized digit or nil if no digit was detected
    static func recognizeDigit(in cellImage: UIImage) -> Int? {
        guard let cgImage = cellImage.cgImage else {
            print("Failed to get CGImage from cell image")
            return nil
        }
        
        // Check if the cell is empty by analyzing pixel values
        if isEmptyCell(cgImage) {
            return nil
        }
        
        // Create a Vision request to classify the digit
        do {
            // Load the Core ML model
            let config = MLModelConfiguration()
            let mnistModel = try MNISTClassifier(configuration: config)
            
            // Create a Vision Core ML model
            let visionModel = try VNCoreMLModel(for: mnistModel.model)
            
            // Create a request for digit classification
            let request = VNCoreMLRequest(model: visionModel)
            request.imageCropAndScaleOption = .centerCrop
            
            // Run the request on the image
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
            
            // Get the classification results
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                print("No classification results")
                return nil
            }
            
            // Convert the classification result to an integer
            // The model returns string identifiers like "1", "2", etc.
            let digit = Int(topResult.identifier)
            
            // Only accept results with a minimum confidence
            if topResult.confidence > 0.5, let digitValue = digit {
                return digitValue
            } else {
                print("Low confidence classification: \(topResult.identifier) (\(topResult.confidence))")
                return nil
            }
        } catch {
            print("Error recognizing digit: \(error)")
            return nil
        }
    }
    
    // Recognize digits in all cells of a Sudoku grid
    // Returns a 9x9 grid of integers, with 0 representing empty cells
    static func recognizeGrid(from cellImages: [[UIImage?]]) -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        
        for row in 0..<9 {
            for col in 0..<9 {
                if let cellImage = cellImages[row][col],
                   let digit = recognizeDigit(in: cellImage) {
                    grid[row][col] = digit
                }
            }
        }
        
        return grid
    }
    
    // Check if a cell is empty (contains no digit)
    private static func isEmptyCell(_ image: CGImage) -> Bool {
        // Convert to grayscale and analyze pixel values
        // Simple approach: count the number of dark pixels
        let width = image.width
        let height = image.height
        let bytesPerRow = width * 4
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(data: nil,
                                     width: width,
                                     height: height,
                                     bitsPerComponent: 8,
                                     bytesPerRow: bytesPerRow,
                                     space: CGColorSpaceCreateDeviceRGB(),
                                     bitmapInfo: bitmapInfo) else {
            return true
        }
        
        // Draw the image into the context
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Get the pixel data
        guard let data = context.data else {
            return true
        }
        
        // Count dark pixels
        let buffer = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        var darkPixelCount = 0
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * 4
                let r = buffer[pixelIndex]
                let g = buffer[pixelIndex + 1]
                let b = buffer[pixelIndex + 2]
                
                // Calculate grayscale value
                let grayValue = (Int(r) + Int(g) + Int(b)) / 3
                
                // If pixel is dark, increment counter
                if grayValue < 100 { // Threshold for considering a pixel "dark"
                    darkPixelCount += 1
                }
            }
        }
        
        // Calculate the percentage of dark pixels
        let totalPixels = width * height
        let darkPixelPercentage = Float(darkPixelCount) / Float(totalPixels)
        
        // If less than 5% of pixels are dark, consider it empty
        return darkPixelPercentage < 0.05
    }
} 