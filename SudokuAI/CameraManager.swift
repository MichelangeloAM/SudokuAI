//
//  CameraManager.swift
//  SudokuAI
//
//  Created by Claude on 06/06/25.
//

import UIKit
import AVFoundation
import Vision

protocol CameraManagerDelegate: AnyObject {
    func cameraManager(_ manager: CameraManager, didDetectGrid detected: Bool)
    func cameraManager(_ manager: CameraManager, didCaptureImage image: UIImage, withGrid gridRect: CGRect)
    func cameraManager(_ manager: CameraManager, didFailWithError error: Error)
}

class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // Camera session and output
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
    
    // Camera preview
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    // Delegate
    weak var delegate: CameraManagerDelegate?
    
    // Grid detection state
    private var isGridDetected = false
    private var gridDetectionCounter = 0
    private let requiredDetections = 10 // Number of consecutive detections needed for confirmation
    private var lastDetectedGridRect: CGRect?
    private var isProcessingFrame = false
    
    // Error handling
    enum CameraError: Error {
        case captureDeviceNotFound
        case captureSessionConfigurationFailed
        case invalidPreviewLayer
    }
    
    // Setup the camera capture session
    func setupCamera() throws {
        captureSession.beginConfiguration()
        
        // Set session preset
        if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .high
        }
        
        // Add video input
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            throw CameraError.captureDeviceNotFound
        }
        
        guard let videoInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            throw CameraError.captureSessionConfigurationFailed
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            throw CameraError.captureSessionConfigurationFailed
        }
        
        // Add video output
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        } else {
            throw CameraError.captureSessionConfigurationFailed
        }
        
        // Set orientation
        if let connection = videoDataOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = false
            }
        }
        
        captureSession.commitConfiguration()
        
        // Create preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        self.previewLayer = previewLayer
    }
    
    // Start the capture session
    func startSession() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    // Stop the capture session
    func stopSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    // Process each camera frame
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Only process frames when not already processing one
        guard !isProcessingFrame else { return }
        isProcessingFrame = true
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            isProcessingFrame = false
            return
        }
        
        // Create a CIImage from the pixel buffer
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Detect Sudoku grid in the frame
        detectSudokuGrid(in: ciImage) { [weak self] detectedRect in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let detectedRect = detectedRect {
                    // Grid detected in this frame
                    self.lastDetectedGridRect = detectedRect
                    
                    // Update counter and detection state
                    self.gridDetectionCounter += 1
                    
                    if self.gridDetectionCounter >= self.requiredDetections && !self.isGridDetected {
                        // Grid detection confirmed
                        self.isGridDetected = true
                        self.delegate?.cameraManager(self, didDetectGrid: true)
                        
                        // Auto-capture after a short delay to allow UI updates
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.captureCurrentFrame()
                        }
                    } else if !self.isGridDetected {
                        // Incrementing toward required detections
                        self.delegate?.cameraManager(self, didDetectGrid: false)
                    }
                } else {
                    // No grid detected in this frame
                    self.gridDetectionCounter = 0
                    if self.isGridDetected {
                        // Reset detection state
                        self.isGridDetected = false
                        self.delegate?.cameraManager(self, didDetectGrid: false)
                    }
                }
                
                self.isProcessingFrame = false
            }
        }
    }
    
    // Detect Sudoku grid in image
    private func detectSudokuGrid(in ciImage: CIImage, completion: @escaping (CGRect?) -> Void) {
        // Convert CIImage to CGImage for Vision framework
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            completion(nil)
            return
        }
        
        // Create a request to detect rectangles
        let request = VNDetectRectanglesRequest { (request, error) in
            if let error = error {
                print("Rectangle detection error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let observations = request.results as? [VNRectangleObservation],
                  !observations.isEmpty else {
                completion(nil)
                return
            }
            
            // Find the largest rectangle that could be a Sudoku grid
            let sortedRects = observations.sorted { rect1, rect2 in
                let area1 = rect1.boundingBox.width * rect1.boundingBox.height
                let area2 = rect2.boundingBox.width * rect2.boundingBox.height
                return area1 > area2
            }
            
            guard let bestRect = sortedRects.first else {
                completion(nil)
                return
            }
            
            // Check if the aspect ratio is approximately square
            let aspectRatio = bestRect.boundingBox.width / bestRect.boundingBox.height
            if aspectRatio >= 0.7 && aspectRatio <= 1.3 {
                // Convert normalized rect to image coordinates
                let imageWidth = CGFloat(cgImage.width)
                let imageHeight = CGFloat(cgImage.height)
                
                let x = bestRect.boundingBox.origin.x * imageWidth
                let y = (1 - bestRect.boundingBox.origin.y - bestRect.boundingBox.height) * imageHeight
                let width = bestRect.boundingBox.width * imageWidth
                let height = bestRect.boundingBox.height * imageHeight
                
                let detectedRect = CGRect(x: x, y: y, width: width, height: height)
                completion(detectedRect)
            } else {
                completion(nil)
            }
        }
        
        // Set the parameters for the rectangle detection request
        request.minimumAspectRatio = 0.7
        request.maximumAspectRatio = 1.3
        request.minimumSize = 0.1
        request.maximumObservations = 10
        
        // Perform the request
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            completion(nil)
        }
    }
    
    // Capture the current frame with the detected grid
    private func captureCurrentFrame() {
        guard let lastDetectedGridRect = self.lastDetectedGridRect else { return }
        
        // Create a screenshot of the current camera preview
        guard let previewLayer = self.previewLayer else { return }
        
        UIGraphicsBeginImageContextWithOptions(previewLayer.frame.size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        previewLayer.render(in: context)
        
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return
        }
        
        UIGraphicsEndImageContext()
        
        // Pass the captured image and grid rect to the delegate
        self.delegate?.cameraManager(self, didCaptureImage: image, withGrid: lastDetectedGridRect)
        
        // Reset for next capture
        self.isGridDetected = false
        self.gridDetectionCounter = 0
    }
} 