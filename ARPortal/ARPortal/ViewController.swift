//
//  ViewController.swift
//  ARPortal
//
//  Created by Colin Morrison on 03/11/2023.
//

import UIKit
import ARKit

class ViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var planeDetectedLabel: UILabel!
    
    let config = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        planeDetectedLabel.isHidden = true

        sceneView.debugOptions = [.showWorldOrigin, .showFeaturePoints]
        config.planeDetection = .horizontal
        
        sceneView.delegate = self
        sceneView.session.run(config)
    }
    
    


}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        /// If anchor is a plane anchor, is a horizontal surface, unhide the lanel
        guard anchor is ARPlaneAnchor else { return }
        
        DispatchQueue.main.async {
            self.planeDetectedLabel.isHidden = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
            self.planeDetectedLabel.isHidden = true
        })
        
    }
}
