//
//  PDBReaderTestMain.swift
//  Gsw
//
//  Created by Deron Johnson on 7/3/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

import Cocoa

class PDBReaderTest
{
    let pdbFileName = "1BNA"
    let pdbFileExt = "pdb"
    
    func execute()
    {
        let filePath = Bundle.main.path(forResource:pdbFileName, ofType:pdbFileExt)
        if filePath == nil { fatalError("Cannot find file in bundle: \(pdbFileName).\(pdbFileExt)") }
        let pdbReader = PDBReader()
        let molSpec = pdbReader.readPDBFile(filePath!)
        print(molSpec)
        
    }
}

class ApplicationDelegate: NSObject, NSApplicationDelegate {
    var _window: NSWindow
    
    init(window: NSWindow) {
        self._window = window
    }
    
    @nonobjc func applicationDidFinishLaunching(notification: NSNotification)
    {
        let pdbReaderTest = PDBReaderTest()
        pdbReaderTest.execute()
    }
}
