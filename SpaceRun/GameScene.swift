//
//  GameScene.swift
//  SpaceRun
//
//  Created by Xiong, Tony on 5/1/17.
//  Copyright © 2017 Xiong, Tony. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    // Class properties
    
    
    // Instance properties
    private let SpaceshipNodeName = "ship"
    private let PhotonTorpedoName = "photon"
    private let ObstacleNodeName = "obstacle"
    private let PowerupNodeName = "powerup"
    private let HealthupNodeName = "shiphealth"
    private let HUDNodeName = "hud"
    private let ShieldNodeName = "shield"
    
    
    // Properties to hold sound actions. We will preload our sounds
    // into these properties so there is no delay when they are implemented
    // the first time.
    private let shootSound: SKAction = SKAction.playSoundFileNamed("laserShot.wav", waitForCompletion: false)
    
    private let obstacleExplodeSound: SKAction = SKAction.playSoundFileNamed("darkExplosion.wav", waitForCompletion: false)
    
    private let shipExplodeSound: SKAction = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false)
    
    private let clayTackle: SKAction = SKAction.playSoundFileNamed("claySound.wav", waitForCompletion: true)
    
    private let tom: SKAction = SKAction.playSoundFileNamed("tomBrady.mp3", waitForCompletion: true)
    
    private weak var shipTouch: UITouch?
    private var lastUpdateTime: TimeInterval = 0
    private var lastShotFireTime: TimeInterval = 0
    private let defaultFireRate: Double = 0.5
    private var shipFireRate: Double = 0.5
    private let powerUpDuration: TimeInterval = 5.0
    private var shipHealthRate: Double = 2.0
    
    // We will be using the explosion particle emitters more than once,
    // and we don't want to load them from their .sks files every time.
    // so instead we'll create instance properties and load (cache) them 
    // for quick reuse like we did our sound-related properties.
    private let shipExplodeTemplate: SKEmitterNode = SKEmitterNode.nodeWithFile("shipExplode.sks")!
    private let obstacleExplodeTemplate: SKEmitterNode = SKEmitterNode.nodeWithFile("obstacleExplode.sks")!
    
    
    override init(size: CGSize) {
        super.init(size: size)
        
        setupGame(size: size)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupGame(size: CGSize) {
        
        let ship = SKSpriteNode(imageNamed: "tomBrady")
        
        ship.position = CGPoint(x: size.width/2.0, y: size.height/2.0)
        ship.size = CGSize(width: 50.0, height: 50.0)
        ship.name = SpaceshipNodeName
        
        
        
        run(self.tom)
        
        // Add ship thruster particle to our ship
        if let thruster = SKEmitterNode.nodeWithFile("thruster.sks") {
            
            thruster.position = CGPoint(x: 0.0, y: -25.0)
            
            // Now, add the thruster as a child of our ship so
            // its position is relative to ship's position
            ship.addChild(thruster)
            
        }
        // Create Shield
        let shield = SKSpriteNode(imageNamed: "ring")
        shield.name = ShieldNodeName
        shield.position = CGPoint (x: size.width/2.0, y: size.height/2.0)
        shield.size = CGSize(width: 80.0, height: 80.0)
        
        addChild(shield)
        addChild(ship)
        
        
        // Set up our HUD
        let hudNode = HUDNode()  // instantiate the HUDNode class
        
        hudNode.name = HUDNodeName
        
        // By default, nodes will overlap (stack) according to the order
        // in which they were added to the scene. If we want to change
        // this order, we can use a node's zPosition to do so.
        hudNode.zPosition = 100.0
        
        // Set the position to the node to the center of the screen.
        // All of the child nodes of the HUD will be positioned relative
        // to this parent node's origin point.
        hudNode.position = CGPoint(x: size.width/2.0, y: size.height/2.0)
        
        addChild(hudNode)
        
        
        // Lay out the score and the time label
        hudNode.layoutForScene()
        
        // Start game HUD Stuff
        hudNode.startGame()
        
        // Add our star field parallax effect to the scen by creating
        // and instance of our StarField class and adding it to the scene
        // as a child
        addChild(StarField())
        
    }
    



    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    
        // Called when touches occur
        if let touch = touches.first {
            
            /*
            // Locate the touch point
            let touchPoint = touch.location(in: self)
            
            // We want to move our ship to the touch point
            //
            // To do this though, we need to acquire a reference
            // to our ship node in our Scene Graph node tree.
            //
            if let ship = self.childNode(withName: SpaceshipNodeName) {
                
                // reposition the ship to the touch point
                ship.position = touchPoint
                
            }
            */
            self.shipTouch = touch
            
        }
    
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // If the lastUpdateTime property is zero, this is the first frame
        // rendered for the scene. Reset it to the passed-in current time.
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        
        // Calculate the time change (delta) since the last frame
        let timeDelta = currentTime - lastUpdateTime
        
        // If the touch is still there (since shipTouch is a weak reference,
        // it will automatically be set to nil by the touch-handling system
        // when it releases the touches after they are done), find the ship
        // node in the Scene Graph node tree by its name and update its
        // position property gradually to the point on the screen that
        // was touched.
        //
        // This will happen every frame because we are in update() so the 
        // ship will keep up with wherever the user's  finger moves to on 
        // the screen.
        
        if let shipTouch = self.shipTouch {
            
            /*if let ship = self.childNode(withName: SpaceshipNodeName) {
                
                // Reposition the ship
                ship.position = shipTouch.location(in: self)
                
            }*/
            
            moveShipTowardPoint(touchPoint: shipTouch.location(in: self), timeDelta: timeDelta)
            
            // We Only want photon torpedos to launch from our ship when the
            // user's finger is in contact with the screen and if the difference
            // between the current time and the last time is torpedo was fired
            // is greater than half a second.
            if currentTime - lastShotFireTime > shipFireRate {
                
                shoot() // fire a photon torpedo from our ship
                
                lastShotFireTime = currentTime
            }
            
        }
        
        // We want to release obstacles 1.5% of the time a frame is drawn
        if arc4random_uniform(1000) <= 30 {
            
            //dropAsteriod()
            dropThing()
            
        }
        
        // Check Shield
        checkShield()
        
        
        // Check for any collisions before each frame is rendered
        checkCollisions()
        
        // Update lastUpdateTime to current Time
        lastUpdateTime = currentTime
        
    }
    
    // 
    // Nudge the ship toward the touch point by an approriate distance amount based
    // on elapsed time (timeDelta) since the last frame
    //
    func moveShipTowardPoint(touchPoint: CGPoint, timeDelta: TimeInterval) {
        
        // Points per second the ship should travel
        let shipSpeed = CGFloat(300)
        
        if let ship = self.childNode(withName: SpaceshipNodeName) {
            
            // Using the Pythageorean Theorem, determine the distance
            // between the ship's current location and the point that was
            // passed in (touchPoint).
            let distanceLeftToTravel = sqrt(pow(ship.position.x - touchPoint.x, 2) + pow(ship.position.y - touchPoint.y, 2))
            
            // if the distance left to travel is greater than 4 points,
            // keep moving the ship. Otherwise, stop moving the ship
            // because we may experience "jitter" around the touch point
            // (due to imprecision with floating point numbers) if we
            // get too close.
            if distanceLeftToTravel > 4 {
                
                // Calculate how far we should move the ship during this
                // frame (current run of update()).
                let distanceToMove = CGFloat(timeDelta) * shipSpeed
                
                // Convert the distance remaining back into (x,y) coordinates
                // using the atan2() function to determine the proper angle
                // based on ship's position and the destination
                let angle = atan2(touchPoint.y - ship.position.y, touchPoint.x - ship.position.x)
                
                // Then, using the angle along with sine and cosine trig function,
                // determine the x and y offset values (x-distance and y-distance to move)
                let xOffset = distanceToMove * cos(angle)
                let yOffset = distanceToMove * sin(angle)
                
                // Use the offset to reposition the ship
                ship.position = CGPoint(x: ship.position.x + xOffset, y: ship.position.y + yOffset)
                
                if let shield = self.childNode(withName: ShieldNodeName) {
                    shield.position = ship.position
                }
                
            }
            
        }
        
    }
    
    
    func checkShield() {
        
        if let shield = self.childNode(withName: ShieldNodeName) {
            
            if shipHealthRate == 4 {
                shield.alpha = 1.0
            } else if shipHealthRate == 3 {
                shield.alpha = 0.75
            } else if shipHealthRate == 2 {
                shield.alpha = 0.50
            } else if shipHealthRate == 1 {
                shield.alpha = 0.25
            } else {
                shield.alpha = 0.00
            }
            
        }
        
        
    }
    
    //
    // Fire a photon torpedo from our ship
    //
    func shoot() {
        
        if let ship = self.childNode(withName: SpaceshipNodeName) {
            
            // Create a photon torpedo fire
            let photon = SKSpriteNode(imageNamed: "americanfootball-1")
            
            photon.name = PhotonTorpedoName
            photon.position = ship.position
            
            self.addChild(photon)
            
            // Move the torpedo from its original position (ship.position)
            // past the upper edge of the screen over half a second. 
            // 
            // NOTE: the y-axis in SpriteKit is flipped back to normal.
            //       (0, 0) is the bottom-left corner and scene height
            //       (self.size.height) is the top edge of the screen.
            //
            // SkAction's are actions built in to SpriteKit that we
            // can use to implement animations and grouping, sequencess,
            // and looping...
            let fly = SKAction.moveBy(x: 0, y: self.size.height + photon.size.height, duration: 0.5)
            
            // Run the fly action
            // photon.run(fly)
            
            // Remove the torpedo once it leaves the scene
            let remove = SKAction.removeFromParent()
            
            let fireAndRemove = SKAction.sequence([fly, remove])
            
            photon.run(fireAndRemove)
            
            self.run(self.shootSound)
            
        }
        
        
    }
    
    
    //
    // Choose randomly when to drop a different type of obstacle or power up
    //
    func dropThing() {
        
        let dieRoll = arc4random_uniform(100) // die value between 0 and 99
        
        if dieRoll < 20{
            
            dropHealth()
            
        } else if dieRoll < 30 {
            
            dropWeaponsPowerUp()
            
        } else if dieRoll < 60{
            
            dropEnemyShip()
            
        } else {
            
            dropAsteriod()
        }
        
    }
    
    func dropHealth() {
        
        let sideSize = 20.0
        
        let startX = Double(arc4random_uniform(uint(self.size.width - 60)) + 30)
        
        // Starting y-position shoule be above the top edge of the scene
        let startY = Double(self.size.height) + sideSize
        
        
        // Create our asteroid sprite and set its properties
        let shipHealth = SKSpriteNode(imageNamed: "patLogo")
        
        shipHealth.size = CGSize(width: sideSize, height: sideSize)
        shipHealth.position = CGPoint(x: startX, y: startY)
        shipHealth.name = HealthupNodeName
        
        self.addChild(shipHealth)
        
        let endY = 0.0 - sideSize
        
        let healthPowerUpPath = SKAction.move(to: CGPoint(x: startX, y: endY), duration: 5.0)
        
        let shrink = SKAction.scale(to: 0.5, duration: 5.0)
        
        let fadeOut = SKAction.fadeOut(withDuration: 5.0)
        
        let grouped = SKAction.group([healthPowerUpPath, shrink, fadeOut])
        
        shipHealth.run(SKAction.sequence([grouped, SKAction.removeFromParent()]))
        
        
        
        
    }
    
    
    //
    // Drop a powerUp sprite which spins and moves from top to bottom
    //
    func dropWeaponsPowerUp() {
        
        
        let sideSize = 30.0
        
        // arc4random_uniform() requires a UInt32 parameter value to be passed to it.
        // Determine the starting x-position.
        let startX = Double(arc4random_uniform(uint(self.size.width - 60)) + 30)
        
        // Starting y-position shoule be above the top edge of the scene
        let startY = Double(self.size.height) + sideSize
        
     
        // Create our asteroid sprite and set its properties
        let powerUp = SKSpriteNode(imageNamed: "lombardi")
        
        powerUp.size = CGSize(width: sideSize, height: sideSize)
        powerUp.position = CGPoint(x: startX, y: startY)
        
        powerUp.name = PowerupNodeName
        
        self.addChild(powerUp)
        
        
        // Set up enemy ship movement
        
        let powerUpPath = curveMeisterEnemyPath()
        

        let followPath = SKAction.follow(powerUpPath, asOffset: true, orientToPath: true, duration: 5.0)
        
        powerUp.run(SKAction.sequence([followPath, SKAction.removeFromParent()]))

        
    }
    
    //
    // Drop an asteroid from above the top edge of the screen some percentage of the time
    //
    func dropAsteriod() {
        
        // Define the asteroid's size which will be a random number between 15 and 44 points
        let sideSize = Double(arc4random_uniform(30) + 15)
        
        // Maximum x-value for the scene
        let maxX = Double(self.size.width)
        let quarterX = maxX / 4.0
        
        let randRange = UInt32(maxX + (quarterX * 2))
        
        // arc4random_uniform() requires a UInt32 parameter value to be passed to it.
        // Determine the starting x-position for the asteroid
        let startX = Double(arc4random_uniform(randRange)) - quarterX
        
        // Starting y-position shoule be above the top edge of the scene
        let startY = Double(self.size.height) + sideSize
        
        // Random ending x-position
        let endX = Double(arc4random_uniform(UInt32(maxX)))
        
        let endY = 0.0 - sideSize
        
        // Create our asteroid sprite and set its properties
        let asteroid = SKSpriteNode(imageNamed: "rogergoodell")
        
        asteroid.size = CGSize(width: sideSize, height: sideSize)
        asteroid.position = CGPoint(x: startX, y: startY)
        
        asteroid.name = ObstacleNodeName
        
        self.addChild(asteroid)
        
        // Run some actions
        //
        // Move our asteroid to a randomly generated point over
        // a duration of 3-6 seconds
        
        let move = SKAction.move(to: CGPoint(x: endX, y: endY), duration: Double(arc4random_uniform(4) + 3))
        
        let remove = SKAction.removeFromParent()
        
        let travelAndRemove = SKAction.sequence([move, remove])
        
        // As it is moving, rotate the asteroid by 3 radians (just under 180 degrees)
        // over 1-3 seconds duration.
        let spin = SKAction.rotate(byAngle: 3, duration: Double(arc4random_uniform(3) + 1))
        
        let spinForever = SKAction.repeatForever(spin)
        
        let groupAction = SKAction.group([spinForever, travelAndRemove])
        
        asteroid.run(groupAction)
        
    }
    
    //
    // Drop an enemy ship onto the scene
    func dropEnemyShip() {
        
    
        let sideSize = 40.0
        
        // arc4random_uniform() requires a UInt32 parameter value to be passed to it.
        // Determine the starting x-position for the enemy
        let startX = Double(arc4random_uniform(uint(self.size.width - 40)) + 20)
        
        // Starting y-position shoule be above the top edge of the scene
        let startY = Double(self.size.height) + sideSize
        
        
        // Create our asteroid sprite and set its properties
        let enemy = SKSpriteNode(imageNamed: "claymatthews")
        
        
        enemy.size = CGSize(width: sideSize, height: sideSize)
        enemy.position = CGPoint(x: startX, y: startY)
        
        enemy.name = ObstacleNodeName
        
        self.addChild(enemy)
        
        
        // Set up enemy ship movement
        //
        // We want the enemy ship to follow a curved flight path (Bezier curve)
        // which uses control points to define how the curvature of the path
        // is formed. The following method will create and return that path.

        let shipPath = curveMeisterEnemyPath()
        
        // Add SKActions to make the enemy ship fly
        //
        //asOffset parameter:
        // if set to true, lets us treat the actual point values of the path
        // as offsets from the enemy ship's starting point vs them being treated
        // as absolute positions on the screen if this parameter is set to false.
        //
        // orientToPath parameter:
        // if true, causes the enemy ship to turn and face the direction of the 
        // path automatically
        let followPath = SKAction.follow(shipPath, asOffset: true, orientToPath: false, duration: 7.0)
        
        enemy.run(SKAction.sequence([followPath, SKAction.removeFromParent()]))
        
    }
    
    
    func curveMeisterEnemyPath() -> CGPath {
        
        let yMax = -1.0 * self.size.height
        
        // Bezier path that we are using was produced using the PaintCode app
        // www.paintcodeapp.com
        //
        // Use the UIBezierPath class to build an object that adds points
        // with two control points per point to construce a curve path.
        let bezierPath = UIBezierPath()
        
        
        bezierPath.move(to: CGPoint(x: 0.5, y:-0.5))
        
        bezierPath.addCurve(to: CGPoint(x: -2.5, y: -59.5), controlPoint1: CGPoint(x: 0.5, y: -0.5), controlPoint2: CGPoint(x: 4.55, y: -29.48))
        
        bezierPath.addCurve(to: CGPoint(x: -27.5, y: -154.5), controlPoint1: CGPoint(x:-9.55, y:-89.52), controlPoint2: CGPoint(x:-43.32, y:-115.43))
        
        bezierPath.addCurve(to: CGPoint(x:30.5, y:-243.5), controlPoint1: CGPoint(x:-11.68, y:-193.57), controlPoint2: CGPoint(x:17.28, y:-186.95))
        
        bezierPath.addCurve(to: CGPoint(x:-52.5, y:-379.5), controlPoint1: CGPoint(x:43.72, y:-300.05), controlPoint2: CGPoint(x:-47.71, y: -335.76))
        
        bezierPath.addCurve(to: CGPoint(x:54.5, y:-449.5), controlPoint1: CGPoint(x:-57.29, y:-423.24), controlPoint2: CGPoint(x:-8.14, y:-482.45))
        
        bezierPath.addCurve(to: CGPoint(x:-5.5, y:-348.5), controlPoint1: CGPoint(x:117.14, y:-416.55), controlPoint2: CGPoint(x:52.25, y:-308.62))
        
        bezierPath.addCurve(to: CGPoint(x:10.5,y: -494.5), controlPoint1: CGPoint(x:-63.25, y: -388.38), controlPoint2: CGPoint(x:-14.48, y: -457.43))
        
        bezierPath.addCurve(to: CGPoint(x:0.5, y:-559.5), controlPoint1: CGPoint(x:23.74, y:-514.16), controlPoint2: CGPoint(x:6.93, y:-537.57))
        
        
        bezierPath.addCurve(to: CGPoint(x:-2.5, y: yMax), controlPoint1: CGPoint(x:-5.2, y:yMax), controlPoint2: CGPoint(x: -2.5, y: yMax))
        
        return bezierPath.cgPath
        
    }
    
    //
    // Perform collision detection between various sprites in our game
    //
    func checkCollisions() {
        
        if let ship = self.childNode(withName: SpaceshipNodeName) {
            
            // If the ship bumps into a powerup, remove the powerup from the 
            // scene and reset shipFireRate property to a much smaller value to
            // increase the ship's fire rate.
            enumerateChildNodes(withName: PowerupNodeName) {
                myPowerUp, _ in
                
                if ship.intersects(myPowerUp) {
                    
                    
                    if let hud = self.childNode(withName: self.HUDNodeName) as! HUDNode? {
                        
                        hud.showPowerupTimer(self.powerUpDuration)
                        
                    }
                    
                    myPowerUp.removeFromParent()
                    
                    // Increase the ship's fire rate
                    self.shipFireRate = 0.1
                    
                    // But, we need to power back down after a delay
                    // so we are not unbeatable...
                    let powerDown = SKAction.run {
                        
                        self.shipFireRate = self.defaultFireRate
                        
                    }
                    
                    let wait = SKAction.wait(forDuration: self.powerUpDuration)
                    
                    let waitAndPowerDown = SKAction.sequence([wait, powerDown])
                    
                    //ship.run(waitAndPowerDown)
                    
                    // If we collect another powerup while one is already in
                    // progress, we need to stop the one in progress and start
                    // a new one so we always get the full duration for any powerup
                    // collected.
                    //
                    // Sprite Kit lets us run actions with a key that we can us
                    // to identify and remove the action before it has a chance to run
                    // or finish.
                    //
                    // if no key is found, nothing happens
                    //
                    let powerDownActionKey = "waitAndPowerDown"
                    ship.removeAction(forKey: powerDownActionKey)
                    
                    ship.run(waitAndPowerDown, withKey: powerDownActionKey)
                   
                }
                
            
                
            }
            
            self.enumerateChildNodes(withName: self.HealthupNodeName) {
                myShipHealth, _ in
                
                if ship.intersects(myShipHealth) {
                    
                    myShipHealth.removeFromParent()
                    self.shipHealthRate = 4.0
                    
                    
                
                    if let hud = self.childNode(withName: self.HUDNodeName) as! HUDNode? {
                        
                        hud.showHealth(Int(self.shipHealthRate))
                        
                    }
                    
                }
                
                
            }
            
            
            // The enumerateChildNodes method wil execute a given code block
            // for every node that is an obstale node in our scene. This code
            // will iterate through all of the obstacle nodes in our Scene Graph
            // node tree.
            //
            // enumerateChildNodes will automatically populate the local identifier
            // obstacle with a reference to the next "obstacle" node it found as
            // it enumerates (loops) through the Scene graph node tree
            enumerateChildNodes(withName: ObstacleNodeName) {
                
                obstacle, _ in
                
                // Check for collision with our ship
                if ship.intersects(obstacle) && self.shipHealthRate == 0{
                    
                    
                    
                    // our ship collided with an obstacle
                    //
                    // Set shipTouch property to nil so it will not
                    // be used by our shooting logic in the updata()
                    // method to countinue to track the touch and
                    // shoot photon torpedos. If this doesn't work
                    // torpedos would continue to fire from (0,0) since
                    // the ship is gone.
                    self.shipTouch = nil
                    
                    // Remove the ship and the obstacle form the Scene Graph
                    ship.removeFromParent()
                    obstacle.removeFromParent()
                    
                    self.run(self.shipExplodeSound)
                    
                    let explosion = self.shipExplodeTemplate.copy() as! SKEmitterNode
                    
                    explosion.position = ship.position
                    explosion.dieOutInDuration(0.3)
                    self.addChild(explosion)
                    
                    if let hud = self.childNode(withName: self.HUDNodeName) as! HUDNode? {
                        
                        hud.endGame()
                        
                    }
                    
                    
                } else if ship.intersects(obstacle) && self.shipHealthRate != 0 {
                    
                    obstacle.removeFromParent()
                    
                    self.shipHealthRate -= 1
                    
                    
                    if let hud = self.childNode(withName: self.HUDNodeName) as! HUDNode? {
                        
                        hud.showHealth(Int(self.shipHealthRate))
                        
                    }
                    
                    self.run(self.clayTackle)
                    
                   
                    
                    
                    
                }
                
                // Now, check if the obstacle collided with one of our photon
                // torpedos using an innter loop (enumeration).
                self.enumerateChildNodes(withName: self.PhotonTorpedoName) {
                    myPhoton, stop in
                    
                    if myPhoton.intersects(obstacle) {
                        
                        myPhoton.removeFromParent()
                        obstacle.removeFromParent()
                        
                        self.run(self.obstacleExplodeSound)
                        
                        // Create Explosion
                        
                        // Call copy() on the node in the template property 
                        // because nodes can only be added to a scene once.
                        //
                        // If we try to add a node agian that already exists in a scene,
                        // the game will crash with an error. We must add copies
                        // of particle emitter nodes that we wish to se more htan once
                        // and we will use the emitter node template that is in our
                        // cached property as a template form which to make these copies.
                        let explosion = self.obstacleExplodeTemplate.copy() as! SKEmitterNode
                        
                        explosion.position = obstacle.position
                        explosion.dieOutInDuration(0.1)
                        self.addChild(explosion)
                        
                        // Update our score
                        if let hud = self.childNode(withName: self.HUDNodeName) as! HUDNode? {
                            
                            let score = 10
                            
                            hud.addPoints(score)
                            
                        }
                        
                        // Set stop.pointee to true to end this inner loop
                        //
                        // This is like a break statement in other languages
                        stop.pointee = true
                        
                    }
                }
            
                
            }
            
            
            
            
        }
        
    }
    
    
    
}
