//
//  BufferSet.swift
//  Gsw
//
//  Created by Deron Johnson on 7/5/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Metal

// This Metal renderer allows several frames in-flight at a time. This number is Renderer.MAX_INFLIGHT_FRAMES.
// A BufferSet provides this many buffers. The actual buffer in the set is indexed by a client-provided 
// index which is unique for each in-flight frame (called constantBufferIndex). 
//
// For each MTLBuffer that can differ between frames, the renderer allocates a buffer set and indexes it
// with a frame-specific index.
//
// For debug: If a label is given, the label is extended with the buffer index.
//
class BufferSet
{
    private var _buffers = Array<MTLBuffer>()
    
    // Allocate a buffer set with buffers of length bytes each, and with the given options.
    public init (device: MTLDevice, length: Int, label: String? = nil, options: MTLResourceOptions = .storageModeShared)
    {
        for idx in 0..<Renderer.MAX_INFLIGHT_FRAMES
        {
            let buf = device.makeBuffer(length:length, options:options)
            if let labelStr = label
            {
                buf.label = labelStr + "[\(idx)]"
            }
            _buffers.append(buf)
        }
    }

    subscript(index: Int) -> MTLBuffer
    {
        get {
            return _buffers[index]
        }
    }
}
