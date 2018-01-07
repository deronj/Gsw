//
//  RendererFactory.swift
//  Gsw
//
//  Created by Deron Johnson on 5/21/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Metal

class RendererFactory
{
    // For singleton pattern
    public static let sharedRendererFactory = RendererFactory()

    // For singleton pattern
    private init () {}

    func createRenderer(rendererName: String?) -> Renderer
    {
        // SimpleRenderer is the default
        if rendererName == nil
        {
            return SimpleRenderer()
        }
        
        switch (rendererName!)
        {
        case "Simple":
            return SimpleRenderer()
        case "Sim1":
            return SimRenderer1()

        default:
            fatalError("Unsupported renderer: \(rendererName ?? "Unknown Renderer")")
        }
    }
}
