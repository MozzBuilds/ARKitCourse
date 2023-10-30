//
//  ViewController.swift
//  ARFloorIsLava
//
//  Created by Colin Morrison on 29/10/2023.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    let config = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.debugOptions = [.showWorldOrigin, .showFeaturePoints]
        
        /// To detect horizontal planes
        config.planeDetection = .horizontal
        
        sceneView.session.run(config)
        sceneView.delegate = self
    }
    
    func createLava(planeAnchor: ARPlaneAnchor) -> SCNNode {
        
        /// Instead of a fixed width, we want to make the plane size depend on the anchor
        let width = CGFloat(planeAnchor.planeExtent.width)
//        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.planeExtent.height)
//        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        let lavaNode = SCNNode(geometry: plane)
        
        /// This only does one surface
        lavaNode.geometry?.firstMaterial?.diffuse.contents =         UIImage(named: "Lava")
        
        /// Now adds the diffuser texture to both sides
        lavaNode.geometry?.firstMaterial?.isDoubleSided = true
        
        /// And likewise set the position depending on the anchor
        lavaNode.position = SCNVector3(planeAnchor.center.x,planeAnchor.center.y,-planeAnchor.center.z)
        
        /// Plane appears facing the camera, needs to be horizontal
        lavaNode.eulerAngles = SCNVector3(GLKMathDegreesToRadians(90),0,0)
        return lavaNode
    }
}

extension ViewController: ARSCNViewDelegate {
    
    /// Device checks for horizontal surfaces
    /// if it dinds one, it adds a plane anchor to the surface. Position, orientation, and size
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        /// Check the anchor found is a plane anchor
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
    
        let lavaNode = createLava(planeAnchor: planeAnchor)
        node.addChildNode(lavaNode)
        
    }
    
    /// The anchor can be updated however. Example of the floor. A horizontal plane is detected, but if the phone is moved and the floor is much later than originally thought, it's the same plane, but the plane is now updating
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        /// diidUpdate is triggered when any anchor is updated, so again we only want the planeAnchors for this app
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        /// Remove current child node
        node.enumerateChildNodes({ childNode,_ in
            childNode.removeFromParentNode()
        })
        
        /// Make a new node based on the anchor and add it
        let lavaNode = createLava(planeAnchor: planeAnchor)
        node.addChildNode(lavaNode)

    }
    
    /// Adding an anchor and updating works, but.. sometimes two anchors may be made for the same plane, initially. ARKit realises its mistake and combines them, and when doing so, calls didRemove
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        
        
        /// Likewise only want to deal with whatever plane anchors get removed
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        /// Then also want to ensure we remove the lava node associated with that plane anchor
        node.enumerateChildNodes({ childNode,_ in
            childNode.removeFromParentNode()
        })
    }
}
