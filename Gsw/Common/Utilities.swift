//
//  Utilities.swift
//  Gsw
//
//  Created by Deron Johnson on 6/14/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Foundation

func randomFloat(_ min: Float, _ max: Float) -> Float
{
    return Float(min + (max - min) * drand48())
}
