//
//  PDBReader.swift
//  Gsw
//
//  Created by Deron Johnson on 6/29/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//
// Derived from Molecules SLSMolecule.m by Brad Larson on 6/26/2008.
// See Molecules_License.txt for details.

import Foundation
import simd

class PDBReader
{
    // The positions of atoms in a residue. Key is atom serial number.
    typealias ResidueSpec = [String: float3]

    private let _molSpec = MoleculeSpec()
    
    private var _currentResidueNum = -1
    private var _currentResidue: ResidueSpec?
    private var _currentResidueType: ResidueType = .unknown
    
    // TODO: For now, only one structure is supported.
    private let _currentStructureNum = 1
    
    // TODO: this is for CONECT. Keyed by atom serial num
    private var _atomCoordinates: [String: float3]? = nil

    // For linking residues 
    private var _previousTerminalAtomPos: float3? = nil
    
    public func readPDBFile(_ filePath: String) -> MoleculeSpec
    {
        let reader = FileLineReader(path:filePath)
        
        if let rdr = reader
        {
            while (true)
            {
                if let line = rdr.nextLine()
                {
                    if (!_parseLine(line))
                    {
                        return _molSpec
                    }
                }
                else
                {
                    fatalError("Premature end of file; END is missing")
                }
            }
        }
        else
        {
            fatalError("Cannot open file \(filePath)")
        }
    }
    
    // Return false when the end has been encountered
    private func _parseLine(_ line: String) -> Bool
    {
        guard line.characters.count < 6 else { fatalError("Line is too short: \(line)") }
        
        let recordName = line.substring(from:0, to:5)
        switch (recordName)
        {
            case "ATOM": _parseAtom(line)
            case "HETATM": _parseHetAtm(line)
            case "TER": _parseTer(line)
            case "END": return false
            
            default:
                // TODO: for now just ignore unrecognized lines
                break;
        }
        
        return true
    }
    
    private func _parseAtom(_ line: String)
    {
        var residueTypeAbbrev = ""

        let residueNum = Int(line.substring(from:22, to:25))
        if residueNum != _currentResidueNum
        {
            // Encountered new residue. Process the current one.
            if let residue = _currentResidue
            {
                _createBondsForResidue(_currentResidueType, residue:residue, structureNum:_currentStructureNum)
            }

            // Start new residue
            _currentResidue = ResidueSpec()
            _currentResidueNum = residueNum!
            residueTypeAbbrev = line.substring(from:17, to:19).trim()
            let maybeResidueType = ResidueType(rawValue:residueTypeAbbrev)
            _currentResidueType = maybeResidueType ?? .unknown
        }
        
        let atomPos = _parseAtomPosition(line)
        let atomNameInResidue = line.substring(from:12, to:15)
        _currentResidue![atomNameInResidue] = atomPos

        // TODO: for CONECT (not yet impl)
        let atomSerialNum = line.substring(from:6, to:10)
        if _atomCoordinates == nil
        {
            _atomCoordinates = [String: float3]()
        }
        _atomCoordinates![atomSerialNum] = atomPos

        var elementType: ElementType
        let elementName = line.substring(from:76, to:77)
        let maybeElementType = ElementType(rawValue:elementName)
        elementType = maybeElementType ?? .unknown

        // Note: Molecules assigns a residue name of "Serine" to all atoms. I am going to use the actual residue abbrev on the Atom line.
        guard residueTypeAbbrev.characters.count > 0 else { fatalError("Unknown residue type") }
        let atomInfo = (element:elementType, position:atomPos, structureNum:_currentStructureNum, residueType:_currentResidueType)
        _molSpec.atomInfos.append(atomInfo)
    }
    
    private func _parseHetAtm(_ line: String)
    {
        // Close any open current residue
        if let residue = _currentResidue
        {
            _createBondsForResidue(_currentResidueType, residue:residue, structureNum:_currentStructureNum)
            _currentResidueType = .unknown
        }

        // There is nothing to bond a new residue to (see _createBondsForResidue)
        _previousTerminalAtomPos = nil
        
        let atomPos = _parseAtomPosition(line)
        
        let atomSerialNum = line.substring(from:6, to:10)
        if _atomCoordinates == nil
        {
            _atomCoordinates = [String: float3]()
        }
        _atomCoordinates![atomSerialNum] = atomPos
        
        var elementType: ElementType
        let elementName = line.substring(from:76, to:77)
        let maybeElementType = ElementType(rawValue:elementName)
        elementType = maybeElementType ?? .unknown

        let hetAtmName = line.substring(from:17, to:19).trim()
        let residueType : ResidueType = (hetAtmName == "HOH") ? .water : .unknown
        let atomInfo = (element:elementType, position:atomPos, structureNum:_currentStructureNum, residueType:residueType)
        _molSpec.atomInfos.append(atomInfo)
    }
    
    private func _parseTer(_ line: String)
    {
        //TODO
    }
    
    private func _parseAtomPosition(_ line: String) -> float3
    {
        var atomPos = float3()
        
        if let x = Float(line.substring(from:30, to:37))
        {
            atomPos.x = x
        }
        else
        {
            fatalError("Invalid position x value")
        }
        if let y = Float(line.substring(from:38, to:45))
        {
            atomPos.y = y
        }
        else
        {
            fatalError("Invalid position y value")
        }
        if let z = Float(line.substring(from:46, to:53))
        {
            atomPos.z = z
        }
        else
        {
            fatalError("Invalid position z value")
        }
        
        // TODO: center of mass, track min/max position
        return atomPos
    }

    private func _createBondInfo(_ residue: ResidueSpec, _ residueType: ResidueType, _ startAtomName: String, _ endAtomName: String,
                                 _ bondType: BondType = .singleBond)
    {
        let bondInfo = (startAtomPos:residue[startAtomName]!, endAtomPos:residue[endAtomName]!, structureNum:_currentStructureNum, bondType:bondType, residueType:residueType)
        _molSpec.bondInfos.append(bondInfo)
    }

    private func _createBondsForResidue(_ residueType: ResidueType, residue: ResidueSpec, structureNum: Int)
    {
        // First do the common atoms for the various residue types
        switch residueType
        {
            // RNA nucleotides
            case .adenine, .cytosine, .guanine, .uracil:
                _createBondInfo(residue, residueType, "C2", "O2")

            // DNA nucleotides
            case .deoxyadenine, .deoxycytosine, .deoxyguanine, .deoxythymine:
                // P -> O3' (Starts from 3' end, so no P in first nucleotide)
                _createBondInfo(residue, residueType, "P", "OP1")
                _createBondInfo(residue, residueType, "P", "OP2")
                _createBondInfo(residue, residueType, "P", "O5'")
                _createBondInfo(residue, residueType, "O5'", "C5'")
                _createBondInfo(residue, residueType, "C5'", "C4'")
                _createBondInfo(residue, residueType, "C4'", "O4'")
                _createBondInfo(residue, residueType, "C4'", "C3'")
                _createBondInfo(residue, residueType, "C3'", "O3'")
                _createBondInfo(residue, residueType, "O4'", "C1'")
                _createBondInfo(residue, residueType, "C3'", "C2'")
                _createBondInfo(residue, residueType, "C2'", "C1'")

                // Link the nucleotides together
                if let atomPos = _previousTerminalAtomPos
                {
                    let bondInfo = (startAtomPos:atomPos, endAtomPos:residue["P"]!, structureNum:_currentStructureNum, bondType:.singleBond, residueType:residueType) as MoleculeSpec.BondInfo
                    _molSpec.bondInfos.append(bondInfo)
                }
                _previousTerminalAtomPos = residue["O3"]
            
            // Amino acids
            case .glycine, .alanine, .valine, .leucine, .isoleucine, .serine, .cysteine, .threonine, .methionine, .proline, .phenylalanine,
                 .tyrosine, .tryptophan, .histidine, .lysine, .arginine, .asparticacid, .glutamicacid, .asparagine, .glutamine:

                // Bonds for backbone atoms
                _createBondInfo(residue, residueType, "N", "CA")
                _createBondInfo(residue, residueType, "CA", "C")
                _createBondInfo(residue, residueType, "C", "O")
            
                // Peptide bond
                if let atomPos = _previousTerminalAtomPos
                {
                    let bondInfo = (startAtomPos:atomPos, endAtomPos:residue["N"]!, structureNum:_currentStructureNum, bondType:.singleBond, residueType:residueType) as MoleculeSpec.BondInfo
                    _molSpec.bondInfos.append(bondInfo)
                }
                _previousTerminalAtomPos = residue["C"]
                    
            default: break
        }
        
        // Now do the residue-specific atoms
        switch (residueType)
        {
            case .adenine, .deoxyadenine:
                _createBondInfo(residue, residueType, "C1", "N9")
                _createBondInfo(residue, residueType, "N9", "C4")
                _createBondInfo(residue, residueType, "C4", "N3")
                _createBondInfo(residue, residueType, "N3", "C2")
                _createBondInfo(residue, residueType, "C2", "N1")
                _createBondInfo(residue, residueType, "N1", "C6")
                _createBondInfo(residue, residueType, "C6", "N6")
                _createBondInfo(residue, residueType, "C6", "C5")
                _createBondInfo(residue, residueType, "C5", "C4")
                _createBondInfo(residue, residueType, "C5", "N7")
                _createBondInfo(residue, residueType, "N7", "C8")
                _createBondInfo(residue, residueType, "C8", "N9")

            case .cytosine, .deoxycytosine:
                _createBondInfo(residue, residueType, "N1", "C2")
                _createBondInfo(residue, residueType, "C2", "O2")
                _createBondInfo(residue, residueType, "C2", "N3")
                _createBondInfo(residue, residueType, "N3", "C4")
                _createBondInfo(residue, residueType, "C4", "N4")
                _createBondInfo(residue, residueType, "C4", "C5")
                _createBondInfo(residue, residueType, "C5", "C6")
                _createBondInfo(residue, residueType, "C6", "N1")

            case .guanine, .deoxyguanine:
                _createBondInfo(residue, residueType, "C1'", "N9")
                _createBondInfo(residue, residueType, "N9", "C4")
                _createBondInfo(residue, residueType, "C4", "N3")
                _createBondInfo(residue, residueType, "N3", "C2")
                _createBondInfo(residue, residueType, "C2", "N2")
                _createBondInfo(residue, residueType, "C2", "N1")
                _createBondInfo(residue, residueType, "N1", "C6")
                _createBondInfo(residue, residueType, "C6", "O6")
                _createBondInfo(residue, residueType, "C6", "C5")
                _createBondInfo(residue, residueType, "C5", "C4")
                _createBondInfo(residue, residueType, "C5", "N7")
                _createBondInfo(residue, residueType, "N7", "C8")
                _createBondInfo(residue, residueType, "C8", "N9")

            case .deoxythymine:
                _createBondInfo(residue, residueType, "C5", "C7")

            case .uracil:
                _createBondInfo(residue, residueType, "C1'", "N1")
                _createBondInfo(residue, residueType, "N1", "C2")
                _createBondInfo(residue, residueType, "C2", "O2")
                _createBondInfo(residue, residueType, "C2", "N3")
                _createBondInfo(residue, residueType, "N3", "C4")
                _createBondInfo(residue, residueType, "C4", "O4")
                _createBondInfo(residue, residueType, "C4", "C5")
                _createBondInfo(residue, residueType, "C5", "C6")
                _createBondInfo(residue, residueType, "C5", "N1")

            case .alanine:
                _createBondInfo(residue, residueType, "CA", "CB")

            case .valine:
                _createBondInfo(residue, residueType, "CA", "CB")
                _createBondInfo(residue, residueType, "CB", "CG1")
                _createBondInfo(residue, residueType, "CB", "CG2")

            case .leucine:
                _createBondInfo(residue, residueType, "CA", "CB")
                _createBondInfo(residue, residueType, "CB", "CG")
                _createBondInfo(residue, residueType, "CG", "CD1")
                _createBondInfo(residue, residueType, "CG", "CD2")

            case .isoleucine:
                _createBondInfo(residue, residueType, "CA", "CB")
                _createBondInfo(residue, residueType, "CB", "CG1")
                _createBondInfo(residue, residueType, "CB", "CG2")
                _createBondInfo(residue, residueType, "CG1", "CD1")

            case .serine:
                _createBondInfo(residue, residueType, "CA", "CB")
                _createBondInfo(residue, residueType, "CB", "OB")

            case .cysteine:
                _createBondInfo(residue, residueType, "CA", "CB")
                _createBondInfo(residue, residueType, "CB", "SG")

            case .threonine:
                _createBondInfo(residue, residueType, "CA", "CB")
                _createBondInfo(residue, residueType, "CB", "OG1")
                _createBondInfo(residue, residueType, "CB", "CG2")

            case .methionine:
                _createBondInfo(residue, residueType, "CA", "CB")
                _createBondInfo(residue, residueType, "CB", "CG")
                _createBondInfo(residue, residueType, "CG", "SD")
                _createBondInfo(residue, residueType, "SD", "CE")

            case .proline:
                _createBondInfo(residue, residueType, "CA", "CB")
                _createBondInfo(residue, residueType, "CB", "CG")
                _createBondInfo(residue, residueType, "CG", "CD")
                _createBondInfo(residue, residueType, "CD", "N")

            case .phenylalanine:
                _createBondInfo(residue, residueType, "CA", "CB")
                _createBondInfo(residue, residueType, "CB", "CG")
                _createBondInfo(residue, residueType, "CG", "CD1")
                _createBondInfo(residue, residueType, "CG", "CD2")
                _createBondInfo(residue, residueType, "CD1", "CE1")
                _createBondInfo(residue, residueType, "CD2", "CE2")
                _createBondInfo(residue, residueType, "CE1", "CZ")
                _createBondInfo(residue, residueType, "CE2", "CZ")

            case .tyrosine:
                _createBondInfo(residue, residueType, "CA", "CB")
                _createBondInfo(residue, residueType, "CB", "CG")
                _createBondInfo(residue, residueType, "CG", "CD1")
                _createBondInfo(residue, residueType, "CG", "CD2")
                _createBondInfo(residue, residueType, "CD1", "CE1")
                _createBondInfo(residue, residueType, "CD2", "CE2")
                _createBondInfo(residue, residueType, "CE1", "CZ")
                _createBondInfo(residue, residueType, "CE2", "CZ")
                _createBondInfo(residue, residueType, "CZ", "OH")

            case .tryptophan:
                _createBondInfo(residue, residueType, "CA", "CB")
                _createBondInfo(residue, residueType, "CB", "CG")
                _createBondInfo(residue, residueType, "CG", "CD1")
                _createBondInfo(residue, residueType, "CG", "CD2")
                _createBondInfo(residue, residueType, "CD1", "NE1")
                _createBondInfo(residue, residueType, "CD2", "CE2")
                _createBondInfo(residue, residueType, "NE1", "CE2")
                _createBondInfo(residue, residueType, "CE2", "CZ2")
                _createBondInfo(residue, residueType, "CZ2", "CH2")
                _createBondInfo(residue, residueType, "CH2", "CZ3")
                _createBondInfo(residue, residueType, "CZ3", "CE3")
                _createBondInfo(residue, residueType, "CE3", "CD2")

            case .histidine:
                _createBondInfo(residue, residueType, "CA", "CB")
                _createBondInfo(residue, residueType, "CB", "CG")
                _createBondInfo(residue, residueType, "CG", "ND1")
                _createBondInfo(residue, residueType, "CG", "CD2")
                _createBondInfo(residue, residueType, "ND1", "CE1")
                _createBondInfo(residue, residueType, "CD2", "NE2")
                _createBondInfo(residue, residueType, "CE1", "NE2")

            case .lysine:
                _createBondInfo(residue, residueType, "CA", "CB")
                _createBondInfo(residue, residueType, "CB", "CG")
                _createBondInfo(residue, residueType, "CG", "CD")
                _createBondInfo(residue, residueType, "CD", "CE")
                _createBondInfo(residue, residueType, "CE", "NZ")

            case .arginine:

                _createBondInfo(residue, residueType, "CA", "CB")
                _createBondInfo(residue, residueType, "CB", "CG")
                _createBondInfo(residue, residueType, "CG", "CD")
                _createBondInfo(residue, residueType, "CD", "NE")
                _createBondInfo(residue, residueType, "NE", "CZ")
                _createBondInfo(residue, residueType, "CZ", "NH1")
                _createBondInfo(residue, residueType, "CZ", "NH2")

            case .asparticacid:
                _createBondInfo(residue, residueType, "CA", "CB")
                _createBondInfo(residue, residueType, "CB", "CG")
                _createBondInfo(residue, residueType, "CG", "OD1")
                _createBondInfo(residue, residueType, "CG", "OD2")

            case .glutamicacid:
                _createBondInfo(residue, residueType, "CA", "CB")
                _createBondInfo(residue, residueType, "CB", "CG")
                _createBondInfo(residue, residueType, "CG", "CD")
                _createBondInfo(residue, residueType, "CD", "OE1")
                _createBondInfo(residue, residueType, "CD", "OE2")

            case .asparagine:
                _createBondInfo(residue, residueType, "CA", "CB")
                _createBondInfo(residue, residueType, "CB", "CG")
                _createBondInfo(residue, residueType, "CG", "OD1")
                _createBondInfo(residue, residueType, "CG", "ND2")
            
            case .glutamine:
                _createBondInfo(residue, residueType, "CA", "CB")
                _createBondInfo(residue, residueType, "CB", "CG")
                _createBondInfo(residue, residueType, "CG", "CD")
                _createBondInfo(residue, residueType, "CD", "OE1")
                _createBondInfo(residue, residueType, "CD", "NE2")

            case .glycine: break
       
            default: break;
        }
    }
}
