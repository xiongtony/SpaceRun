//
//  SKEmitterNodeExtension.swift
//  SpaceRun
//
//  Created by Xiong, Tony on 5/10/17.
//  Copyright © 2017 Xiong, Tony. All rights reserved.
//

import SpriteKit

// .sks files are archived in SKEmitterNode instances. Our
// property changes in the Xcode particle editor actually
// changes real properties on this kind of node.
//
// We will need to retrieve a copy of that node by loading 
// it from the app bundle. In order to mimic the API that
// Apple uses for sound actions, we will build a swift extension
// to add a new method to the SKEmitterNode class to unarchive
// our .sks file.
//
// This was called a category in Objective-C, but is called
// an extension in Swift.

// Use a Swift extension to extend the String class to have our
// own defined length property.
extension String {
    var length: Int {
        return self.characters.count
    }
}

extension SKEmitterNode {
    
    class func nodeWithFile(_ fileName: String) -> SKEmitterNode? {
        
        // We will check the file basename and extension. If
        // there is no extension, we will set it to "sks"
        let baseName = (fileName as NSString).deletingPathExtension
        
        // get fileName's extension if it has one
        var fileExtension = (fileName as NSString).pathExtension
        
        if fileExtension.length == 0 {
            fileExtension = "sks"
        }
        
        // We will grab the main bundle of our project and ask
        // for the path to a resource that has the previously
        // calculated baseName and extension.
        if let path = Bundle.main.path(forResource: baseName, ofType: fileExtension) {
            
            // Particle effect in Sprite Kit are archived when
            // they are created so we need to unarchive the effect
            // file (.sks) so it can be treated as an SKEmitterNode
            // object.
            let node = NSKeyedUnarchiver.unarchiveObject(withFile: path) as! SKEmitterNode
            
            return node
            
        }
        
        return nil
        
    }
    
    
    //
    // We want to add explosions for the two collisions between torpedos and obstacles and
    // our ship and obstacles.
    // 
    // We don't wnat the explosion emitters to keep running indefinitely so we will
    // make them die our after a shor duration
    func dieOutInDuration(_ duration: TimeInterval) {
        
        // Define two waiting periods because once we set the birthrate to zero, we
        // will still need to wait before the partivles that have already been birthed
        // die out (lifetime). Otherwise, the particles would vanish from the screen
        // immdiately
        let firstWait = SKAction.wait(forDuration: duration)
        
        // Set the birthrate to zero in order to make the particle effect disappear
        // using an SKAction run code block
        let stop = SKAction.run {
            [weak self] in
            
            if let weakSelf = self {
                weakSelf.particleBirthRate = 0
            }
        }
        
        
        // Set the second wait time
        let secondWait = SKAction.wait(forDuration: TimeInterval(self.particleLifetime))
  
        let remove = SKAction.removeFromParent()
        
        run(SKAction.sequence([firstWait, stop, secondWait, remove]))
    }
    
    
}
