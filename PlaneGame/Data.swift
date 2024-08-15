import Foundation

protocol ScoreChange{
    func scoreChange(_ score: Int)
}

class Data{
    
    static let shared = Data()
    var delegate: ScoreChange?
    
    var score = UserDefaults.standard.integer(forKey: "score") {
        didSet{
            delegate?.scoreChange(score)
            UserDefaults.standard.set(score, forKey: "score")
        }
    }
    
    func addCoins(){
        score += 5
    }
    
}
