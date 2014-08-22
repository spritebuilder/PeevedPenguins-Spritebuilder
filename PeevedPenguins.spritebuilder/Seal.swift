import Foundation

class Seal: CCSprite {
    func didLoadFromCCB() {
        physicsBody.collisionType = "seal"
    }
}