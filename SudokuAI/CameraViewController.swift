import UIKit
import AVFoundation
import Vision
import CoreML

class CameraViewController: UIViewController,
                            UIImagePickerControllerDelegate,
                            UINavigationControllerDelegate {
    
    private var capturedImage: UIImage?
    private var imagePicker: UIImagePickerController?
    private var didShowCameraOnce = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }
    
    // Present the camera automatically when the view is fully visible
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // If camera not shown yet, present it. Otherwise, don't.
        guard !didShowCameraOnce else { return }
        didShowCameraOnce = true
        presentCameraInterface()
    }
    
    private func presentCameraInterface() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("No camera on this device.")
            return
        }
        
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = false
        picker.cameraCaptureMode = .photo
        picker.cameraDevice = .rear
        
        // Force flash on if available
        if UIImagePickerController.isFlashAvailable(for: .rear) {
            picker.cameraFlashMode = .auto
        }
        
        // Create a custom overlay view with a red square
        let overlayView = UIView(frame: UIScreen.main.bounds)
        overlayView.backgroundColor = .clear
        overlayView.isUserInteractionEnabled = false

        let focusRect = UIView()
        focusRect.isUserInteractionEnabled = false
        focusRect.layer.borderColor = UIColor.red.cgColor
        focusRect.layer.borderWidth = 4.0
        focusRect.translatesAutoresizingMaskIntoConstraints = false
        overlayView.addSubview(focusRect)

        // Center the focusRect in overlay
        NSLayoutConstraint.activate([
            focusRect.widthAnchor.constraint(equalToConstant: 250),
            focusRect.heightAnchor.constraint(equalToConstant: 250),
            focusRect.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            focusRect.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor)
        ])

        // Assign the overlay to the picker
        picker.cameraOverlayView = overlayView
        
        // Show default iOS camera UI
        picker.showsCameraControls = true
        
        self.imagePicker = picker
        
        // Show the camera interface
        present(picker, animated: true)
    }
    
    // Handle the captured image
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Remove the overlay so Apple's preview can proceed without freezing
        picker.cameraOverlayView = nil

        if let image = info[.originalImage] as? UIImage {
            dismiss(animated: true) {
                self.showCapturedPhoto(image)
            }
        } else {
            dismiss(animated: true)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Remove the overlay so Apple's preview can proceed
        picker.cameraOverlayView = nil

        dismiss(animated: true) {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func showCapturedPhoto(_ image: UIImage) {
        // Create a view controller to display the captured photo and the 2 buttons
        let photoVC = UIViewController()
        photoVC.view.backgroundColor = .black

        // Create the image view
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        photoVC.view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: photoVC.view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: photoVC.view.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: photoVC.view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: photoVC.view.bottomAnchor, constant: -100)
        ])

        // Create a container for the buttons
        let buttonContainer = UIStackView()
        buttonContainer.axis = .horizontal
        buttonContainer.alignment = .center
        buttonContainer.distribution = .fillEqually
        buttonContainer.spacing = 20
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        photoVC.view.addSubview(buttonContainer)

        NSLayoutConstraint.activate([
            buttonContainer.heightAnchor.constraint(equalToConstant: 50),
            buttonContainer.leadingAnchor.constraint(equalTo: photoVC.view.leadingAnchor, constant: 20),
            buttonContainer.trailingAnchor.constraint(equalTo: photoVC.view.trailingAnchor, constant: -20),
            buttonContainer.bottomAnchor.constraint(equalTo: photoVC.view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])

        // Create Retake button
        let retakeButton = UIButton(type: .system)
        retakeButton.setTitle("Retake", for: .normal)
        retakeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        retakeButton.tintColor = .white
        retakeButton.backgroundColor = .systemRed
        retakeButton.layer.cornerRadius = 8
        retakeButton.addTarget(self, action: #selector(retakePhoto), for: .touchUpInside)
        buttonContainer.addArrangedSubview(retakeButton)

        // Create Verify button
        let verifyButton = UIButton(type: .system)
        verifyButton.setTitle("Verify", for: .normal)
        verifyButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        verifyButton.tintColor = .white
        verifyButton.backgroundColor = .systemGreen
        verifyButton.layer.cornerRadius = 8
        verifyButton.addTarget(self, action: #selector(verifyPhoto), for: .touchUpInside)
        buttonContainer.addArrangedSubview(verifyButton)

        // Save the captured image for later use (e.g., verification)
        self.capturedImage = image

        // Push onto navigation stack if we have one
        navigationController?.pushViewController(photoVC, animated: true)
    }

    @objc private func retakePhoto() {
        // Pop back to the CameraViewController so user can take another photo
        navigationController?.popViewController(animated: true)
    }

    @objc private func verifyPhoto() {
        guard let image = capturedImage else { return }

        // Create a loading view controller (spinner overlay)
        let loadingVC = UIViewController()
        loadingVC.view.backgroundColor = UIColor(white: 0, alpha: 0.7)

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.translatesAutoresizingMaskIntoConstraints = false
        loadingVC.view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: loadingVC.view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: loadingVC.view.centerYAnchor)
        ])
        spinner.startAnimating()

        // Present loading VC modally
        loadingVC.modalPresentationStyle = .overFullScreen
        if let topVC = navigationController?.topViewController {
            topVC.present(loadingVC, animated: false)
        }

        // Use our SudokuProcessor to detect and solve the Sudoku
        SudokuProcessor.processSudokuImage(image) { result in
            // Dismiss the loading indicator
            loadingVC.dismiss(animated: true) {
                switch result {
                case .success(let sudokuResult):
                    // Show results
                    self.showSudokuResults(
                        originalGrid: sudokuResult.originalGrid,
                        solvedGrid: sudokuResult.solvedGrid,
                        gridImage: sudokuResult.gridImage
                    )
                    
                case .failure(let error):
                    // Show error
                    self.showProcessingError(error)
                }
            }
        }
    }

    // Show results of Sudoku processing
    private func showSudokuResults(originalGrid: [[Int]], solvedGrid: [[Int]], gridImage: UIImage) {
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

    // Show error message when Sudoku processing fails
    private func showProcessingError(_ error: SudokuProcessingError) {
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
            errorLabel.text = "Could not detect a Sudoku grid in the image.\nPlease try again with a clearer photo."
        case .digitRecognitionFailed:
            errorLabel.text = "Could not recognize all digits in the grid.\nPlease try again with a clearer photo."
        case .solutionFailed:
            errorLabel.text = "Could not solve the Sudoku puzzle.\nThe puzzle might be invalid or unsolvable."
        case .invalidSudoku:
            errorLabel.text = "The recognized Sudoku puzzle is invalid.\nPlease try again with a different puzzle."
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
        // Pop back to root view controller
        navigationController?.popToRootViewController(animated: true)
    }

    // This function is no longer needed since we use SudokuProcessor now
    private func showRecognizedDigits(_ digits: [String]) {
        // This function is kept for backward compatibility but we no longer use it
        print("Legacy function called: showRecognizedDigits")
    }
}
