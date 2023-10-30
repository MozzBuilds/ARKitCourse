//
//  ViewController.swift
//  ARIkea
//
//  Created by Colin Morrison on 30/10/2023.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var collectionVIew: UICollectionView!
    @IBOutlet var planeDetectedLabel: UILabel!
    
    let config = ARWorldTrackingConfiguration()
    let items = ["cup", "vase", "boxing", "table"]
    
    var selectedItem: String?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        sceneView.debugOptions = [.showWorldOrigin, .showFeaturePoints]
        config.planeDetection = .horizontal
        
        sceneView.session.run(config)
        
        collectionVIew.dataSource = self
        collectionVIew.delegate = self
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        registerGestureRecognisers()
    }
    
    func registerGestureRecognisers() {
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(rotate))
        
        longPress.minimumPressDuration = 0.1 /// How long a press should be before the long press gesture is recognised
        
        sceneView.addGestureRecognizer(tapGesture)
        sceneView.addGestureRecognizer(pinchGesture)
        sceneView.addGestureRecognizer(longPress)
    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        
        /// We know the sender view is the sceneView but need to declare it so
        let sceneView = sender.view as! ARSCNView
        
        /// Get the CGPoint location of the tap
        let tapLocation = sender.location(in: sceneView)
        
        /// Test if the hit at that location, on this scene view, is a horizontal plane
        let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        
        if !hitTest.isEmpty {
            /// Here we have touched a horizontal surface
            addItem(result: hitTest.first!)
        }
    }
    
    @objc func pinch(sender: UIPinchGestureRecognizer) {
        
        let sceneView = sender.view as! ARSCNView
        let pinchLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(pinchLocation)
        
        if !hitTest.isEmpty {
            /// Get the results from the hit test
            let results = hitTest.first
            
            /// Get the node
            let node = results?.node
            
            /// Scale the node size depending on the pinch
            let pinchAction = SCNAction.scale(by: sender.scale, duration: 0)
            node?.runAction(pinchAction)
           
            sender.scale = 1.0
            /// If this is not done, it keeps scaling exponentially from the pinch, non linear scale
            /// A constant rate scale is good and much easier for a user, than an expotential scale. If they do a big pinch, cup shouldn't increase by x10000 in size

            // Watch for the models used. Sometimes it contains child nodes, all of which must be adjusted to allow scaling at the same rate
        }
    }
    
    @objc func rotate(sender: UILongPressGestureRecognizer) {
        
        let sceneView = sender.view as! ARSCNView
        let holdLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(holdLocation)

        if !hitTest.isEmpty {
            
            let result = hitTest.first!
            
            if sender.state == .began {
                /// If I'm currently pressing, start rotating and continue forever
                let action = SCNAction.rotateBy(x: 0,
                                                y: CGFloat(GLKMathDegreesToRadians(360)),
                                                z: 0, duration: 1)
                
                let forever = SCNAction.repeatForever(action)
                result.node.runAction(forever)
            } else if sender.state == .ended {
                /// Finger has released
                /// Stop the animation
                result.node.removeAllActions()
            }
        }
    }
    
    func addItem(result: ARHitTestResult) {
        
        if let selectedItem {

            /// Load the scene of the item we want to place, based on the item the user selected
            /// Name must match the scene name
            let scene = SCNScene(named: "Models.scnassets/\(selectedItem).scn")
            
            /// Now need to extract the base node, in the scene
            /// Name must match the node name, in the scene
            let node = scene?.rootNode.childNode(withName: selectedItem, recursively: false)
            
            
            /// Need to position the item exactly on the horizontal sruface. Need to use the transform matrix from this
            let transform = result.worldTransform
            
            /// This encodes the position of the detected surface in the third column
            let thirdColumn = transform.columns.3
            node?.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
            
            if selectedItem == "table" {
                /// Special case where the table item isn't centered in the scene, so we have centered it manually
                centerPivot(for: node!)
            }
            
            /// Need to make sure the nodes also aren't positioned in the scene
            /// Go to the scene, click the node, inspect, and if it has any x/y/z positions, set them all to zero. Else the node will be offset by that position
            /// They were 0 by default for me
            
            sceneView.scene.rootNode.addChildNode(node!)
        }
    }
    
    /// Nodes aren't always centered in the scene, and this can't be changed in the scene itself
    func centerPivot(for node: SCNNode) {
        let min = node.boundingBox.min
        let max = node.boundingBox.max
        node.pivot = SCNMatrix4MakeTranslation(min.x + (max.x - min.x)/2,
                                               min.y + (max.y - min.y)/2,
                                               min.z + (max.z - min.z)/2)
    }

}

extension ViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        /// How many cells to display
        items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "item", for: indexPath) as! ItemCell
        cell.itemLabel.text = items[indexPath.row]
        return cell
    }
    
}

extension ViewController: UICollectionViewDelegate {
    
    /// When a cell is selected
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath)
        selectedItem = items[indexPath.row]
        cell?.backgroundColor = .green
    }
    
    /// When another cell is clicked on, the original is deselected
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = .systemOrange
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        /// Called when anchor is added to the scene view, tirggered on a background thread
        /// Need to check if its a plane anchor that was added
        guard anchor is ARPlaneAnchor else { return }
        
        DispatchQueue.main.async {
            self.planeDetectedLabel.isHidden = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
                self.planeDetectedLabel.isHidden = true
            })
        }
    }
}
