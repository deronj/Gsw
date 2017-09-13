//
//  MoleculeSpec.swift
//  Gsw
//
//  Created by Deron Johnson on 6/30/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Foundation
import simd

enum ElementType: String
{
    case unknown
    case carbon = "C"
    case hydrogen = "H"
    case oxygen = "O"
    case nitrogen = "N"
    case sulfur = "S"
    case phosphorus = "P"
    case iron = "FE"
    case silicon = "SI"
}

enum ResidueType: String
{
    case unknown
    case deoxyadenine = "DA"
    case deoxycytosine = "DC"
    case deoxyguanine = "DG"
    case deoxythymine = "DT"
    case adenine = "A"
    case cytosine = "C"
    case guanine = "G"
    case uracil = "U"
    case glycine = "GLY"
    case alanine = "ALA"
    case valine = "VAL"
    case leucine = "LEU"
    case isoleucine = "ILE"
    case serine = "SER"
    case cysteine = "CYS"
    case threonine = "THR"
    case methionine = "MET"
    case proline = "PRO"
    case phenylalanine  = "PHE"
    case tyrosine = "TYR"
    case tryptophan = "TRP"
    case histidine = "HIS"
    case lysine = "LYS"
    case arginine = "ARG"
    case asparticacid = "ASP"
    case glutamicacid = "GLU"
    case asparagine = "ASN"
    case glutamine = "GLN"
    case water = "HOH"
}

enum BondType
{
    case singleBond
    case doubleBond
    case tripleBond
}

class MoleculeSpec
{
    public typealias AtomInfo = (element: ElementType, position: float3, structureNum: Int, residueType: ResidueType)
    public typealias BondInfo = (startAtomPos: float3, endAtomPos: float3, bondType: BondType, structureNum: Int, residueType: ResidueType)

    // List of atoms
    // TODO: for now, this is unkeyed
    public var atomInfos = Array<AtomInfo>()

    // List of bonds
    // TODO: for now, this is unkeyed
    public var bondInfos = Array<BondInfo>()
}
