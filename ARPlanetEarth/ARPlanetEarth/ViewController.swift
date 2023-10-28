//
//  ViewController.swift
//  ARPlanetEarth
//
//  Created by Colin Morrison on 28/10/2023.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    
    let config = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.sceneView.debugOptions = [.showWorldOrigin, .showFeaturePoints]
        sceneView.session.run(config)
        sceneView.autoenablesDefaultLighting = true
    }

    override func viewDidAppear(_ animated: Bool) {
        
        let sun = SCNNode(geometry: SCNSphere(radius: 0.35))
        sun.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "Sun")
        sun.position = SCNVector3(0,0,-1)
        sceneView.scene.rootNode.addChildNode(sun)
        
        /// Could add the nodes to the sun as the parent, but they need their own nodes if we want them to have their own rotation independent of the suns
        /// Can then set the parents position relative to the sun manually, so the earth method doesn't need changed
        /// Then want to set the rotation to the parent, so it acts as an orbit. Setting the rotation on the planet will rotate it around its own axis
        addEarthNode()
        addVenusNode()
        
        // MARK: - Adding a sun rotation action
        /// The sun rotates 360 deg around itself
        /// BUT it has child nodes! So these will also rotate 360 degrees, around the sun!
        /// They will however rotate at the same time around the sun. If we want them to rotate at different speeds, we need to create different parent nodes for them to rotate around, and handle their rotation independently, as above
        sun.runAction(rotationAction(time: 8))
    }
    
    private func addEarthNode() {
        
        let parent = SCNNode()
        
        let earth = createPlanet(geometry: SCNSphere(radius: 0.2),
                                 diffuse: UIImage(named: "Earth_Day"),
                                 specular: UIImage(named: "Earth_Specular"),
                                 emission: UIImage(named: "Earth_Clouds"),
                                 normal: UIImage(named: "Earth_Normal"),
                                 position: SCNVector3(1.2, 0, -1))
        
        parent.addChildNode(earth)
        parent.position = SCNVector3(0,0,-1)
        parent.runAction(rotationAction(time: 14))
        sceneView.scene.rootNode.addChildNode(parent)

        /// To add a moon i could just add it to the earth and offset it. It will follow the earths orbit around the sun. BUT the moon will always face the same place on the earth. And currently the same point of the earth faces the sun
        /// I could spin the moon, but it won't change the orbit around the earth
        /// For this I need to spin the earth, and the moon will orbit the spinning earth
        /// The moon will have no spin but can sort that later
        /// This meets the initial goal of the challenge, BUT... it'll do what the earth was doing to the sun. It'll face the same point on the earth all the time
        /// HOWEVER, the sun is the centre, so for earth, i was able to add a new node to base the earths rotation from. If I add a child to earth this won't work. Can I make a moonParent, relative to the position of the earth, but its own node?
            /// THIS DID NOT WORK. The spin and position were good but the position doesn't change. The moonparent's position is set initially and is thereafter unchanged
        /// What if I add the moonParent as a child to earth?
            /// Earth orbits, moonparent position is earth, moonparent then has its own rotation which the moon uses
        
        let earthRotation = SCNAction.rotateBy(x: 0, y: CGFloat(GLKMathDegreesToRadians(360)), z: 0, duration: 6)
        let earthForeverRotation = SCNAction.repeatForever(earthRotation)
        
        earth.runAction(earthForeverRotation)
        
        let moonParent = SCNNode()
        
        let moon = createPlanet(geometry: SCNSphere(radius: 0.05),
                                diffuse: UIImage(named: "Moon"),
                                specular: nil,
                                emission: nil,
                                normal: nil,
                                position: SCNVector3(0, 0, -0.3))  /// Position relative to the edge of the earth

        moonParent.addChildNode(moon)
        moonParent.runAction(rotationAction(time: 2))
        earth.addChildNode(moonParent)
    }
    
    private func addVenusNode() {
        
        let parent = SCNNode()

        let venus = createPlanet(geometry: SCNSphere(radius: 0.1),
                                 diffuse: UIImage(named: "Venus_Surface")!,
                                 specular: nil,
                                 emission: UIImage(named: "Venus_Atmosphere"),
                                 normal: nil,
                                 position: SCNVector3(0.7, 0, -0))
        
        parent.addChildNode(venus)
        parent.position = SCNVector3(0,0,-1)
        parent.runAction(rotationAction(time: 10))
        sceneView.scene.rootNode.addChildNode(parent)
    }
    
    // MARK: - Helper Funcs
    
    private func createPlanet(geometry: SCNGeometry, diffuse: UIImage?, specular: UIImage?, emission: UIImage?, normal: UIImage?, position: SCNVector3) -> SCNNode {
        
        let planet = SCNNode(geometry: geometry)
        
        /// Cover the surface with a texture
        planet.geometry?.firstMaterial?.diffuse.contents = diffuse
        
        /// Light effects, what parts should light reflect on
        planet.geometry?.firstMaterial?.specular.contents = specular
        
        /// Cover layer on top, what to emit. Cloud coverage for example is this image for earth. Emitting something on the surface
        planet.geometry?.firstMaterial?.emission.contents = emission
        
        /// Allows us to show mountains and things
        planet.geometry?.firstMaterial?.normal.contents = normal
        planet.position = position
        
        return planet
    }
    
    func rotationAction(time: TimeInterval) -> SCNAction {
        let rotation = SCNAction.rotateBy(x: 0, y: CGFloat(GLKMathDegreesToRadians(360)), z: 0, duration: time)
        return SCNAction.repeatForever(rotation)
    }
}

