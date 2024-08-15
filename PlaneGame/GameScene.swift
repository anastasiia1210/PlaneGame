import SpriteKit
import GameplayKit

struct CollisionTypes{
    static let plane: UInt32 = 1
    static let coin: UInt32 = 2
    static let cloud: UInt32 = 3
}

class GameScene: SKScene, SKPhysicsContactDelegate, ScoreChange {
    
    func scoreChange(_ score: Int) {
        labelScore.text = "Score: \(score)"
        labelScore.position = CGPoint(x: frame.width/2 - 10 - labelScore.calculateAccumulatedFrame().size.width, y: frame.height/2.5)
    }
    
    var labelScore = SKLabelNode(fontNamed: "Chalkduster")
    
    override func didMove(to view: SKView) {
        Data.shared.delegate = self
        self.physicsWorld.contactDelegate = self
        self.backgroundColor = UIColor.white
        playMusic()
        createLabelScore()
        createPlane()
        let moveClouds = SKAction.run { [weak self] in self?.createCloud()}
        let moveCoins = SKAction.run { [weak self] in self?.createCoin()}
        let cloudSequence = SKAction.sequence([moveClouds, SKAction.wait(forDuration: 2.0)])
        let coinSequence = SKAction.sequence([moveCoins, SKAction.wait(forDuration: 6.0)])
        let repeatCloudsForever = SKAction.repeatForever(cloudSequence)
        let repeatCoinsForever = SKAction.repeatForever(coinSequence)
        let group = SKAction.group([repeatCloudsForever, repeatCoinsForever])
        self.run(group)
       
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchedNode = self.atPoint(location)
            if touchedNode.name == "restartButton" {
                        restartGame()
                    }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if self.isPaused {
               return
           }
        let plane = self.childNode(withName: "Plane")
        for touch in touches {
            let touchLocation = touch.location(in: self)
            plane?.position.y = touchLocation.y
        }
    }
    
    
    func createPlane(){
        let plane = SKSpriteNode(imageNamed: "plane")
        plane.zRotation = -(.pi / 4)
        plane.position = CGPoint(x: plane.size.width/2-self.size.width/2+10, y: 0)
        plane.name = "Plane"
        plane.xScale = 0.7
        plane.yScale = 0.7
        if let planeTexture = plane.texture {
            plane.physicsBody = SKPhysicsBody(texture: planeTexture, size: plane.size)
        }
        plane.physicsBody?.categoryBitMask = CollisionTypes.plane
        plane.physicsBody?.contactTestBitMask = CollisionTypes.cloud | CollisionTypes.coin
        plane.physicsBody?.isDynamic = false
        plane.physicsBody?.affectedByGravity = false
        addChild(plane)
    }
    
    func createCloud(){
        let cloud = SKSpriteNode(imageNamed: "cloud")
        cloud.physicsBody = SKPhysicsBody(texture: cloud.texture!, size: cloud.size)
        cloud.physicsBody?.categoryBitMask = CollisionTypes.cloud
        cloud.physicsBody?.contactTestBitMask = CollisionTypes.plane
        cloud.physicsBody?.collisionBitMask = CollisionTypes.plane
        cloud.physicsBody?.affectedByGravity = false
        moveElements(cloud)
    }
    
    func createCoin(){
        let coin = SKSpriteNode(imageNamed: "coin")
        coin.xScale = 0.5
        coin.yScale = 0.5
        coin.physicsBody = SKPhysicsBody(circleOfRadius: coin.size.height/4)
        coin.physicsBody?.categoryBitMask = CollisionTypes.coin
        coin.physicsBody?.contactTestBitMask = CollisionTypes.plane
        coin.physicsBody?.collisionBitMask = CollisionTypes.plane
        coin.physicsBody?.affectedByGravity = false
        moveElements(coin)
    }
    
    func moveElements(_ node: SKSpriteNode){
        let screenHeight = UIScreen.main.bounds.height
        let startX = self.frame.width/2 + 70
        let startY = CGFloat.random(in: -screenHeight/2...screenHeight/2)
        node.position = CGPoint(x: startX, y: startY)
        if !isOverlapping(with: node, in: self) {
            addChild(node)
            let moveLeft = SKAction.moveBy(x: -self.frame.width-node.size.width, y: 0, duration: 10)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([moveLeft, remove])
            node.run(sequence)
        }
    }
    
    func isOverlapping(with newCloud: SKSpriteNode, in scene: SKScene) -> Bool {
        for node in scene.children {
            if let existingCloud = node as? SKSpriteNode, existingCloud.frame.intersects(newCloud.frame) {
                return true
            }
        }
        return false
    }

    func didBegin(_ contact: SKPhysicsContact) {
     
        let bodyA = contact.bodyA.node
        let bodyB = contact.bodyB.node
        
        if contact.bodyA.categoryBitMask == CollisionTypes.cloud || contact.bodyB.categoryBitMask == CollisionTypes.cloud {
            gameOver()
        } else if contact.bodyA.categoryBitMask == CollisionTypes.plane && contact.bodyB.categoryBitMask == CollisionTypes.coin {
            playCoinSound()
            Data.shared.addCoins()
            bodyB?.removeFromParent()
        } else if contact.bodyA.categoryBitMask == CollisionTypes.coin && contact.bodyB.categoryBitMask == CollisionTypes.plane {
            playCoinSound()
            Data.shared.addCoins()
            bodyA?.removeFromParent()
        }
    }
    
    func createCloudPhysicsBody(_ cloud: SKSpriteNode) -> SKPhysicsBody{
        let trianglePath = CGMutablePath()
           trianglePath.move(to: CGPoint(x: -cloud.size.width / 2, y: -cloud.size.height / 2))
           trianglePath.addLine(to: CGPoint(x: cloud.size.width / 2, y: -cloud.size.height / 2))
           trianglePath.addLine(to: CGPoint(x: 0, y: cloud.size.height / 2))
           trianglePath.closeSubpath()

           return SKPhysicsBody(polygonFrom: trianglePath)
    }
    
    func createLabelScore(){
        labelScore.text = "Score: \(Data.shared.score)"
        labelScore.fontSize = 30
        labelScore.fontColor = SKColor.black
        labelScore.position = CGPoint(x: frame.width/2 - 10 - labelScore.calculateAccumulatedFrame().size.width, y: frame.height/2.5)
        addChild(labelScore)
    }
    
    func gameOver(){
        self.isPaused = true
        self.physicsWorld.speed = 0
        
        let gameOverLabel = SKLabelNode(fontNamed: "Chalkduster")
        gameOverLabel.text = "Game over"
        gameOverLabel.fontSize = 70
        gameOverLabel.fontColor = SKColor.black
        gameOverLabel.zPosition = 100
        addChild(gameOverLabel)
        
        let playAgain = SKSpriteNode(imageNamed: "playAgain")
        playAgain.xScale = 1.2
        playAgain.yScale = 1.2
        playAgain.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 70)
        playAgain.name = "restartButton"
        addChild(playAgain)
    }
    
    func restartGame(){
        self.removeAllChildren()
        self.isPaused = false
        self.physicsWorld.speed = 1

        let newScene = GameScene(size: self.size)
        newScene.anchorPoint = self.scene?.anchorPoint ?? CGPoint(x: 0, y: 0)
        newScene.scaleMode = self.scaleMode
        let transition = SKTransition.fade(withDuration: 1.0)
        self.view?.presentScene(newScene, transition: transition)
    }
    
    func playCoinSound() {
        let coinSound = SKAction.playSoundFileNamed("coinSound.mp3", waitForCompletion: false)
        self.run(coinSound)
    }
    
    func playMusic(){
        if let musicURL = Bundle.main.url(forResource: "music", withExtension: "mp3") {
                let backgroundMusic = SKAudioNode(url: musicURL)
                backgroundMusic.autoplayLooped = true
                backgroundMusic.run(SKAction.changeVolume(to: 0.1, duration: 0))
                addChild(backgroundMusic)
            }
    }
}
