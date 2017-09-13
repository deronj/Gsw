//
//  BoundingBox.swift
//  Gsw
//
//  Created by Deron Johnson on 6/24/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Foundation

// (x,y,z) is the center. The other params are the dimensions of the box.
class BoundingBox
{
    var x: Float
    var y: Float
    var z: Float
    var width: Float
    var height: Float
    var depth: Float
    
    var minX: Float { get { return x - width/2.0 } }
    var maxX: Float { get { return x + width/2.0 } }
    var minY: Float { get { return y - height/2.0 } }
    var maxY: Float { get { return y + height/2.0 } }
    var minZ: Float { get { return z - depth/2.0 } }
    var maxZ: Float { get { return z + depth/2.0 } }
    
    public init(x theX: Float, y theY: Float, z theZ: Float, width theWidth: Float, height theHeight: Float, depth theDepth: Float)
    {
        x = theX
        y = theY
        z = theZ
        width = theWidth
        height = theHeight
        depth = theDepth
    }
    
    // Return a random point within the box
    public func randomPointWithin() -> Point
    {
        let x = randomFloat(minX, maxX)
        let y = randomFloat(minY, maxY)
        let z = randomFloat(minZ, maxZ)
        return (x, y, z)
    }
}

