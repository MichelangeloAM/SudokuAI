//
//  CameraView.swift
//  SudokuAI
//
//  Created by Michelangelo Amoruso Manzari on 17/03/25.
//


import SwiftUI

struct CameraView: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> CameraViewController {
        return CameraViewController()
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
    }
}
