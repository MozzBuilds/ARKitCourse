//
//  ViewController.swift
//  ARJellyFish
//
//  Created by Colin Morrison on 28/10/2023.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet var playButton: UIButton!
    @IBOutlet var resetButton: UIButton!
    
    let config = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.debugOptions = [.showWorldOrigin, .showFeaturePoints]
        sceneView.session.run(config)
        
        let tapGesureRec = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tapGesureRec)
    }

    @IBAction func playButtonTapped(_ sender: Any) {
        addNode()
        playButton.isEnabled = false
    }
    

    @IBAction func resetButtonTapped(_ sender: Any) {
        playButton.isEnabled = true
    }
    
    private func addNode() {
        
//        let node = SCNNode(geometry: SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0))
//        
//        node.position = SCNVector3(0, 0, -1)
//        node.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray
//        sceneView.scene.rootNode.addChildNode(node)
        
        let jellyFishScene = SCNScene(named: "Jellyfish")
        
        /// We only want the jellyfish in the scene, as a node
        /// Recursively true will search all children and childrens children etc. Setting to false will just search immediate children, which works for jellyfish
        let jellyFishNode = jellyFishScene?.rootNode.childNode(withName: "JellyFish", recursively: false)
        jellyFishNode?.position = SCNVector3(0,0,-1)
        sceneView.scene.rootNode.addChildNode(jellyFishNode!)
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        /// Need to recognise where the tap is coming from. Is it on a node or just anywhere
        /// If the coordinates tapped correspond with the coordinates there's an object on, it's a match
        let tappedSceneView = sender.view as! SCNView
        let touchCoordinates = sender.location(in: tappedSceneView)
        let hitTest = tappedSceneView.hitTest(touchCoordinates)
        
        /// If there's no match, hitTest array will be empty
        if hitTest.isEmpty {
            
        } else {
            /// If it's a hit, we want to extract info from the hit test
            let results = hitTest.first! /// We know we hit something
            let geometry = results.node.geometry /// Tells us what was touched, and the width/height/length etc, all the geometry properties, no use here other than demo

            /// Also want to prevent the animation being called again, whilst it's already animating. If its animating, animationKeys is not empty
            if results.node.animationKeys.isEmpty {
                animateNode(node: results.node)
            }
        }
    }
    
    func animateNode(node: SCNNode) {
        
        /// Add a spin animation to the jellyfish
        let spin = CABasicAnimation(keyPath: "position")
        
        spin.fromValue = node.presentation.position /// Start point for the animation, set to nodes current position
/*        spin.toValue = SCNVector3(0,0,-2)*/ /// End point, RELATIVE TO THE WORLD ORIGIN
        
        ///Instaed to make it relative to the node, moving 0.2m iin all axis
        spin.toValue = SCNVector3(node.presentation.position.x - 0.2,
                                  node.presentation.position.y - 0.2, 
                                  node.presentation.position.z - 0.2)
        
        spin.duration = 0.1 /// Set the animation time, else it's super quick
        spin.autoreverses = true /// Animate back to the original position after thef rirst animation, else it shaps
        spin.repeatCount = 5 /// Repeat the animation 5 times
        
        node.addAnimation(spin, forKey: "position")
    }
}

