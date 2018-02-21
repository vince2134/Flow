//
//  EditAction.swift
//  Flow
//
//  Created by Kevin Chan on 22/12/2017.
//  Copyright © 2017 MusicG. All rights reserved.
//

import Foundation

class EditAction: Action {
    
    var measures: [Measure]
    var oldNotations: [MusicNotation]
    var newNotations: [MusicNotation]
    var notationIndices: [Int]
    
    init(old oldNotations: [MusicNotation], new newNotations: [MusicNotation]) {
        self.measures = []
        self.oldNotations = oldNotations
        self.newNotations = newNotations
        self.notationIndices = []
    }
    
    func execute() {

        /*for (notation, measure) in zip(oldNotations, measures) {
            measure.deleteInMeasure(notation)
        }*/

        // Delete notes in measures
        for notation in self.oldNotations {
            if let measure = notation.measure {
                if let index = measure.notationObjects.index(of: notation) {
                    self.notationIndices.append(index)
                    print("found index at: \(index)")
                }
                if !self.measures.contains(measure) {
                    self.measures.append(measure)
                }
                measure.deleteInMeasure(notation)
            }
        }

        var measureIndex = 0
        
        for (notation, index) in zip(self.newNotations, self.notationIndices) {
            if !measures[measureIndex].isAddNoteValid(musicNotation: notation.type) {
                measureIndex += 1
            }

            if measureIndex >= measures.count {
                break
            }

            let measure = measures[measureIndex]
            measure.addToMeasure(notation, at: index)
        }

        //self.measures[0].addToMeasure(newNotations[0])

        /*for notation in newNotations {
            if !measures[measureIndex].isAddNoteValid(musicNotation: item.type) {
                measureIndex += 1
                noteIndex = 0
            }

            if measureIndex >= measures.count {
                break
            }


            let measure = measures[measureIndex]
            measure

        }*/
    }
    
    func undo() {
        
    }
    
    func redo() {
        
    }
    
}
