import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // App logo/icon
                Image(systemName: "number.square")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                // App title
                Text("Sudoku Solver AI")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.primary)
                
                // App description
                Text("Take a photo of a Sudoku puzzle\nand get the solution instantly")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Spacer()
                
                // Camera button
                NavigationLink(destination: CameraViewControllerWrapper()) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                        Text("Scan Sudoku")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Footer text
                Text("Powered by Computer Vision & ML")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarHidden(true)
        }
    }
}

// A UIViewControllerRepresentable to wrap your UIKit CameraViewController
struct CameraViewControllerWrapper: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> CameraViewController {
        CameraViewController()
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // Nothing special needed here
    }
}
