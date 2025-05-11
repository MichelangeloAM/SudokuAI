//
//  SudokuVerifier.swift
//  SudokuAI
//
//  Created by Michelangelo Amoruso Manzari on 02/02/25.
//

import Foundation

class SudokuVerifier {
    
    // Check if the Sudoku grid is valid
    // This checks if the current state of the grid follows Sudoku rules
    // It allows for empty cells (0s) and checks that no rules are violated
    static func isValidSudoku(_ grid: [[Int]]) -> Bool {
        // Check grid dimensions
        guard grid.count == 9 else { return false }
        for row in grid {
            guard row.count == 9 else { return false }
        }
        
        // Check rows
        for row in 0..<9 {
            if !isValidPartial(grid[row]) {
                return false
            }
        }
        
        // Check columns
        for col in 0..<9 {
            let column = grid.map { $0[col] }
            if !isValidPartial(column) {
                return false
            }
        }
        
        // Check 3x3 boxes
        for boxRow in 0..<3 {
            for boxCol in 0..<3 {
                var box: [Int] = []
                for row in (boxRow * 3)..<(boxRow * 3 + 3) {
                    for col in (boxCol * 3)..<(boxCol * 3 + 3) {
                        box.append(grid[row][col])
                    }
                }
                
                if !isValidPartial(box) {
                    return false
                }
            }
        }
        
        return true
    }
    
    // Check if a sequence is a valid partial Sudoku sequence
    // (no duplicates except for 0s, which represent empty cells)
    private static func isValidPartial(_ sequence: [Int]) -> Bool {
        var seen = Set<Int>()
        
        for num in sequence {
            // Skip empty cells
            if num == 0 {
                continue
            }
            
            // Check if number is in valid range
            if !(1...9).contains(num) {
                return false
            }
            
            // Check for duplicates
            if seen.contains(num) {
                return false
            }
            
            seen.insert(num)
        }
        
        return true
    }
    
    // For more advanced validation, you can check if the puzzle is solvable
    static func isSolvable(_ grid: [[Int]]) -> Bool {
        // First check if the current state is valid
        if !isValidSudoku(grid) {
            return false
        }
        
        // Then try to solve a copy of the grid
        var gridCopy = grid
        return SudokuSolver.solve(&gridCopy)
    }
}
