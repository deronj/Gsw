//
//  DisabledLight.swift
//  Gsw
//
//  Created by Deron Johnson on 8/28/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Metal

class DisabledLight: Light
{
    public override func upload(buffer: MTLBuffer, offset: Int)
    {
        lightStruct.type = LightTypeDisabled
        super.upload(buffer:buffer, offset:offset)
    }
}
