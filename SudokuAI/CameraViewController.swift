import UIKit
import AVFoundation
import Vision
import CoreML

class CameraViewController: UIViewController, CameraManagerDelegate {
    
    // Camera handling
    private let cameraManager = CameraManager()
    
    // UI Elements
    private var previewView: UIView!
    private var gridOverlayView: UIView!
    private var statusLabel: UILabel!
    private var loadingIndicator: UIActivityIndicatorView!
    
    // Processing state
    private var isProcessing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Start the camera session when the view appears
        cameraManager.startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Stop the camera session when the view disappears
        cameraManager.stopSession()
    }
    
    // Configure UI elements
    private func setupUI() {
        view.backgroundColor = .black
        
        // Create preview view for camera
        previewView = UIView()
        previewView.backgroundColor = .black
        previewView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewView)
        
        // Create grid overlay view
        gridOverlayView = UIView()
        gridOverlayView.layer.borderWidth = 4.0
        gridOverlayView.layer.borderColor = UIColor.red.cgColor
        gridOverlayView.backgroundColor = .clear
        gridOverlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridOverlayView)
        
        // Create status label
        statusLabel = UILabel()
        statusLabel.text = "Searching for Sudoku grid..."
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        // Create loading indicator
        loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        
        // Create cancel button
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        cancelButton.tintColor = .white
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        view.addSubview(cancelButton)
        
        // Create manual capture button
        let captureButton = UIButton(type: .system)
        captureButton.setImage(UIImage(systemName: "camera.circle.fill"), for: .normal)
        captureButton.tintColor = .white
        captureButton.contentVerticalAlignment = .fill
        captureButton.contentHorizontalAlignment = .fill
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.addTarget(self, action: #selector(manualCaptureButtonTapped), for: .touchUpInside)
        view.addSubview(captureButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Preview view takes up the full screen
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Grid overlay is centered with fixed size
            gridOverlayView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gridOverlayView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            gridOverlayView.widthAnchor.constraint(equalToConstant: 280),
            gridOverlayView.heightAnchor.constraint(equalToConstant: 280),
            
            // Status label is at the top
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Loading indicator is centered
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Cancel button is at the bottom left
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // Capture button is at the bottom center
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    // Configure camera
    private func setupCamera() {
        do {
            // Setup the camera manager
            try cameraManager.setupCamera()
            cameraManager.delegate = self
            
            // Setup the preview layer
            guard let previewLayer = cameraManager.previewLayer else {
                throw CameraManager.CameraError.invalidPreviewLayer
            }
            
            previewLayer.frame = view.bounds
            previewView.layer.addSublayer(previewLayer)
            
        } catch {
            showAlert(title: "Camera Error", message: "Failed to setup camera: \(error.localizedDescription)")
        }
    }
    
    // MARK: - User Actions
    
    @objc private func cancelButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func manualCaptureButtonTapped() {
        guard !isProcessing else { return }
        isProcessing = true
        
        // Update UI to show that processing is happening
        statusLabel.text = "Processing Sudoku..."
        loadingIndicator.startAnimating()
        
        // Capture the current frame manually
        captureCurrentFrame()
    }
    
    // Manually capture the current camera frame
    private func captureCurrentFrame() {
        guard let previewLayer = cameraManager.previewLayer else {
            isProcessing = false
            return
        }
        
        // Create grid rect based on the gridOverlayView's frame
        let gridFrame = gridOverlayView.frame
        
        // Create a screenshot of the current camera view
        UIGraphicsBeginImageContextWithOptions(previewView.bounds.size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            isProcessing = false
            return
        }
        
        previewLayer.render(in: context)
        
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            isProcessing = false
            return
        }
        
        UIGraphicsEndImageContext()
        
        // Process the captured image
        processCapturedImage(image, withGrid: gridFrame)
    }
    
    // MARK: - CameraManagerDelegate
    
    func cameraManager(_ manager: CameraManager, didDetectGrid detected: Bool) {
        if detected {
            // Grid detected, update UI
            gridOverlayView.layer.borderColor = UIColor.green.cgColor
            statusLabel.text = "Sudoku grid detected! Analyzing..."
            loadingIndicator.startAnimating()
        } else {
            // No grid detected, update UI
            gridOverlayView.layer.borderColor = UIColor.red.cgColor
            statusLabel.text = "Position the Sudoku grid in the frame"
            loadingIndicator.stopAnimating()
        }
    }
    
    func cameraManager(_ manager: CameraManager, didCaptureImage image: UIImage, withGrid gridRect: CGRect) {
        guard !isProcessing else { return }
        isProcessing = true
        
        // Update UI to show that processing is happening
        statusLabel.text = "Processing Sudoku..."
        loadingIndicator.startAnimating()
        
        // Process the captured image
        processCapturedImage(image, withGrid: gridRect)
    }
    
    func cameraManager(_ manager: CameraManager, didFailWithError error: Error) {
        showAlert(title: "Camera Error", message: error.localizedDescription)
    }
    
    // MARK: - Image Processing
    
    private func processCapturedImage(_ image: UIImage, withGrid gridRect: CGRect) {
        // Add debug logging
        print("Processing captured image with grid rect: \(gridRect)")
        
        // Process the Sudoku in a background thread
        DispatchQueue.global(qos: .userInitiated).async {
            // Create a slightly larger grid for manual captures to ensure we get the full grid
            var processRect = gridRect
            let margin = min(gridRect.width, gridRect.height) * 0.05 // 5% margin
            processRect = processRect.insetBy(dx: -margin, dy: -margin)
            
            // Extract the grid from the image
            let extractedGridImage = self.extractGrid(from: image, using: processRect)
            
            // Debug logging for extracted image
            print("Extracted grid image size: \(extractedGridImage.size)")
            
            // Process the Sudoku using our existing processor
            SudokuProcessor.processSudokuImage(extractedGridImage) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.loadingIndicator.stopAnimating()
                    
                    switch result {
                    case .success(let sudokuResult):
                        print("Successfully processed Sudoku grid")
                        // Show results
                        self.showSudokuResults(
                            originalGrid: sudokuResult.originalGrid,
                            solvedGrid: sudokuResult.solvedGrid,
                            gridImage: sudokuResult.gridImage
                        )
                        
                    case .failure(let error):
                        print("Failed to process Sudoku: \(error)")
                        // Show error
                        self.showProcessingError(error)
                    }
                }
            }
        }
    }
    
    // Extract the grid portion from the captured image
    private func extractGrid(from image: UIImage, using rect: CGRect) -> UIImage {
        // Create a new context to crop the image
        let scale = image.scale
        let scaledRect = CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.size.width * scale,
            height: rect.size.height * scale
        )
        
        // Debug logging
        print("Original image size: \(image.size)")
        print("Crop rect: \(scaledRect)")
        
        // Check if the rect is within the image bounds
        let imageBounds = CGRect(x: 0, y: 0, width: image.size.width * scale, height: image.size.height * scale)
        let safeRect = scaledRect.intersection(imageBounds)
        
        if safeRect.size.width <= 0 || safeRect.size.height <= 0 {
            print("Warning: Invalid crop rect, using full image")
            return image
        }
        
        if let cgImage = image.cgImage?.cropping(to: safeRect) {
            return UIImage(cgImage: cgImage, scale: scale, orientation: image.imageOrientation)
        }
        
        // Return the original image if cropping fails
        print("Warning: Cropping failed, using full image")
        return image
    }
    
    // MARK: - Result Handling
    
    // Show results of Sudoku processing
    private func showSudokuResults(originalGrid: [[Int]], solvedGrid: [[Int]], gridImage: UIImage) {
        print("Showing results with originalGrid having \(originalGrid.count) rows and solvedGrid having \(solvedGrid.count) rows")
        
        // Create a view controller to display the results
        let resultsVC = UIViewController()
        resultsVC.view.backgroundColor = .white
        
        // Create a scroll view to allow zooming and panning
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        resultsVC.view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: resultsVC.view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: resultsVC.view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: resultsVC.view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: resultsVC.view.safeAreaLayoutGuide.bottomAnchor, constant: -100)
        ])
        
        // Create a stack view for our content
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.alignment = .center
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
        
        // Add a title label
        let titleLabel = UILabel()
        titleLabel.text = "Sudoku Solver Results"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.textAlignment = .center
        contentStack.addArrangedSubview(titleLabel)
        
        // Add the original image view
        let originalImageView = UIImageView(image: gridImage)
        originalImageView.contentMode = .scaleAspectFit
        originalImageView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        contentStack.addArrangedSubview(originalImageView)
        
        // Create and add the solution grid image
        let solutionImage = SudokuProcessor.createGridImage(original: originalGrid, solved: solvedGrid)
        let solutionImageView = UIImageView(image: solutionImage)
        solutionImageView.contentMode = .scaleAspectFit
        solutionImageView.heightAnchor.constraint(equalToConstant: 300).isActive = true
        contentStack.addArrangedSubview(solutionImageView)
        
        // Add a description label
        let descLabel = UILabel()
        descLabel.text = "Original digits shown in black.\nSolution digits shown in blue."
        descLabel.font = UIFont.systemFont(ofSize: 16)
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
        contentStack.addArrangedSubview(descLabel)
        
        // Check if the Sudoku is correctly filled
        let isCorrectlyFilled = checkIfSudokuIsCorrectlyFilled(originalGrid)
        let verificationLabel = UILabel()
        verificationLabel.font = UIFont.boldSystemFont(ofSize: 18)
        verificationLabel.textAlignment = .center
        verificationLabel.numberOfLines = 0
        
        if isCorrectlyFilled {
            verificationLabel.text = "✅ Sudoku is correctly filled!"
            verificationLabel.textColor = .systemGreen
        } else {
            verificationLabel.text = "✓ Sudoku solution generated"
            verificationLabel.textColor = .systemBlue
        }
        
        contentStack.addArrangedSubview(verificationLabel)
        
        // Add buttons at the bottom
        let buttonContainer = UIStackView()
        buttonContainer.axis = .horizontal
        buttonContainer.alignment = .center
        buttonContainer.distribution = .fillEqually
        buttonContainer.spacing = 20
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        resultsVC.view.addSubview(buttonContainer)
        
        NSLayoutConstraint.activate([
            buttonContainer.heightAnchor.constraint(equalToConstant: 50),
            buttonContainer.leadingAnchor.constraint(equalTo: resultsVC.view.leadingAnchor, constant: 20),
            buttonContainer.trailingAnchor.constraint(equalTo: resultsVC.view.trailingAnchor, constant: -20),
            buttonContainer.bottomAnchor.constraint(equalTo: resultsVC.view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
        
        // Create New Scan button
        let newScanButton = UIButton(type: .system)
        newScanButton.setTitle("New Scan", for: .normal)
        newScanButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        newScanButton.tintColor = .white
        newScanButton.backgroundColor = .systemBlue
        newScanButton.layer.cornerRadius = 8
        newScanButton.addTarget(self, action: #selector(newScan), for: .touchUpInside)
        buttonContainer.addArrangedSubview(newScanButton)
        
        // Navigate to the results screen
        navigationController?.pushViewController(resultsVC, animated: true)
    }
    
    // Check if a Sudoku is correctly filled (all cells filled and valid)
    private func checkIfSudokuIsCorrectlyFilled(_ grid: [[Int]]) -> Bool {
        // Check if all cells are filled (no zeros)
        for row in grid {
            for cell in row {
                if cell == 0 {
                    return false
                }
            }
        }
        
        // Check if the grid follows Sudoku rules
        return SudokuVerifier.isValidSudoku(grid)
    }
    
    // Show error message when Sudoku processing fails
    private func showProcessingError(_ error: SudokuProcessingError) {
        print("Showing processing error: \(error)")
        
        // Create error view controller
        let errorVC = UIViewController()
        errorVC.view.backgroundColor = .white
        
        // Create error message label
        let errorLabel = UILabel()
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.font = UIFont.systemFont(ofSize: 18)
        
        // Set the error message based on the error type
        switch error {
        case .gridDetectionFailed:
            errorLabel.text = "Could not detect a Sudoku grid in the image.\n\nTry taking a clearer photo with good lighting, or use the manual capture button."
        case .digitRecognitionFailed:
            errorLabel.text = "Could not recognize digits in the grid.\n\nMake sure the Sudoku is clearly visible and try again."
        case .solutionFailed:
            errorLabel.text = "Could not solve the Sudoku puzzle.\n\nThe puzzle might be invalid or unsolvable."
        case .invalidSudoku:
            errorLabel.text = "The recognized Sudoku puzzle is invalid.\n\nPlease try again with a different angle or better lighting."
        }
        
        errorVC.view.addSubview(errorLabel)
        
        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: errorVC.view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: errorVC.view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: errorVC.view.leadingAnchor, constant: 40),
            errorLabel.trailingAnchor.constraint(equalTo: errorVC.view.trailingAnchor, constant: -40)
        ])
        
        // Add a retry button
        let retryButton = UIButton(type: .system)
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.setTitle("Try Again", for: .normal)
        retryButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        retryButton.tintColor = .white
        retryButton.backgroundColor = .systemBlue
        retryButton.layer.cornerRadius = 8
        retryButton.addTarget(self, action: #selector(newScan), for: .touchUpInside)
        
        errorVC.view.addSubview(retryButton)
        
        NSLayoutConstraint.activate([
            retryButton.centerXAnchor.constraint(equalTo: errorVC.view.centerXAnchor),
            retryButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 40),
            retryButton.widthAnchor.constraint(equalToConstant: 200),
            retryButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Present the error screen
        navigationController?.pushViewController(errorVC, animated: true)
    }
    
    @objc private func newScan() {
        // Pop back to this view controller
        navigationController?.popToViewController(self, animated: true)
        
        // Reset the camera detection and UI
        isProcessing = false
        gridOverlayView.layer.borderColor = UIColor.red.cgColor
        statusLabel.text = "Position the Sudoku grid in the frame"
        loadingIndicator.stopAnimating()
    }
    
    // MARK: - Helper Functions
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        }))
        present(alert, animated: true)
    }
}
