//
//  Converter.swift
//  Flow
//
//  Created by Kevin Chan on 06/01/2018.
//  Copyright © 2018 MusicG. All rights reserved.
//

import Foundation

class Converter {
    
    // MARK: Conversion functions
    static func compositionToMusicXML(_ composition: Composition) -> String {
        let xml = AEXMLDocument()
        
        let scoreElement = xml.addChild(name: "score-partwise", attributes: ["version": "3.1"])
        
        // Part list
        let partListElement = scoreElement.addChild(name: "part-list")
        let scorePartElement = partListElement.addChild(name: "score-part", attributes: ["id": "P1"])
        scorePartElement.addChild(name: "part-name", value: "Music")
        
        // Part
        let partElement = scoreElement.addChild(name: "part", attributes: ["id": "P1"])
        
        // Tempo
        let tempo = composition.tempo
        
        var previousKeySignature = KeySignature.c
        var previousTimeSignature = TimeSignature(beats: 4, beatType: 4 )
        var previousDivisions = 1
        
        // Loop through measures
        for i in 0..<(composition.numMeasures / 2) {
            let measureElement = partElement.addChild(name: "measure", attributes: ["number": "\(i)"])
            
            
            guard composition.staffList[0].measures.count > 0 else {
                fatalError("No measure found.")
            }
            
            let firstMeasure = composition.staffList[0].measures[i]
            
            let divisions = composition.getDivisions(at: i)
            
            let equal = previousKeySignature == firstMeasure.keySignature &&
                        previousTimeSignature == firstMeasure.timeSignature  &&
                        previousDivisions == divisions
            
            if !equal || i == 0 {
                previousKeySignature = firstMeasure.keySignature
                previousTimeSignature = firstMeasure.timeSignature
                previousDivisions = divisions
                
                // Set attributes
                let attributesElement = measureElement.addChild(name: "attributes")
                
                // Set divisions
                attributesElement.addChild(name: "divisions", value: "\(divisions)")
                
                // Key signature
                let keyElement = attributesElement.addChild(name: "key")
                keyElement.addChild(name: "fifths", value: "\(firstMeasure.keySignature.rawValue)")
                
                // Time signature
                let timeSignatureElement = attributesElement.addChild(name: "time")
                timeSignatureElement.addChild(name: "beats", value: "\(firstMeasure.timeSignature.beats)")
                timeSignatureElement.addChild(name: "beat-type", value: "\(firstMeasure.timeSignature.beatType)")
                
                // Number of Staves
                attributesElement.addChild(name: "staves", value: "\(composition.staffList.count)")
                
                if i == 0 {
                    attributesElement.addChild(name: "sound", attributes: ["tempo": "\(Int(tempo))"])
                }
                
                // Set clefs
                for (index, staff) in composition.staffList.enumerated() {
                    guard staff.measures.count > 0 else {
                        fatalError("No measure found.")
                    }
                    
                    let clef = staff.measures[0].clef
                     
                    // Clef
                    let clefElement = attributesElement.addChild(name: "clef", attributes: ["number": "\(index + 1)"])
                    clefElement.addChild(name: "sign", value: clef.rawValue)
                    clefElement.addChild(name: "line", value: "\(clef.getStandardLine())")
                }
            }
            
            for (index, staff) in composition.staffList.enumerated() {
                let measure = staff.measures[i]
                
                // Add notes and/or rests
                for notation in measure.notationObjects {
                    let notationElement = measureElement.addChild(name: "note")
                    
                    // Add necessary elements depending on note or rest
                    if let note = notation as? Note {
                        let pitchElement = notationElement.addChild(name: "pitch")
                        pitchElement.addChild(name: "step", value: note.pitch.step.toString())
                        pitchElement.addChild(name: "octave", value: "\(note.pitch.octave)")
                        
                        if let accidental = note.accidental {
                            notationElement.addChild(name: "accidental", value: accidental.toString())
                        }
                        
                    } else if notation is Rest {
                        notationElement.addChild(name: "rest")
                    }
                    
                    notationElement.addChild(name: "staff", value: "\(index + 1)")
                    
                    // Set duration and type
                    notationElement.addChild(name: "duration", value: "\(notation.type.getDuration(divisions: divisions))")
                    notationElement.addChild(name: "type", value: notation.type.toString())
                }
            }
        }
        
        // Get string format of xml
        var xmlString = xml.xml
        
        // Add MusicXML Declaration
        let doctype =
        """
        
        <!DOCTYPE score-partwise PUBLIC
            "-//Recordare//DTD MusicXML 3.1 Partwise//EN"
            "http://www.musicxml.org/dtds/partwise.dtd">
        """
        var index = xmlString.index(of: ">")!
        index = xmlString.index(index, offsetBy: 1, limitedBy: xmlString.endIndex)!
        xmlString.insert(contentsOf: doctype, at: index)
        
        print(xmlString)
        
        return xmlString
    }
    
    static func musicXMLtoComposition(_ xml: String) -> Composition {
        let composition = Composition()
        
        // Perform conversion here
        do {
            let xml = try AEXMLDocument(xml: xml)
            
            let measureElements = xml.root["part"].children
            
            let gStaff = Staff()
            let fStaff = Staff()
            
            var previousKeySignature = KeySignature.c
            var previousTimeSignature = TimeSignature(beats: 4, beatType: 4 )
            var clefs = [Clef]()
            
            for measureElement in measureElements {
                if let keyInt = Int(measureElement["attributes"]["key"]["fifths"].string) {
                    if let keySignature = KeySignature(rawValue: keyInt) {
                        previousKeySignature = keySignature
                    }
                }
                
                if let beats = Int(measureElement["attributes"]["time"]["beats"].string),
                    let beatType = Int(measureElement["attributes"]["time"]["beat-type"].string) {
                    previousTimeSignature = TimeSignature(beats: beats, beatType: beatType)
                }
                
                if let tempoString = measureElement["attributes"]["sound"].attributes["tempo"] {
                    if let tempo = Double(tempoString) {
                        composition.tempo = tempo
                    }
                }
                
                // Get attributes
                /*let keySignature = KeySignature(rawValue: Int(measureElement["attributes"]["key"]["fifths"].string)!)
                let timeSignature = TimeSignature(beats: Int(measureElement["attributes"]["time"]["beats"].string)!,
                                                  beatType: Int(measureElement["attributes"]["time"]["beat-type"].string)!)
                let clef = Clef(rawValue: measureElement["attributes"]["clef"]["sign"].string)*/
                
                var measures = [Measure]()
                
                if let clefXMLs = measureElement["attributes"]["clef"].all {
                    clefs.removeAll()
                    for clefXML in clefXMLs {
                        let clef = Clef(rawValue: clefXML["sign"].string)!
                        clefs.append(clef)
                    }
                }
                
                for clef in clefs {
                    let measure = Measure(keySignature: previousKeySignature,
                                          timeSignature: previousTimeSignature,
                                          clef: clef, loading: true)
                    measures.append(measure)
                }
                
                /*let measure = Measure(keySignature: keySignature!,
                                      timeSignature: timeSignature,
                                      clef: clef!)*/
                
                
                
                //                print(measure.keySignature.toString())
                //                print("beats: \(measure.timeSignature.beats)")
                //                print(measure.clef.rawValue)
                
                // Get notes and/or rests
                //var measureIndex = 0
                if let notationElements = measureElement["note"].all {
                    for notationElement in notationElements {
                        let type = RestNoteType.convert(notationElement["type"].string)
                        
                        let staffNum = Int(notationElement["staff"].string)! - 1
                        let measure = measures[staffNum]
                        
                        if let step = notationElement["pitch"]["step"].value {
                            let pitch = Pitch(step: Step.convert(step),
                                              octave: Int(notationElement["pitch"]["octave"].string)!)
                            
                            if let accidentalString = notationElement["accidental"].value {
                                let accidental = Accidental.convert(accidentalString)
                                let note = Note(pitch: pitch, type: type, accidental: accidental)
                                measure.addToMeasure(note)
                            } else {
                                let note = Note(pitch: pitch, type: type)
                                measure.addToMeasure(note)
                            }

                        } else {
                            let rest = Rest(type: type)
                            
                            /*if !measures[measureIndex].isAddNoteValid(musicNotation: rest.type) {
                                measureIndex += 1
                            }*/
                            
                            measure.addToMeasure(rest)
                        }
                    }
                }
                
                for measure in measures {
                    if measure.clef == .G {
                        gStaff.addMeasure(measure)
                    } else if measure.clef == .F {
                        fStaff.addMeasure(measure)
                    }
                    
                    /*measure.updateKeySignature()
                    measure.updateGroups()*/
                }
            }

            composition.addStaff(gStaff)
            composition.addStaff(fStaff)
            
        } catch {
            print("\(error)")
        }
        
        return composition
    }
}
