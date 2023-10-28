//
//  ViewController.swift
//  ARDrawing
//
//  Created by Colin Morrison on 28/10/2023.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var drawButton: UIButton!
    
    let configuration = ARWorldTrackingConfiguration()

    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.debugOptions = [.showWorldOrigin, .showFeaturePoints]
        sceneView.showsStatistics = true
            /// Shows FPS, performance
        sceneView.session.run(configuration)
        sceneView.delegate = self
    }


    @IBAction func drawButtonTapped(_ sender: Any) {
        
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
        /// To grab the position and orientation of the "normal" of the camera
        guard let pointOfView = sceneView.pointOfView else { return } // Returns a transform matrix
        let transform = pointOfView.transform
        
        /// X position is in the transform matrix column 3 row 1
        /// y is in 3, 2, and z is in 33
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        /// Converting to negative because if you look at these variables at runtime, they are actually all negative.. i.e. if you move up, the y is negative, which doesn't make sense for our calculation
        
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        
        /// Now have the position vector of the phone, and the orientation vector pointing in the directon of the camera
        /// Need to combine these two vectors, to be able to add nodes in front of the camera view
        
        let frontOfCamera = orientation + location
        
        DispatchQueue.main.async { [self] in
            if self.drawButton.isHighlighted {
                let sphereNode = SCNNode(geometry: SCNSphere(radius: 0.02))
                sphereNode.position = frontOfCamera
                sphereNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                sceneView.scene.rootNode.addChildNode(sphereNode)
            } else {
                /// When not drawing, show a pointer so the user knows where drawing will start
                let pointerNode = SCNNode(geometry: SCNSphere(radius: 0.01))
                pointerNode.position = frontOfCamera
                pointerNode.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                pointerNode.name = "Pointer"
                
                /// But make sure we delete the old ones first else we just get another line
                self.sceneView.scene.rootNode.enumerateChildNodes({node,_ in
                    node.name == "Pointer" ? node.removeFromParentNode() : nil
                })
                
                self.sceneView.scene.rootNode.addChildNode(pointerNode)
            }
        }
    }
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}
