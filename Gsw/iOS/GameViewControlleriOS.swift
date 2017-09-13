//
//  GameViewController.swift
//  Gsw
//
//  Created by Deron Johnson on 5/21/17.
//  Copyright © 2017 Pixelcraft3D. All rights reserved.
//

import UIKit
import MetalKit

class GameViewController: UIViewController, MTKViewDelegate
{
    var _view: MTKView?
    var _renderer: Renderer?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        _selectRenderer()
        
        _view = self.view as? MTKView
        _view!.delegate = self
        
        // Note: The OSX version of this app uses Multisample
        _view!.sampleCount = 4
        
        // Setup the render target, choose values based on your app
        _view!.depthStencilPixelFormat = _renderer!.getDesiredDepthStencilPixelFormat()
        
        do
        {
            _view!.device = try _renderer!.initialize(_view!.colorPixelFormat, _view!.depthStencilPixelFormat, _view!.sampleCount);
        }
        catch
        {
            fatalError("Cannot initialize renderer, error = \(error)")
        }
    }
    
    func _selectRenderer()
    {
        var rendererName : String?
        
        /* Usage: Gsw-iOS [<rendererName>] */
        if CommandLine.arguments.count > 1
        {
            rendererName = CommandLine.arguments[1]
            print("Selecting renderer \(rendererName!)")
        }
        else
        {
            rendererName = nil
            print("Using default renderer")
        }
        
        _renderer = RendererFactory.createRenderer(rendererName:rendererName)
    }
    
    func draw(in view: MTKView)
    {
        // Metal requires you to wrap each frame's rendering in an autorelease pool
        autoreleasepool {
            _renderer!.updateAndDraw(in:view)
        }
    }
    
    private func _reshape(size: CGSize)
    {
        _renderer!.reshape(size:size)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize)
    {
        _reshape(size:size)
    }
}


