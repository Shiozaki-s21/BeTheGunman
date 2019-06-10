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

class ViewController: UIViewController, ARSCNViewDelegate {
  
  @IBOutlet weak var hitLabel: UILabel! {
    didSet {
      hitLabel.isHidden = true
    }
  }
  @IBOutlet var sceneView: ARSCNView!
  
  // timer as a sec
  fileprivate var count:Int = 3
  
  lazy var kightNode: SCNNode = {
    // Create a new SCNScene as a kight
    let kight = SCNScene(named: "art.scnassets/kight.scn")!
    
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
    kightNode.position = SCNVector3Make(0, 0, 0)
    return kightNode
  }()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // call count down
    countDown()
    
    // Set the view's delegate
    //    sceneView.delegate = self
    
    sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    sceneView.autoenablesDefaultLighting = true
    sceneView.scene.physicsWorld.contactDelegate = self
    
    // from here. must be divided by another part(game part)
    // add new model
    // Set the scene to the view
    //     sceneView.scene = SCNScene()
    sceneView.scene.rootNode.addChildNode(kightNode)
    
    // til this row
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // set configration
    let configuration = ARWorldTrackingConfiguration()
    
    //Mark:- search horizon
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
    
    if let camera = sceneView.pointOfView {
      node.position = camera.position
      
      let toPositionCamera = SCNVector3Make(0, 0, -3)
      let toPosition = camera.convertPosition(toPositionCamera, to: nil)
      
      let move = SCNAction.move(to: toPosition, duration: 0.5)
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
    
    let timer = Timer.scheduledTimer(timeInterval: 1.0,
                                     target: self,
                                     selector: #selector(self.timerAction(sender:)),
                                     userInfo: nil,
                                     repeats: true)
    timer.fire()
  }
  
  @objc func timerAction(sender:Timer){
    // Mark: - countdown part
    
    // must be showed on display
    // create(put) it as a number model?
    print(count)
    if count == 0 {
      // stop the timer
      sender.invalidate()
    }
    
    count -= 1
  }
}

extension ViewController: SCNPhysicsContactDelegate {
  func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
    let nodeA = contact.nodeA
    let nodeB = contact.nodeB
    
    if (nodeA.name == "kight" && nodeB.name == "ball")
      || (nodeB.name == "kight" && nodeA.name == "ball"){
      
      DispatchQueue.main.async {
        self.hitLabel.text = "HIT!!"
        self.hitLabel.sizeToFit()
        self.hitLabel.isHidden = false
        
        // Vibration
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          self.hitLabel.isHidden = true
        }
      }
    }
  }
}
