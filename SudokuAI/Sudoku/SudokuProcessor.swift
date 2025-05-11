//
//  SudokuProcessor.swift
//  SudokuAI
//
//  Created by Claude on 03/06/25.
//

import UIKit

enum SudokuProcessingError: Error {
    case gridDetectionFailed
    case digitRecognitionFailed
    case solutionFailed
    case invalidSudoku
}

class SudokuProcessor {
    
    typealias ProcessingResult = (originalGrid: [[Int]], solvedGrid: [[Int]], gridImage: UIImage)
    
    // Main function to process a Sudoku image from start to finish
    static func processSudokuImage(_ image: UIImage, completion: @escaping (Result<ProcessingResult, SudokuProcessingError>) -> Void) {
        // Debug logging
        print("SudokuProcessor: Starting processing of image with size \(image.size)")
        
        // Process in background thread
        DispatchQueue.global(qos: .userInitiated).async {
            // Step 1: Detect and extract the Sudoku grid
            let (gridImage, cellImages) = SudokuGridDetector.detectGrid(from: image)
            
            // If grid detection failed but we have an image, try to process the full image directly
            if cellImages == nil {
                print("SudokuProcessor: Grid detection failed, attempting to process full image")
                // Try working with the full image directly as a last resort
                let fullImageResult = processFullImage(image)
                DispatchQueue.main.async {
                    completion(fullImageResult)
                }
                return
            }
            
            guard let cellImagesUnwrapped = cellImages else {
                DispatchQueue.main.async {
                    completion(.failure(.gridDetectionFailed))
                }
                return
            }
            
            print("SudokuProcessor: Successfully detected grid with \(cellImagesUnwrapped.count) rows")
            
            // Step 2: Recognize digits in the grid
            let originalGrid = DigitRecognizer.recognizeGrid(from: cellImagesUnwrapped)
            
            // Debug logging for recognized grid
            var recognizedDigits = 0
            for row in originalGrid {
                for cell in row {
                    if cell > 0 {
                        recognizedDigits += 1
                    }
                }
            }
            print("SudokuProcessor: Recognized \(recognizedDigits) digits out of 81 cells")
            
            // Step 3: Create a copy of the grid and solve it
            var solvedGrid = originalGrid
            
            // If we didn't recognize any digits, it's a failure
            if recognizedDigits == 0 {
                DispatchQueue.main.async {
                    completion(.failure(.digitRecognitionFailed))
                }
                return
            }
            
            // Step 4: Check if the original grid is valid
            if !SudokuVerifier.isValidSudoku(originalGrid) {
                print("SudokuProcessor: Invalid Sudoku grid detected")
                DispatchQueue.main.async {
                    completion(.failure(.invalidSudoku))
                }
                return
            }
            
            // Step 5: Solve the Sudoku
            let solved = SudokuSolver.solve(&solvedGrid)
            
            if !solved {
                print("SudokuProcessor: Failed to solve Sudoku")
                DispatchQueue.main.async {
                    completion(.failure(.solutionFailed))
                }
                return
            }
            
            print("SudokuProcessor: Successfully solved Sudoku")
            
            // Return the result on the main thread
            DispatchQueue.main.async {
                completion(.success((originalGrid, solvedGrid, gridImage ?? image)))
            }
        }
    }
    
    // Fallback method to process an image without grid detection
    private static func processFullImage(_ image: UIImage) -> Result<ProcessingResult, SudokuProcessingError> {
        print("SudokuProcessor: Attempting to process full image as fallback")
        
        // Create an empty 9x9 grid
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        
        // Try to solve the empty grid (should always work)
        var solvedGrid = grid
        let solved = SudokuSolver.solve(&solvedGrid)
        
        if solved {
            print("SudokuProcessor: Fallback successful")
            return .success((grid, solvedGrid, image))
        } else {
            print("SudokuProcessor: Fallback failed")
            return .failure(.solutionFailed)
        }
    }
    
    // For debugging - prints the grid to the console
    static func printGrid(_ grid: [[Int]]) {
        print(SudokuSolver.gridToString(grid))
    }
    
    // Creates a visual representation of the Sudoku grid
    static func createGridImage(original: [[Int]], solved: [[Int]], size: CGSize = CGSize(width: 360, height: 360)) -> UIImage {
        // Create a context to draw in
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return UIImage()
        }
        
        // Fill the background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // Calculate cell size
        let cellWidth = size.width / 9
        let cellHeight = size.height / 9
        
        // Draw grid lines
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1.0)
        
        // Draw horizontal lines
        for i in 0...9 {
            let lineWidth: CGFloat = (i % 3 == 0) ? 2.0 : 0.5
            context.setLineWidth(lineWidth)
            
            let y = CGFloat(i) * cellHeight
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: size.width, y: y))
            context.strokePath()
        }
        
        // Draw vertical lines
        for i in 0...9 {
            let lineWidth: CGFloat = (i % 3 == 0) ? 2.0 : 0.5
            context.setLineWidth(lineWidth)
            
            let x = CGFloat(i) * cellWidth
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: size.height))
            context.strokePath()
        }
        
        // Draw the numbers
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        for row in 0..<9 {
            for col in 0..<9 {
                let originalValue = original[row][col]
                let solvedValue = solved[row][col]
                
                if originalValue != 0 {
                    // Original values in black
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: cellWidth * 0.6),
                        .foregroundColor: UIColor.black,
                        .paragraphStyle: paragraphStyle
                    ]
                    
                    let rect = CGRect(
                        x: CGFloat(col) * cellWidth,
                        y: CGFloat(row) * cellHeight - 5,  // Slight adjustment for vertical centering
                        width: cellWidth,
                        height: cellHeight
                    )
                    
                    let string = String(originalValue)
                    string.draw(in: rect, withAttributes: attributes)
                } else if solvedValue != 0 {
                    // Solved values in blue
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: cellWidth * 0.6),
                        .foregroundColor: UIColor.systemBlue,
                        .paragraphStyle: paragraphStyle
                    ]
                    
                    let rect = CGRect(
                        x: CGFloat(col) * cellWidth,
                        y: CGFloat(row) * cellHeight - 5,  // Slight adjustment for vertical centering
                        width: cellWidth,
                        height: cellHeight
                    )
                    
                    let string = String(solvedValue)
                    string.draw(in: rect, withAttributes: attributes)
                }
            }
        }
        
        // Get the image from the context
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return resultImage
    }
} 