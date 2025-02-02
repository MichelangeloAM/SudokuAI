//
//  SudokuVerifier.swift
//  SudokuAI
//
//  Created by Michelangelo Amoruso Manzari on 02/02/25.
//

func isSudokuValid(_ grid: [[Int]]) -> Bool {
    for i in 0..<9 {
        // Check rows and columns
        if !isValidSequence(grid[i]) || !isValidSequence(grid.map { $0[i] }) {
            return false
        }
        
        // Check subgrids
        let rowStart = (i / 3) * 3
        let colStart = (i % 3) * 3
        
        var subgrid: [Int] = []
        for x in rowStart..<rowStart+3 {
            for y in colStart..<colStart+3 {
                subgrid.append(grid[x][y])
            }
        }
        
        if !isValidSequence(subgrid) {
            return false
        }
    }
    
    return true
}

func isValidSequence(_ sequence: [Int]) -> Bool {
    guard Set(sequence).count == 9 else { return false } // Ensure all numbers are present without duplicates
    
    for i in 0..<9 {
        if !(1...9 ~= sequence[i]) {
            return false
        }
    }
    
    return true
}
