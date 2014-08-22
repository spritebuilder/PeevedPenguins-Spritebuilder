import Foundation

class WaitingPenguin: CCSprite {

    func didLoadFromCCB() {
      // generate a random number between 0.0 and 2.0
      let delay = UInt64(Float(Int(arc4random()) % 2000) / 1000.0)
      let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC * delay))
      dispatch_after(delayTime, dispatch_get_main_queue()) {
        self.startBlinkAndJump()
      }
    }

    func startBlinkAndJump() {
      // the animation manager of each node is stored in the 'userObject' property
      // timelines can be referenced and run by name
      self.animationManager.runAnimationsForSequenceNamed("BlinkAndJump")
    }

}
