//
//  StarField.swift
//  SpaceRun
//
//  Created by Xiong, Tony on 5/10/17.
//  Copyright © 2017 Xiong, Tony. All rights reserved.
//

import SpriteKit

class StarField: SKNode {
    
    override init() {
        
        super.init()
        
        initSetup()
        
    }
    
    
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init()
        
        initSetup()
        
    }
    
    
    
    func initSetup() {
        
        // Because we need to call a method on self from inside a code block,
        // we must create a weak reference to self. This is waht we're doing
        // wish the weakSelf constant.
        //
        // Why? The run actio holds a strong reference to the code block and
        // the node (self) holds a strong reference to the action. Now, if the
        // code block held a strong reference to the node (self), then the action,
        // the code block, and the node would form a retain cycle and would
        // never get deallocated => memory leak.
        //
        let update = SKAction.run {
            [weak self] in
            
            if arc4random_uniform(10) < 5 {
                
                if let weakSelf = self {
                    weakSelf.launchStar()
                }
                
            }
            
        }
        
        let delay = SKAction.wait(forDuration: 0.01)
        
        let updateLoop = SKAction.sequence([delay, update])
        
        run(SKAction.repeatForever(updateLoop))
        
    }
    
    func launchStar() {
        
        // Make sure we have a reference to our scene
        if let scene = self.scene {
            
            // Calculate a random starting point at top of screen
            let randX = Double(arc4random_uniform(uint(scene.size.width)))
            
            let maxY = Double(scene.size.height)
            
            let randomStart = CGPoint(x: randX, y: maxY)
            
            let star = SKSpriteNode(imageNamed: "shootingstar")
            
            star.position = randomStart
            
            star.alpha = 0.1 + (CGFloat(arc4random_uniform(10)) / 10.0)
            star.size = CGSize(width: 3.0 - star.alpha, height: 8 - star.alpha)
            
            // stack from dimmest to brightest in the z-axis
            star.zPosition = -100 + star.alpha + 10
            
            // Move the star toward the bottom of the screen using random duration
            // between 0.1 and 1 second removing the star when it passes the bottom edge.
            //
            // The different speeds (based on duration) wiil give us the illusion
            // of a parallax effect.
            
            let destY = 0.0 - scene.size.height - star.size.height
            
            let duration = Double(-star.alpha + 1.8)
            
            addChild(star)
            star.run(SKAction.sequence([SKAction.moveBy(x: 0.0, y: destY, duration: duration), SKAction.removeFromParent()]))
            
        }
        
    }
    
    
}
