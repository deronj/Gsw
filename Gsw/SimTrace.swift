//
//  SimTrace.swift
//  Gsw
//
//  Created by Deron Johnson on 1/2/18.
//  Copyright © 2018 Deron Johnson. All rights reserved.
//

import Foundation

// Contains a description of a simple particle simulation run.
// It consists of a number of simulation frames. Each frame specifies
// the positions of each particle.

class SimTrace
{
    struct Particle
    {
        var position: float3

        mutating func scale(scaleFactor: float3)
        {
            position.x *= scaleFactor.x
            position.y *= scaleFactor.y
            position.z *= scaleFactor.z
        }
    }

    // The particle infomation for a single frame
    typealias Frame = Array<Particle>

    public var numParticles = 0

    // Where in Z a 2D trace is placed
    private let _INITIAL_Z : Float = 0.0

    // The information for all frames
    private var _frames : Array<Frame> = []

    private var _minPos: float2
    private var _maxPos: float2

    // Note that this is not the actual size of the simulation box; that size isn't in the trace file.
    // Instead it is based on the min/max coordinates in the file. We therefore call this the 
    // "effective" simbox.
    private var _simBoxSize = float2(0.0, 0.0)

    public init()
    {
        let fmax = Float.greatestFiniteMagnitude
        _minPos = float2(fmax, fmax)
        _maxPos = float2(-fmax, -fmax)
    }

    // Reads the sim output file into the frames array
    //
    public func read2DFrom(filePath: String)
    {
        let file: FileHandle? = FileHandle(forReadingAtPath:filePath)
        guard file != nil else { fatalError("Cannot read file \(filePath)") }

        // Read all the data
        let data = file!.readDataToEndOfFile()

        // Close the file
        file!.closeFile()

        // Convert data to string
        let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue)

        // Parse lines: Line is "x y x y x y ..."
        var lineNum = 0
        str!.enumerateLines { line, _ in
            let coords = line.components(separatedBy:" ");

            // There is a null string at the end. Ignore.
            let numCoords = coords.count - 1

            // Must be an even number of coords
            guard numCoords % 2 == 0 else { fatalError("Error: Odd number of coordinates on line \(lineNum)") }

            let numParticles = coords.count / 2

            // Ensure the number of particles in each sim frame is consistent with the first
            if lineNum == 0
            {
                self.numParticles = numParticles
            }
            else
            {
                guard numParticles == self.numParticles else { fatalError("Inconsistent number of coordinates on line \(lineNum)") }
            }

            var curFrame : Frame = []

            // Add pairs of input coords to the current frame
            var idx = 0
            while idx < numCoords
            {
                let x = Float(coords[idx])
                let y = Float(coords[idx+1])

                // Track the size of the effective simbox
                self._minPos.x = min(self._minPos.x, x!)
                self._minPos.y = min(self._minPos.y, y!)
                self._maxPos.x = max(self._minPos.x, x!)
                self._maxPos.y = max(self._minPos.y, y!)

                let particle = Particle(position: float3(x:x!, y:y!, z:self._INITIAL_Z))
                curFrame.append(particle)
                
                idx += 2
            }
            
            // Add new frame
            self._frames.append(curFrame)

            lineNum += 1
        }

        _simBoxSize.x = _maxPos.x - _minPos.x
        _simBoxSize.y = _maxPos.y - _minPos.y
    }

    // Scales the input coordinates (the sim box) to the specified display size (vizBox)
    public func scaleToVizBox(_ vizBoxSize: float2)
    {
        for frameIdx in 0..<_frames.count
        {
            let scale = float3(vizBoxSize.x / _simBoxSize.x, vizBoxSize.y / _simBoxSize.y, 1.0)

            let frame = _frames[frameIdx]
            for particleIdx in 0..<frame.count
            {
                var particle = frame[particleIdx]
                particle.scale(scaleFactor: scale)
            }
        }
    }

    public func numSimFrames() -> Int
    {
        return _frames.count
    }

    public func getParticlePosition(frameIndex : Int, particleIndex : Int) -> float3
    {
        return _frames[frameIndex][particleIndex].position
    }
}
