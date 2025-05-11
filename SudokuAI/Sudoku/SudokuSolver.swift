//
//  SudokuSolver.swift
//  SudokuAI
//
//  Created by Claude on 03/06/25.
//

import Foundation

class SudokuSolver {
    
    // Solves a Sudoku puzzle using backtracking algorithm
    // Returns true if a solution was found, false otherwise
    // The grid is modified in-place with the solution
    static func solve(_ grid: inout [[Int]]) -> Bool {
        // Find an empty cell
        guard let (row, col) = findEmptyCell(grid) else {
            // No empty cells means we've completed the puzzle
            return true
        }
        
        // Try placing digits 1-9 in the empty cell
        for num in 1...9 {
            if isValidPlacement(grid, row: row, col: col, num: num) {
                // Place the digit if it's valid
                grid[row][col] = num
                
                // Recursively attempt to solve the rest of the grid
                if solve(&grid) {
                    return true
                }
                
                // If we couldn't solve with this digit, backtrack
                grid[row][col] = 0
            }
        }
        
        // If no digits worked, we need to backtrack
        return false
    }
    
    // Finds the first empty cell (value 0) in the grid
    // Returns the row and column as a tuple, or nil if no empty cells
    private static func findEmptyCell(_ grid: [[Int]]) -> (Int, Int)? {
        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == 0 {
                    return (row, col)
                }
            }
        }
        return nil
    }
    
    // Checks if placing num at grid[row][col] is valid
    private static func isValidPlacement(_ grid: [[Int]], row: Int, col: Int, num: Int) -> Bool {
        // Check row
        for c in 0..<9 {
            if grid[row][c] == num {
                return false
            }
        }
        
        // Check column
        for r in 0..<9 {
            if grid[r][col] == num {
                return false
            }
        }
        
        // Check 3x3 box
        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3
        
        for r in boxRow..<(boxRow + 3) {
            for c in boxCol..<(boxCol + 3) {
                if grid[r][c] == num {
                    return false
                }
            }
        }
        
        // If we pass all checks, the placement is valid
        return true
    }
    
    // Returns a string representation of the grid for debugging
    static func gridToString(_ grid: [[Int]]) -> String {
        var result = ""
        for row in 0..<9 {
            if row % 3 == 0 && row != 0 {
                result += "- - - - - - - - - - -\n"
            }
            
            for col in 0..<9 {
                if col % 3 == 0 && col != 0 {
                    result += "| "
                }
                
                if grid[row][col] == 0 {
                    result += "_ "
                } else {
                    result += "\(grid[row][col]) "
                }
            }
            result += "\n"
        }
        return result
    }
} 