//
//  GameViewControllerOSX.swift
//  foo
//
//  Created by Deron Johnson on 5/20/17.
//  Copyright (c) 2017 Deron Johnson. All rights reserved.
//

import Cocoa
import MetalKit

class GameViewController: NSViewController, MTKViewDelegate
{
    var _view: MTKView?
    var _renderer: Renderer?

    static var eyePositionWC = float3(0, 1.5, -15)
    
    let _camera = ConcreteCameraOSX(eyePositionWC:eyePositionWC)
    
    var _mouseEventCount: UInt = 0
    var _mouseHysteresis: UInt = 3
    var _mouseIsDown: Bool = false

    public override var acceptsFirstResponder: Bool { get { return true } }

    public override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
    }
    
    public required init?(coder: NSCoder)
    {
        super.init(coder:coder)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        _selectRenderer()
        
        _view = self.view as? MTKView
        _view!.delegate = self
        
        _view!.sampleCount = 1
        
        // Setup the render target, choose values based on your app
        _view!.depthStencilPixelFormat = _renderer!.getDesiredDepthStencilPixelFormat()

        do
        {
            _view!.device = try _renderer!.initialize(_view!.colorPixelFormat, _view!.depthStencilPixelFormat, _view!.sampleCount, camera:_camera);
        }
        catch
        {
            fatalError("Cannot initialize renderer, error = \(error)")
        }
        
        // Apparently, this is required on OSX in order for the initial Reshape to be called, so the proj matrix can be calculated
        // (For some strange reason this is required now, but wasn't required earlier)
        _view!.drawableSize = CGSize(width: 500.0, height:500.0)
    }

    override func viewDidAppear()
    {
        super.viewDidAppear()
    
        if self.view.window != nil
        {
            self.view.window!.makeFirstResponder(self)
        }
        else
        {
            fatalError("View has no window")
        }
    
        var trackingOptions = NSTrackingAreaOptions()
        trackingOptions.insert(.mouseMoved)
        trackingOptions.insert(.activeInKeyWindow)
        trackingOptions.insert(.inVisibleRect)
        let trackingArea = NSTrackingArea(rect:NSZeroRect, options:trackingOptions, owner:self, userInfo:nil)
        self.view.addTrackingArea(trackingArea)
    }

    func _selectRenderer()
    {
        var rendererName : String?
        
        /* Usage: Gsw-OSX [<rendererName>] */
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
        
        _renderer = RendererFactory.sharedRendererFactory.createRenderer(rendererName:rendererName)
        _renderer!.setEyePosition(GameViewController.eyePositionWC)
    }
    
    func draw(in view: MTKView)
    {
        // Metal requires you to wrap each frame's rendering in an autorelease pool
        autoreleasepool {
            _renderer!.updateAndDraw(in:view)
        }
    }
    
   func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize)
    {
        _renderer!.reshape(size)
    }
    
    override func keyDown(with event: NSEvent)
    {
        if Int(event.keyCode) == kVK_Escape
        {
            _mouseIsDown = false
        }
        else
        {
            _camera.keyDown(event.keyCode)
        }
    }
    
    override func keyUp(with event: NSEvent)
    {
        if Int(event.keyCode) != kVK_Escape
        {
            _camera.keyUp(event.keyCode)
        }
    }
    
    override func mouseDown(with event: NSEvent)
    {
        _mouseIsDown = true
    }
    
    override func mouseUp(with event: NSEvent)
    {
        _mouseIsDown = false
    }
    
    override func mouseMoved(with event: NSEvent)
    {
        if (_mouseIsDown)
        {
            _handleMouseEvent(event)
        }
    }
    
    override func mouseDragged(with event: NSEvent)
    {
        if _mouseIsDown
        {
            _handleMouseEvent(event)
        }
    }
    
    private func _handleMouseEvent(_ event: NSEvent)
    {
        let delta = CGVector(dx:event.deltaX, dy:event.deltaY);
    
        _mouseEventCount += 1
        if _mouseEventCount > _mouseHysteresis
        {
            _camera.mouseMoved(delta)
        }
    }
}

