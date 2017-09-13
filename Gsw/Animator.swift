//
//  Animator.swift
//  Gsw
//
//  Created by Deron Johnson on 7/7/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Foundation

// Provides an update function which modifies its delegateobject in some way over time.
//
protocol Animator
{
    func update(timeDelta: Float)
}
