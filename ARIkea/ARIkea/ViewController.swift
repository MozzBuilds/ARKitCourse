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
//        sceneView.delegate = self
        registerGestureRecognisers()
    }
    
    func registerGestureRecognisers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
        sceneView.addGestureRecognizer(tapGesture)
        /// Whenever the sceneview is tapped on, this function gets called
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
            
            /// Need to make sure the nodes also aren't positioned in the scene
            /// Go to the scene, click the node, inspect, and if it has any x/y/z positions, set them all to zero. Else the node will be offset by that position
            /// They were 0 by default for me
            
            sceneView.scene.rootNode.addChildNode(node!)
        }
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
