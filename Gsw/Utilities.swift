//
//  Utilities.swift
//  Gsw
//
//  Created by Deron Johnson on 6/24/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Foundation
import simd

typealias Point = (Float, Float, Float)

func randomFloat(_ min: Float = 0.0, _ max: Float = 1.0) -> Float
{
    return Float(drand48() * Double(max - min) + Double(min))
}

// Returns a unit vector in a random orientation
func randomUnitVector() -> float3
{
    let randVec = float3(randomFloat(), randomFloat(), randomFloat())
    return normalize(randVec)
 }

func degreesToRadians(_ angle: Float) -> Float
{
    return angle * Float.pi / Float(180.0)
}

extension String
{
    func trim() -> String
    {
        return self.trimmingCharacters(in: NSCharacterSet.whitespaces)
    }

    func substring(from: Int, to: Int) -> String
    {
        // TODO: Swift 4: return self[from...to]
        let rangeStartIndex = self.index(self.startIndex, offsetBy: from)
        let rangeEndPlus1Index = self.index(self.startIndex, offsetBy: to+1)
        return self.substring(with:rangeStartIndex..<rangeEndPlus1Index)
    }
}

// Example Usage: (0...5).clamp(value)
//
extension ClosedRange {
    func clamp(_ value : Bound) -> Bound {
        return value < self.lowerBound ? self.lowerBound
            : value > self.upperBound ? self.upperBound
            : value
    }
}
