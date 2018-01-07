//
//  SimRenderer1.swift
//  Gsw
//
//  Created by Deron Johnson on 1/1/18.
//  Copyright © 2018 Deron Johnson. All rights reserved.
//

// Visualizes the results of my MD simulations.
// Reads the data produced by a sim of a 2D sim box with identical particles
// and plays it back.
//
// The input file contains a "sim trace," which is the output info from a sim run.
// Each line of the input file contains the particle coordinates for a single timestep (frame).
// A line contains the 2D position coordinates separated by a space. Each x and y coordinates are
// float and are separated by a space.

import Metal

class SimRenderer1 : SimpleRenderer
{
    // TODO: for now
    let _simTraceFileName = "/Users/dj/src/rap/md1/md1/md1/md1.out"

    let _simTrace = SimTrace()

    // TODO: calibrate
    let vizBoxSize = float2(10.0, 10.0)

    override func _loadAssets(_ color0PixelFormat: MTLPixelFormat, _ depthStencilPixelFormat: MTLPixelFormat, _ sampleCount: Int) throws
    {
        _initRenderPass(color0PixelFormat)

        _simTrace.read2DFrom(filePath:_simTraceFileName)
        _simTrace.scaleToVizBox(vizBoxSize)

        let numParticles = _simTrace.numParticles

        _perObjectTransforms = PerObjectTransforms(device:device, numTransformableObjects:numParticles)

        // Create a sim obj for each particle
        _objects = Array<Renderable>()
        for particleIndex in 0..<numParticles
        {
            let object = try! SimObject(particleIndex:particleIndex, simTrace:_simTrace, perObjectTransforms:_perObjectTransforms,
                                        material:_redMaterial, device:device)
            _objects!.append(object);
        }

        _renderPass!.perObjectTransforms = _perObjectTransforms

        _renderPass!.add(objects:_objects!)

    }
}



