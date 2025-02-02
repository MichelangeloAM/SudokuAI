//
//  CameraViewController.swift
//  SudokuAI
//
//  Created by Michelangelo Amoruso Manzari on 02/02/25.
//

import UIKit
import AVFoundation
import Vision
import SudokuVerifier

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var captureSession: AVCaptureSession!
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Request camera permission
        DispatchQueue.main.async { [unweak self] in
            guard let strongSelf = self else { return }
            
            if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
                strongSelf.configureCamera()
            } else {
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                    if granted {
                        strongSelf.configureCamera()
                    }
                })
            }
        }
    }
    
    func configureCamera() {
        captureSession = AVCaptureSession()
        
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                
                // Add video data output
                let output = AVCaptureVideoDataOutput()
                output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
                if captureSession.canAddOutput(output) {
                    captureSession.addOutput(output)
                }
                
                previewLayer.session = captureSession
                view.layer.insertSublayer(previewLayer, at: 0)
                
                // Start the session
                captureSession.startRunning()
            }
        } catch let error {
            print("Error configuring camera: \(error)")
        }
    }
    
    func processFrame(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Convert to CIImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Load the Vision request handler
        guard let model = try? VNCoreMLModel(for: SudokuNumberRecognizer().model) else { return }
        let request = VNCoreMLRequest(model: model)

        let orientation = CGImagePropertyOrientation(previewLayer.connection?.imageOrientation ?? .up)
        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, orientation: Int(orientation.rawValue))

        do {
            try imageRequestHandler.perform([request])
        } catch let error {
            print("Error processing request: \(error)")
        }

        // Handle the results
        if let observations = request.results as? [VNClassificationObservation] {
            for observation in observations where observation.confidence > 0.8 {
                if let number = Int(observation.identifier) {
                    // Add logic to collect numbers and verify Sudoku grid
                    print("Detected number: \(number)")
                    
                    
                }
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processFrame(sampleBuffer: sampleBuffer)
    }
}
