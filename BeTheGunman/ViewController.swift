//
//  ViewController.swift
//  BeTheGunman
//
//  Created by SubaruShiozaki on 2019-06-09.
//  Copyright © 2019 Kazuya Takahashi. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import CoreMotion

class ViewController: UIViewController, ARSCNViewDelegate {
  
  @IBOutlet weak var hitLabel: UILabel! {
    didSet {
      hitLabel.isHidden = true
    }
  }
  @IBOutlet var sceneView: ARSCNView!
  
  // count down
  @IBOutlet var countDownLabel: UILabel! {
    didSet {
      countDownLabel.isHidden = true
    }
  }
  
  @IBOutlet var resultLabel: UILabel! {
    didSet {
      resultLabel.isHidden = true
    }
  }
  
  @IBOutlet var returnButton: UIButton! {
    didSet {
      returnButton.isHidden = true
    }
  }
  
  // timer as a sec
  fileprivate var count:Int = 3
  
  var startTime:Date = Date()
  var tappedTime:TimeInterval = TimeInterval()
  
  var conflict:Bool = false
  
  lazy var kightNode: SCNNode = {
    // Create a new SCNScene as a kight
    let kight = SCNScene(named: "art.scnassets/test.dae")!
    
    // Create node for kight
    let kightNode: SCNNode = SCNNode()
    var nodeArray = kight.rootNode.childNodes
    kightNode.name = "kight"
    kightNode.position = SCNVector3(0, 0, 0)
    for childNode in nodeArray {
      kightNode.addChildNode(childNode as SCNNode)
    }
    
    // to add BodyShape
    let shape = SCNPhysicsShape(node: kightNode, options: nil)
    // to add hitting
    // .dynamic -> it's movable after hitting
    // .static -> no hit
    // .kinematic -> it's not movable after hitting
    kightNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: shape)
    kightNode.physicsBody?.isAffectedByGravity = false
    kightNode.position = SCNVector3Make(0, -1, 3.5)
    
    return kightNode
  }()
  
  lazy var bulletNode: SCNNode = {
    let bulletNode: SCNNode = SCNNode()
    let bullet = SCNScene(named: "art.scnassets/bullet.scn")!
    var nodeArray = bullet.rootNode.childNodes
    bulletNode.name = "bullet"
    bulletNode.position = SCNVector3(0, 0, 0)
    for childNode in nodeArray {
      bulletNode.addChildNode(childNode as SCNNode)
    }
    
    let shape = SCNPhysicsShape(node: bulletNode, options: nil)
    bulletNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: shape)
    bulletNode.physicsBody?.isAffectedByGravity = false
    bulletNode.position = SCNVector3Make(0, 0, 0.1)
    return bulletNode
  }()
  
  
  let manager = CMPedometer()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
    countDown()
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // set configration
    let configuration = ARWorldTrackingConfiguration()
    
    //MARK: - search horizon
    //    configuration.planeDetection = .horizontal
    
    // set light information
    configuration.isLightEstimationEnabled = true
    
    sceneView.session.run(configuration)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    // Pause the view's session
    sceneView.session.pause()
  }
  
  // MARK: - ARSCNViewDelegate
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    // get tapped time
    tappedTime = Date().timeIntervalSince(startTime)
    print(tappedTime)
        let ball = SCNSphere(radius: 0.1)
        ball.firstMaterial?.diffuse.contents = UIColor.blue
    
        let node = SCNNode(geometry: ball)
        node.name = "ball"
        node.position = SCNVector3Make(0, 0.1, 0)
    
        // add PhysicsShape
        let shape = SCNPhysicsShape(geometry: ball, options: nil)
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        node.physicsBody?.contactTestBitMask = 1
        node.physicsBody?.isAffectedByGravity = false
    
//    let node = bulletNode
//    node.name = "bullet"
    
    if let camera = sceneView.pointOfView {
      node.position = camera.position
      
      let toPositionCamera = SCNVector3Make(0, 0, -5)
      let toPosition = camera.convertPosition(toPositionCamera, to: nil)
      
      let move = SCNAction.move(to: toPosition, duration: 0.3)
      move.timingMode = .easeOut
      node.runAction(move) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          node.removeFromParentNode()
        }
      }
    }
    sceneView.scene.rootNode.addChildNode(node)
  }
  
  fileprivate func countDown() {
    // show label earch second til 3 sec
    //    countDownLabel.isHidden = false
    
    let timer = Timer.scheduledTimer(timeInterval: 1.0,
                                     target: self,
                                     selector: #selector(self.timerAction(sender:)),
                                     userInfo: nil,
                                     repeats: true)
    timer.fire()
  }
  
  @objc func timerAction(sender:Timer){
    // MARK: - countdown part
    
    // must be showed on display
    // create(put) it as a number model?
    
    print(self.count) // for debug
    
    countDownLabel.isHidden = false
    countDownLabel.text = String(count)
    
    if self.count == 0 {
      // stop the timer
      sender.invalidate()
      self.countDownLabel.isHidden = true
      gamePart()
    }
    self.count -= 1
  }
  
  func gamePart() {
    // start to count time
    startTime = Date()
    
    // put the setting in
    sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    sceneView.autoenablesDefaultLighting = true
    sceneView.scene.physicsWorld.contactDelegate = self
    
    // from here. must be divided by another part(game part)
    // add new model
    // Set the scene to the view
    //     sceneView.scene = SCNScene()
    sceneView.scene.rootNode.addChildNode(kightNode)
  }
  
  func showResult(tappedTime: TimeInterval) {
    
    if tappedTime > 5.0 {
      self.performSelector(onMainThread: #selector(setTextToResultLabel(text:)), with: "Lose", waitUntilDone: true)
    } else {
      self.performSelector(onMainThread: #selector(setTextToResultLabel(text:)), with: "Win", waitUntilDone: true)
    }
    
    self.performSelector(onMainThread: #selector(switchReturnHidden), with: nil, waitUntilDone: true)
    self.performSelector(onMainThread: #selector(switchResultLabel), with: nil, waitUntilDone: true)
  }
  
  @objc func setTextToResultLabel(text: String) {
    self.resultLabel.text = text
  }
  
  @objc func switchResultLabel() {
    self.resultLabel.isHidden = self.resultLabel.isHidden ? false : true
  }
  
  @objc func switchReturnHidden() {
    self.returnButton.isHidden = self.returnButton.isHidden ? false : true
  }
}

extension ViewController: SCNPhysicsContactDelegate {
  func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
    let nodeA = contact.nodeA
    let nodeB = contact.nodeB
    
    if (nodeA.name == "kight" && nodeB.name == "ball")
      || (nodeB.name == "kight" && nodeA.name == "ball"){
      
      DispatchQueue.main.async {
        //        self.hitLabel.text = "HIT!!"
        //        self.hitLabel.sizeToFit()
        //        self.hitLabel.isHidden = false
        
        // Vibration
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        //          self.hitLabel.isHidden = true
        //        }
      }
    } else {
      self.tappedTime = 99.9
    }
    
    showResult(tappedTime: tappedTime)
  }
}
