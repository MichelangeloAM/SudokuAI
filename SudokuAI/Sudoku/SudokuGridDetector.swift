//
//  SudokuGridDetector.swift
//  SudokuAI
//
//  Created by Claude on 03/06/25.
//

import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

class SudokuGridDetector {
    
    // Main function to detect and extract a Sudoku grid from an image
    // Returns the processed image with the detected grid highlighted,
    // and an array of individual cell images for digit recognition
    static func detectGrid(from inputImage: UIImage) -> (UIImage?, [[UIImage?]]?) {
        guard let cgImage = inputImage.cgImage else {
            print("Failed to get CGImage from input image")
            return (nil, nil)
        }
        
        // Step 1: Apply preprocessing to enhance grid visibility
        guard let preprocessedImage = preprocessImage(cgImage) else {
            print("Failed to preprocess image")
            return (nil, nil)
        }
        
        // Step 2: Detect rectangular contours that might be the Sudoku grid
        guard let gridRect = detectLargestRectangle(in: preprocessedImage) else {
            print("Failed to detect Sudoku grid")
            return (UIImage(cgImage: preprocessedImage), nil)
        }
        
        // Step 3: Extract and warp the grid to a square perspective
        guard let warpedGrid = extractAndWarpGrid(from: preprocessedImage, gridRect: gridRect) else {
            print("Failed to extract and warp grid")
            return (UIImage(cgImage: preprocessedImage), nil)
        }
        
        // Step 4: Divide the grid into 81 cells
        let cellImages = extractCells(from: warpedGrid)
        
        // Create a result image with the detected grid highlighted for debugging
        let resultImage = drawRectangleOnImage(UIImage(cgImage: preprocessedImage), rect: gridRect)
        
        return (resultImage, cellImages)
    }
    
    // Preprocess the image to enhance grid visibility
    private static func preprocessImage(_ inputImage: CGImage) -> CGImage? {
        let ciImage = CIImage(cgImage: inputImage)
        let context = CIContext()
        
        // Apply grayscale
        let grayscaleFilter = CIFilter.colorControls()
        grayscaleFilter.setValue(ciImage, forKey: kCIInputImageKey)
        grayscaleFilter.setValue(0, forKey: kCIInputSaturationKey) // 0 = grayscale
        
        guard let grayscaleOutput = grayscaleFilter.outputImage else {
            return inputImage
        }
        
        // Apply contrast enhancement
        let contrastFilter = CIFilter.colorControls()
        contrastFilter.setValue(grayscaleOutput, forKey: kCIInputImageKey)
        contrastFilter.setValue(1.5, forKey: kCIInputContrastKey) // Increase contrast
        
        guard let contrastOutput = contrastFilter.outputImage,
              let cgImage = context.createCGImage(contrastOutput, from: contrastOutput.extent) else {
            return inputImage
        }
        
        return cgImage
    }
    
    // Detect the largest rectangular shape in the image (likely the Sudoku grid)
    private static func detectLargestRectangle(in image: CGImage) -> CGRect? {
        let request = VNDetectRectanglesRequest()
        request.minimumAspectRatio = 0.7
        request.maximumAspectRatio = 1.3
        request.minimumSize = 0.5
        request.maximumObservations = 10
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        
        do {
            try handler.perform([request])
            
            if let results = request.results as? [VNRectangleObservation], !results.isEmpty {
                // Sort by size (area) to find the largest rectangle
                let sortedResults = results.sorted { rect1, rect2 in
                    let area1 = rect1.boundingBox.width * rect1.boundingBox.height
                    let area2 = rect2.boundingBox.width * rect2.boundingBox.height
                    return area1 > area2
                }
                
                // Return the bounding box of the largest rectangle
                if let largestRect = sortedResults.first {
                    // Convert normalized coordinates to image coordinates
                    let imageWidth = CGFloat(image.width)
                    let imageHeight = CGFloat(image.height)
                    
                    let x = largestRect.boundingBox.origin.x * imageWidth
                    let y = (1 - largestRect.boundingBox.origin.y - largestRect.boundingBox.height) * imageHeight
                    let width = largestRect.boundingBox.width * imageWidth
                    let height = largestRect.boundingBox.height * imageHeight
                    
                    return CGRect(x: x, y: y, width: width, height: height)
                }
            }
            
            return nil
        } catch {
            print("Error detecting rectangles: \(error)")
            return nil
        }
    }
    
    // Extract and warp the grid to a square perspective
    private static func extractAndWarpGrid(from image: CGImage, gridRect: CGRect) -> CGImage? {
        // Create a perspective transform from the detected rectangle to a square
        let sourceSize = CGFloat(min(image.width, image.height))
        let targetSize = CGFloat(min(image.width, image.height))
        
        // Create a CIImage from the CGImage
        let ciImage = CIImage(cgImage: image)
        
        // Define the four corners of the grid
        let topLeft = CGPoint(x: gridRect.minX, y: gridRect.minY)
        let topRight = CGPoint(x: gridRect.maxX, y: gridRect.minY)
        let bottomLeft = CGPoint(x: gridRect.minX, y: gridRect.maxY)
        let bottomRight = CGPoint(x: gridRect.maxX, y: gridRect.maxY)
        
        // Apply perspective correction
        let perspectiveFilter = CIFilter.perspectiveCorrection()
        perspectiveFilter.setValue(ciImage, forKey: kCIInputImageKey)
        perspectiveFilter.setValue(CIVector(cgPoint: topLeft), forKey: "inputTopLeft")
        perspectiveFilter.setValue(CIVector(cgPoint: topRight), forKey: "inputTopRight")
        perspectiveFilter.setValue(CIVector(cgPoint: bottomLeft), forKey: "inputBottomLeft")
        perspectiveFilter.setValue(CIVector(cgPoint: bottomRight), forKey: "inputBottomRight")
        
        guard let perspectiveOutput = perspectiveFilter.outputImage else {
            return image
        }
        
        // Create a CGImage from the CIImage
        let context = CIContext()
        return context.createCGImage(perspectiveOutput, from: perspectiveOutput.extent)
    }
    
    // Extract individual cells from the grid
    private static func extractCells(from gridImage: CGImage) -> [[UIImage?]] {
        let gridWidth = gridImage.width
        let gridHeight = gridImage.height
        
        let cellWidth = gridWidth / 9
        let cellHeight = gridHeight / 9
        
        var cellImages = Array(repeating: Array(repeating: nil as UIImage?, count: 9), count: 9)
        
        for row in 0..<9 {
            for col in 0..<9 {
                let x = col * cellWidth
                let y = row * cellHeight
                
                // Create a CGImage for each cell
                if let cellCGImage = gridImage.cropping(to: CGRect(x: x, y: y, width: cellWidth, height: cellHeight)) {
                    // Convert to UIImage
                    let cellUIImage = UIImage(cgImage: cellCGImage)
                    
                    // Apply additional processing to isolate the digit
                    cellImages[row][col] = preprocessCellForOCR(cellUIImage)
                }
            }
        }
        
        return cellImages
    }
    
    // Preprocess a cell image to isolate the digit for OCR
    private static func preprocessCellForOCR(_ cellImage: UIImage) -> UIImage {
        guard let cgImage = cellImage.cgImage else {
            return cellImage
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()
        
        // Step 1: Convert to grayscale
        let grayscaleFilter = CIFilter.colorControls()
        grayscaleFilter.setValue(ciImage, forKey: kCIInputImageKey)
        grayscaleFilter.setValue(0, forKey: kCIInputSaturationKey)
        
        guard let grayscaleOutput = grayscaleFilter.outputImage else {
            return cellImage
        }
        
        // Step 2: Apply adaptive thresholding
        let thresholdFilter = CIFilter.colorThreshold()
        thresholdFilter.setValue(grayscaleOutput, forKey: kCIInputImageKey)
        thresholdFilter.setValue(0.5, forKey: "inputThreshold")
        
        guard let thresholdOutput = thresholdFilter.outputImage,
              let resultCGImage = context.createCGImage(thresholdOutput, from: thresholdOutput.extent) else {
            return cellImage
        }
        
        // Step 3: Crop to remove border (which can interfere with OCR)
        let width = resultCGImage.width
        let height = resultCGImage.height
        let cropMargin = Int(min(width, height) * 0.15) // 15% margin
        
        let cropRect = CGRect(
            x: cropMargin,
            y: cropMargin,
            width: width - (2 * cropMargin),
            height: height - (2 * cropMargin)
        )
        
        if let croppedImage = resultCGImage.cropping(to: cropRect) {
            return UIImage(cgImage: croppedImage)
        }
        
        return UIImage(cgImage: resultCGImage)
    }
    
    // Draw a rectangle on an image for visualization
    private static func drawRectangleOnImage(_ image: UIImage, rect: CGRect) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        
        let context = UIGraphicsGetCurrentContext()!
        image.draw(at: .zero)
        
        context.setStrokeColor(UIColor.red.cgColor)
        context.setLineWidth(4.0)
        context.stroke(rect)
        
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return resultImage
    }
} 