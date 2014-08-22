import Foundation

class MainScene: CCNode {
    @objc func play() {
        let gameplayScene: CCScene = CCBReader.loadAsScene("Gameplay")
        CCDirector.sharedDirector().replaceScene(gameplayScene);
    }
}
