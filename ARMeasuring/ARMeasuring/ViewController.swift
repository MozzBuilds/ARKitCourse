//
//  ViewController.swift
//  ARMeasuring
//
//  Created by Colin Morrison on 03/11/2023.
//

import UIKit
import ARKit

class ViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet var xLabel: UILabel!
    @IBOutlet var yLabel: UILabel!
    @IBOutlet var zLabel: UILabel!
    
    let config = ARWorldTrackingConfiguration()
    var startingPosition: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.debugOptions = [.showWorldOrigin, .showFeaturePoints]
        
        
        sceneView.session.run(config)
        
        sceneView.delegate = self
//        sceneView.showsStatistics = true
        
        let tapGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tapGestureRecogniser)
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        
        guard let sceneView = sender.view as? ARSCNView else { return }
        
        // if sceneview is tapped, and startingposition is already there, remove it, so it stops measuring
        if startingPosition != nil {
            startingPosition?.removeFromParentNode()
            startingPosition = nil
            return
        }
        
        let sphere = SCNNode(geometry: SCNSphere(radius: 0.005))
        sphere.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        
        
        // For position, could do the usual thing where we get the POV of camera
        // An alternative:
        
        guard let currentFrame = sceneView.session.currentFrame else { return }
        let camera = currentFrame.camera // position, orientation, imaging parameters of camera, in a transform matrix
        let transform = camera.transform // 4x4 matrix
        
//        sphere.simdTransform = transform /// node will be positioned exacty where phone is currently positioned
        
        // Want the sphere to be 0.1m away from the device. Need to modify the z position
        
        var translationMatrix = matrix_identity_float4x4
        translationMatrix.columns.3.z = -0.1
        var modifiedMatrix = simd_mul(transform, translationMatrix) // basically creates a copy of the original, but changes column 3.z to be multiplied by -0.1
        sphere.simdTransform = modifiedMatrix
        
        sceneView.scene.rootNode.addChildNode(sphere)
        startingPosition = sphere
    }

    // to help get diagonal distance, pythag
    func distance(x: Float, y: Float, z: Float) -> Float {
        return sqrtf(x*x + y*y + z*z)
    }

}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        // Only proceed if the user tapped on a starting position
        guard let startingPosition else { return }
        
        // get the current location of the cameras POV
        guard let pov = sceneView.pointOfView else { return }
        let transform = pov.transform
        
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let xDistance = location.x - startingPosition.position.x
        let yDistance = location.y - startingPosition.position.y
        let zDistance = location.z - startingPosition.position.z
        
        /// updateAtTime is called in a background thread, so need to point back to main thread
        DispatchQueue.main.async { [self] in
            self.xLabel.text = String(format: "%.2f", xDistance) + "m"
            self.yLabel.text = String(format: "%.2f", yDistance) + "m"
            self.zLabel.text = String(format: "%.2f", zDistance) + "m"
            distanceLabel.text = String(format: "%.2f", distance(x: xDistance, y: yDistance, z: zDistance)) + "m"
        }
    }
}
