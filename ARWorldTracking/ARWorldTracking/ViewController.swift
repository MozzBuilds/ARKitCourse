//
//  ViewController.swift
//  ARWorldTracking
//
//  Created by Colin Morrison on 28/10/2023.
//

import UIKit
import ARKit

class ViewController: UIViewController {
    
    let configuration = ARWorldTrackingConfiguration()
        /// used to track the position/orientation of the device relative to the real world

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        sceneView.session.run(configuration)
        sceneView.autoenablesDefaultLighting = true
    }

    @IBAction func addAction(_ sender: Any) {
        let node = SCNNode() /// A position in space, no shape/size/color
        
        // MARK: - Default Shapes
//        node.geometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.05)
        /// In meters
        /// No radius, take away 0 from the edges, firm perfect box
        /// Do half the dimension for a kind of sphere
        /// Use SCN to identify the object e.g. SCNBox, SCNCapsule
//        node.geometry = SCNCapsule(capRadius: 0.1, height: 0.3)
//        node.geometry = SCNCone(topRadius: 0.2, bottomRadius: 0.3, height: 0.2)
//        node.geometry = SCNCylinder(radius: 0.1, height: 0.2)
//        node.geometry = SCNSphere(radius: 0.1)
//        node.geometry = SCNTube(innerRadius: 0.05, outerRadius: 0.1, height: 0.2)
//        node.geometry = SCNPlane(width: 0.2, height: 0.2)

        // MARK: - Custom Shapes
//        let path = UIBezierPath()
//        path.move(to: CGPoint(x: 0, y: 0))
//        path.addLine(to: CGPoint(x: 0, y: 0.2)) /// First line\
//        path.addLine(to: CGPoint(x: 0.2, y: 0.2)) // Second line is horizontal, so from the original point we get a diagonal ine
//        node.geometry = SCNShape(path: path, extrusionDepth: 0.2) /// 0.2m deep, Z axis
        /// Have a shape that goes from 0,0 to 0,0.2, to 0.2, 0.2, back to 0.0
        /// Can then add another line at point 0.2, 0, if we want to create a square (with extrusion making it a cube)
        /// Each line is relative to the end of the past point, and the new point
        /// NOTE: Look at tools to convert a custom shape/image to Path code! e.g. BezierCode app, loads out there
        
        /// To randomly position it
//        let x = randomNumberGenerator(first: -0.3, second: 0.3)
//        let y = randomNumberGenerator(first: -0.3, second: 0.3)
//        let z = randomNumberGenerator(first: -0.3, second: 0.3)
//        node.position = SCNVector3(x, y, z)
        
        // MARK: - Relative Positioning Section
        node.geometry = SCNPyramid(width: 0.1, height: 0.1, length: 0.1)
        
        node.geometry?.firstMaterial?.specular.contents = UIColor.orange
        /// The color reflected off the surface. We need a source for this to work, on the sceneview
        
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        /// Color spread across entire surface (diffuse)
        
        /// Then need to specify the position of the node, in XYZ coordinates, using 3 dimensional vector
        /// This is relative to the centre position of the node, and centre position of the coordinate
        /// so 0,0,0 for a 1m wide object will means it takes up -0.5 to 0.5
        /// Use negative for behind, positive for in front of the origin
        node.position = SCNVector3(0.2, 0.3, -0.2 )
        
        // MARK: - Cylinder task
        // Add a cylinder 0.3m to the left of pyramid, 0.2m above, 0.3m behind
        let cylinderNode = SCNNode(geometry: SCNCylinder(radius: 0.05, height: 0.1))
        cylinderNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        /// Option 1 would be to calculate what changes we need to do, relative to the root node
        /// Option 2 would be to try add it to the pyramid node, try this first
        cylinderNode.position = SCNVector3(-0.3, 0.2, -0.3)
        node.addChildNode(cylinderNode)
        
        // MARK: - Rotation of nodes
        node.eulerAngles = SCNVector3(GLKMathDegreesToRadians(90), 0, 0)
        /// Look at apple doc examples of shapes to see their default position
        /// For relative rotation, where a node has a child and the parent is rotated, the child is also rotated on the same axis, which can massively change its position
        /// NOTE: To get around this, add the node to root node, THEN add child nodes to it. It will rotate, but its position will be relative to the root node position, 

        self.sceneView.scene.rootNode.addChildNode(node)
        /// Need to position the node inside the scene
        /// Root node is the starting position
        /// Adding child node to root node means the new node's position is relative to the root node
        
        // MARK: - My horrific quick trial for large objects
//        let node1 = SCNNode()
//        node1.geometry = SCNBox(width: 0.5, height: 2, length: 2, chamferRadius: 0.05)
//        node1.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray
//
//        let node2 = SCNNode()
//        node2.geometry = SCNBox(width: 1, height: 2, length: 0.5, chamferRadius: 0.05)
//        node2.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray
//        
//        node1.position = SCNVector3(0, 0, 0)
//        node2.position = SCNVector3(0.5, 0, 2.25)
//        self.sceneView.scene.rootNode.addChildNode(node1)

    }
    
    @IBAction func setNewOrigin(_ sender: Any) {
        restartSession()
    }
    
    func restartSession() {
        sceneView.session.pause()
        /// Stops keeping track of the world position
        ///
        sceneView.scene.rootNode.enumerateChildNodes({ node, _ in
            node.removeFromParentNode()
            /// Removes all notes
        })
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors]) /// Start everything from scratch

        /// Calling this function will reset the scene, remove all boxes, as if nothing happened
    }
    
    func randomNumberGenerator(first: CGFloat, second: CGFloat) -> CGFloat {
        CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(first - second) + min(first, second)
    }
}

