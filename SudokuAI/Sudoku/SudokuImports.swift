//
//  SudokuImports.swift
//  SudokuAI
//
//  Created by Claude on 03/06/25.
//

// This file doesn't contain any actual code
// It's just a convenient place to document all the Sudoku components
// and their dependencies

/*
 Components overview:
 
 1. SudokuGridDetector
    - Detects and extracts the Sudoku grid from an image
    - Uses Vision and Core Image for image processing
 
 2. DigitRecognizer
    - Recognizes digits in grid cells using the MNIST classifier
    - Uses Vision and Core ML
 
 3. SudokuVerifier
    - Verifies that a Sudoku grid follows the rules
 
 4. SudokuSolver
    - Solves a Sudoku puzzle using backtracking algorithm
 
 5. SudokuProcessor
    - Coordinates the entire process from image to solution
 
 Dependency graph:
 
 SudokuProcessor
  ├── SudokuGridDetector
  ├── DigitRecognizer
  ├── SudokuVerifier
  └── SudokuSolver
 
 */ 