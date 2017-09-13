//
//  Renderable.swift
//  Gsw
//
//  Created by Deron Johnson on 6/19/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Metal

// An object that can be drawn by a RenderPass. This object consists of multiple subrenderables,
// all of which share the same transform, geometry buffer, and vertex descriptor. But subrenderables
// can have different materials.
//
protocol Renderable
{
    // Must always include the buffer affset
    typealias VertexBufferInfo = (buffer: MTLBuffer, offset: Int)
    
    var label: String? { get set }
    
    var subrenderables: Array<Subrenderable> { get }
    
    // The object must tell the render pass how its vertices are laid out in the geometry buffer
    var vertexDescriptor: MTLVertexDescriptor { get }
    
    // The buffer which contains the geometry of this renderable.
    var vertexBufferInfo: VertexBufferInfo { get }

    // The object-coords-to-world transform for the object
    // This will be nil for a static (unmoving) object
    var transform: TRSTransform? { get }
    
    // Provides an update function which modifies various properties of this renderable over time
    var animator: Animator? { get set }
    
    // TODO: do I stil need this?
    // For now, we assume that the vertex shader options are the same for all subrenderables of a renderable.
    var vertexShaderOptions: VertexShaderOptions { get set }
    
    // Specify the material for all subrenderables
    func setMaterial(_ material: Material)
    
    // Note: Renderable objects are not currently encoded by any render pass. Only subrenderables are encoded.
}
