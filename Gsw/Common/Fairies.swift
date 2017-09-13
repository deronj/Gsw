NOT YET

//
//  Fairies.swift
//  Gsw
//
//  Created by Deron Johnson on 6/11/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Foundation

// A collection of moving fairies. A fairy is a moving light. It represents a point light which
// lights the main pass of the scene. (But fairies do not light other fairies). Each fairy is
// drawn with the same color as its corresponding light.
//
class Fairies
{
    var _number: Int = 0
    var number: Int { get { return _number } }

    let fairyList = Array<Fairy>()
    
    init(_ num: Int)
    {
        _number = num
    }
}

