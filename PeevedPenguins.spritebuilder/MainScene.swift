import Foundation

class MainScene: CCNode {
    func play() {
        let gameplayScene: CCScene = CCBReader.loadAsScene("Gameplay")
        CCDirector.sharedDirector().replaceScene(gameplayScene);
    }
}
