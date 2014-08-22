import Foundation

class Gameplay: CCNode, CCPhysicsCollisionDelegate {

  var _physicsNode: CCPhysicsNode? = nil
  var _catapultArm: CCNode? = nil
  var _levelNode: CCNode? = nil
  var _contentNode: CCNode? = nil

  var _pullbackNode: CCNode? = nil
  var _mouseJointNode: CCNode? = nil
  var _mouseJoint: CCPhysicsJoint? = nil

  var _currentPenguin: Penguin? = nil
  var _penguinCatapultJoint: CCPhysicsJoint? = nil

  var _followPenguin: CCAction? = nil

  let MIN_SPEED: CGFloat = 5.0


  // is called when CCB file has completed loading
  func didLoadFromCCB() {
    // nothing shall collide with our invisible nodes
    _mouseJointNode!.physicsBody.collisionMask = []
    _pullbackNode!.physicsBody.collisionMask = []
    // tell this scene to accept touches
    self.userInteractionEnabled = true

    // load a level
    let level: CCScene = CCBReader.loadAsScene("Levels/Level1")
    _levelNode!.addChild(level)

    // visualize physic bodies & joints
    //  _physicsNode.debugDraw = true
    _physicsNode!.collisionDelegate = self
  }

  func retry() {
    // reload this level
    CCDirector.sharedDirector().replaceScene(CCBReader.loadAsScene("Gameplay"))
  }

  func releaseCatapult() {
    if (_mouseJoint != nil) {
      // releases the joint and lets the catpult snap back
      _mouseJoint!.invalidate()
      _mouseJoint = nil

      // releases the joint and lets the penguin fly
      _penguinCatapultJoint!.invalidate()
      _penguinCatapultJoint = nil

      // after snapping rotation is fine
      _currentPenguin!.physicsBody.allowsRotation = true
      _currentPenguin!.launched = true

      let uiPointsBoundingBox = CGRectMake(0, 0, self.boundingBox().size.width,  self.boundingBox().size.height)
      // follow the flying penguin
      _followPenguin = CCActionFollow.actionWithTarget(_currentPenguin, worldBoundary:uiPointsBoundingBox) as CCAction?
      _contentNode!.runAction(_followPenguin)
    }
  }

  func sealRemoved(seal: CCNode) {
    // load particle effect
    let explosion = CCBReader.load("SealExplosion") as CCParticleSystem
    // place the particle effect on the seals position
    explosion.position = seal.position
    // add the particle effect to the same node the seal is on
    seal.parent.addChild(explosion)
    // make the particle effect clean itself up, once it is completed
    explosion.autoRemoveOnFinish = true
  
    // finally, remove the destroyed seal
    seal.removeFromParent()
}

  func nextAttempt() {
    _currentPenguin = nil
    _contentNode!.stopAction(_followPenguin)
    _followPenguin = nil

    let actionMoveTo = CCActionMoveTo.actionWithDuration(1.0, position:CGPoint(x:0, y:0)) as CCAction?
    _contentNode!.runAction(actionMoveTo)
}

  
  override func touchBegan(touch: UITouch, withEvent event: UIEvent) {
    let touchLocation: CGPoint = touch.locationInNode(_contentNode)

    // start catapult dragging when a touch inside of the catapult arm occurs
    if (CGRectContainsPoint(_catapultArm!.boundingBox(), touchLocation)) {
      // move the mouseJointNode to the touch position
      _mouseJointNode!.position = touchLocation

      // setup a spring joint between the mouseJointNode and the catapultArm
      _mouseJoint = CCPhysicsJoint.connectedSpringJointWithBodyA(_mouseJointNode!.physicsBody,
            bodyB: _catapultArm!.physicsBody,
            anchorA: CGPoint(x: 0, y: 0),
            anchorB: CGPoint(x: 34, y: 138),
            restLength:0.0,
            stiffness:3000.0,
            damping:150.0)

      // create a penguin from the ccb-file
      _currentPenguin = CCBReader.load("Penguin") as Penguin?
      // initially position it on the scoop. 34,138 is the position in the node space of the _catapultArm
      let penguinPosition: CGPoint = _catapultArm!.convertToWorldSpace(CGPoint(x:34, y:138));
      // transform the world position to the node space to which the penguin will be added (_physicsNode)
      _currentPenguin!.position = _physicsNode!.convertToNodeSpace(penguinPosition)
      // add it to the physics world
      _physicsNode!.addChild(_currentPenguin)
      // we don't want the penguin to rotate in the scoop
      _currentPenguin!.physicsBody.allowsRotation = false

      // create a joint to keep the penguin fixed to the scoop until the catapult is released
      _penguinCatapultJoint = CCPhysicsJoint.connectedPivotJointWithBodyA(_currentPenguin!.physicsBody,
            bodyB:_catapultArm!.physicsBody,
            anchorA:_currentPenguin!.anchorPointInPoints)
    }
  }

  override func touchMoved(touch: UITouch, withEvent event: UIEvent) {
    // whenever touches move, update the position of the mouseJointNode to the touch position
    let touchLocation: CGPoint = touch.locationInNode(_contentNode)
    _mouseJointNode!.position = touchLocation
}

  override func touchEnded(touch: UITouch, withEvent event: UIEvent) {
    // when touches end, release the catapult
    self.releaseCatapult()
  }

  override func touchCancelled(touch: UITouch, withEvent event: UIEvent) {
    // when touches are cancelled, release the catapult
    self.releaseCatapult()
  }

  func ccPhysicsCollisionPostSolve(pair: CCPhysicsCollisionPair, seal nodeA: CCNode, wildcard nodeB: CCNode) {
    let energy = pair.totalKineticEnergy

    // if energy is large enough, remove the seal
    if (energy > 5000.0) {
        _physicsNode!.space.addPostStepBlock({
          self.sealRemoved(nodeA)
        }, key:nodeA)
    }
  }

  override func update(delta: CCTime) {
    if (_currentPenguin != nil && _currentPenguin!.launched) {
      // if speed is below minimum speed, assume this attempt is over
      if (ccpLength(_currentPenguin!.physicsBody.velocity) < MIN_SPEED) {
        self.nextAttempt()
        return
      }

      // right corner of penguin
      let penguinMaxX = _currentPenguin!.boundingBox().origin.x + _currentPenguin!.boundingBox().size.width;

      // if right corner of penguin leaves is further left, then the left end of the scene -> next attempt
      if (penguinMaxX < self.boundingBox().origin.x) {
        self.nextAttempt()
        return
      }

      // left conrer of penguin
      let penguinMinX = _currentPenguin!.boundingBox().origin.x;

      // if left corner of penguin leaves is further right, then the right end of the scene -> next attempt
      if (penguinMinX > (self.boundingBox().origin.x + self.boundingBox().size.width)) {
        self.nextAttempt()
        return
      }
    }
  }
}
