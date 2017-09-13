//
//  ShaderOptions.swift
//  Gsw
//
//  Created by Deron Johnson on 6/19/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

// The list of additional capabilities that a render passes's vertex shader can support,
// such as per-vertex Lambert lighting, skinning, vertex displacement maps, etc. 
// A renderable object can specify that it needs a certain set (array) of capabilities.
//
// Note: Some of these options may not be used together will certain FragmentShaderOptions.
// The conflicts are specified below.
//
struct VertexShaderOptions: OptionSet
{
    let rawValue: Int
    
    public init(rawValue:Int) { self.rawValue = rawValue }
    
    // TODO
}

// The list of additional capabilities that a render passes's fragment shader can support,
// Note: Some of these options may not be used together will certain VertexShaderOptions.
//
struct FragmentShaderOptions: OptionSet
{
    let rawValue: Int
    
    public init(rawValue:Int) { self.rawValue = rawValue }

    // Diffuse color is modulated (aka multiplied) by texel
    public static let diffuseTextured = FragmentShaderOptions(rawValue: 1 << 0)
}
