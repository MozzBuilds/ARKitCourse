//
//  ViewController.swift
//  ARFloorIsLava
//
//  Created by Colin Morrison on 29/10/2023.
//

import UIKit
import ARKit
import CoreMotion

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var addButton: UIButton!
    
    let config = ARWorldTrackingConfiguration()
    let motionManager = CMMotionManager()
    var vehicle = SCNPhysicsVehicle()
    var orientation: CGFloat = 0
    var accelerationValues = [UIAccelerationValue(0), UIAccelerationValue(0)]
    
    var touched = 0

    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.debugOptions = [.showWorldOrigin, .showFeaturePoints]
        
        /// To detect horizontal planes
        config.planeDetection = .horizontal
        
        sceneView.session.run(config)
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        setUpAccelerometer()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /// Triggered whenever the user touches the screen of the phone
        guard touches.first != nil else { return } // If there is at least 1 finger touching the screen
        
        touched += touches.count // How many fingers are touching the screen
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        /// Triggered whenever the user releases their tap
        touched = 0
    }
    
    func createConcrete(planeAnchor: ARPlaneAnchor) -> SCNNode {
        
        /// Instead of a fixed width, we want to make the plane size depend on the anchor
        let width = CGFloat(planeAnchor.planeExtent.width)
//        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.planeExtent.height)
//        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        let concreteNode = SCNNode(geometry: plane)
        
        /// This only does one surface
        concreteNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "Concrete")
        
        /// Now adds the diffuser texture to both sides
        concreteNode.geometry?.firstMaterial?.isDoubleSided = true
        
        /// And likewise set the position depending on the anchor
        concreteNode.position = SCNVector3(planeAnchor.center.x,planeAnchor.center.y,-planeAnchor.center.z)
        
        /// Plane appears facing the camera, needs to be horizontal
        concreteNode.eulerAngles = SCNVector3(GLKMathDegreesToRadians(90),0,0)
        
        /// Need to add a physics body, to interact with the car. Forms a solid object
        /// Static means it will be fixed. It can be collided with. But the body is not affected by other forces or physics bodies, including gravity and collisions
        let staticBody = SCNPhysicsBody.static()
        concreteNode.physicsBody = staticBody
        
        return concreteNode
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        
        /// Need the position of the camera to decide where to add it
        guard let pov = sceneView.pointOfView else { return }
        let transform = pov.transform
        
        /// Orientation again determined by the transform, but  need to reverse it
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m32)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let currentPositionOfCamera = orientation + location
        
        /// Add tge cystin scene and car object
        let scene = SCNScene(named: "VehicleScene.scn")!
        let frameNode = scene.rootNode.childNode(withName: "frame", recursively: false)!
        
        /// Declare the wheel nodes
        /// The wheels are rotated 90 degrees to be vertical (WHY?), so we need to add them under a parent node which can be rotated but the wheels are not
        let frontLeft = frameNode.childNode(withName: "frontLeftParent", recursively: false)!
        let frontRight = frameNode.childNode(withName: "frontRightParent", recursively: false)!
        let rearLeft = frameNode.childNode(withName: "rearLeftParent", recursively: false)!
        let rearRight = frameNode.childNode(withName: "rearRightParent", recursively: false)!

        /// Declare the wheels as vehicle wheels
        let v_frontLeftWheel = SCNPhysicsVehicleWheel(node: frontLeft)
        let v_frontRightWheel = SCNPhysicsVehicleWheel(node: frontRight)
        let v_rearLeftWheel = SCNPhysicsVehicleWheel(node: rearLeft)
        let v_rearRightWheel = SCNPhysicsVehicleWheel(node: rearRight)

        frameNode.position = currentPositionOfCamera
        
        /// The box needs physics so it can fall/move. It needs to be affected by gravity and will fall onto the horiontal plane
        /// Want to keep it as a compoint, as we want this box node to have different affects than we do e.g. the wheels
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: frameNode, options: [.keepAsCompound: true]))
        
        /// Mass of the car, in Newtons. Default is 1N which is very light so a small force moves it very fast
        /// Setting to 5N will make it much slower
        body.mass = 5
        frameNode.physicsBody = body
        
        /// Create the vehicle. The wheels should now move and rotate
        vehicle = SCNPhysicsVehicle(chassisBody: frameNode.physicsBody!, wheels: [v_rearLeftWheel, v_rearRightWheel, v_frontLeftWheel, v_frontRightWheel])
        
        // NOTE ABOUT VEHICLES
        /// Green arrow in sceneview represents the direction of travel, powered by the 'engine' of the vehicle. So normally right now, the green arrow is the Y? axis, so it fights gravity and tries to propell the chassis and attached nodes upwards
        ///     This makes sense but green is actually Z.. why is the Z access controling up/down movement?
        /// The whole car then gets inverted, and the wheels/base isn;'t supported by the concrete base anymore and it all falls apart
        /// Need to rotate the frame/chassis 180deg downwards and all the other components need moved
        /// Now the vehicle points and forces downwards, but it vibrates as its trying to push down to the graavity
        
        sceneView.scene.physicsWorld.addBehavior(vehicle)
        sceneView.scene.rootNode.addChildNode(frameNode)
    }
    
    func setUpAccelerometer() {
        
        /// Need to access accelerometer data using a motion manager. and need to check the device has an accelerometer
        /// It measures acceleration from motion
        /// It starts from its normal Y position on the phone length, with 100% of gravity pulling it down
        /// When you rotate your phone 45 degrees, the gravity is spread 50/50 Y and X
        /// For completely horizontal, 100% of the grabitational force is now being applied in the horizontal direction
        if motionManager.isAccelerometerAvailable {
            
            motionManager.accelerometerUpdateInterval = 1/60 /// (triggered 60 times a second)
            
            /// First step is to detect the acceleration applied via gravity
            motionManager.startAccelerometerUpdates(to: .main, withHandler: { data, error in
                if let error {
                    print(error.localizedDescription)
                    return
                } else {
                    self.accelerometerDidChange(acceleration: data!.acceleration)
                }
            })
        }
    }
    
    func accelerometerDidChange(acceleration: CMAcceleration) {
        /// Acceleration contains an x and value which gives the acceleration split on a scale from 0 to 1
        /// To determine which way the phone is facing, we need to use the acceleration data. If we don't, and just set orientation to acceleration.y, then the vehicle behaves differently depending if the phone is held horizontally with the camera on the left, versus if it was on the right
        /// One is negative, one is positive
        
        /// By default, the acceleration applied includes gravity, thiscan be filtered to better represent how the phone is oriented, for a smoother acceleration
        /// This isn't necessary, but it helps with the user interaction.
        accelerationValues[1] = filtered(currentAcceleration: accelerationValues[1], updatedAcceleration: acceleration.y) //Vertical
        accelerationValues[0] = filtered(currentAcceleration: accelerationValues[0], updatedAcceleration: acceleration.x) // Horizontal

        /// If horizontal acceleration dut to gravity is positive, set orientation to the negative of the vertical acceleration
        if  accelerationValues[0] > 0 {
            orientation = -accelerationValues[1]
        } else {
            orientation = accelerationValues[1]
        }
    }
    
    func filtered(currentAcceleration: Double, updatedAcceleration: Double) -> Double {
        /// Takes in two accelerations due to gravity
        
        let kFilteringFactor = 0.5
        return updatedAcceleration*kFilteringFactor + currentAcceleration*(1 - kFilteringFactor)
    }
}

extension ViewController: ARSCNViewDelegate {
    
    /// Device checks for horizontal surfaces
    /// if it dinds one, it adds a plane anchor to the surface. Position, orientation, and size
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        /// Check the anchor found is a plane anchor
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
    
        let lavaNode = createConcrete(planeAnchor: planeAnchor)
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
        let concreteNode = createConcrete(planeAnchor: planeAnchor)
        node.addChildNode(concreteNode)

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
    
    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        /// Called every frame, so 60fps
        
        /// Set the steering angle to depend on the phones orientation (and so, acceleration)
        /// Set the wheels as the wheels positions in the array. The wheels must match the position of the front wheels, which for this example is position 3 and 4, so index 2 and 3
        /// The negative orientation for the steering angle depends on if the car starts facing us , or faces away from us`
        vehicle.setSteeringAngle(-orientation, forWheelAt: 2)
        vehicle.setSteeringAngle(-orientation, forWheelAt: 3)

        /// Aplpy the engine force to the back wheels
        var engineForce: CGFloat = 0 // Newtons
        var brakingForce: CGFloat = 0
        
        switch touched {
        case 1:
            engineForce = 50
            /// The other way to change the speed of the car, besides changing its mass, is to change the engine force. This is likely more useful to do if there's multiple objects with masses that may interact?
        case 2:
            engineForce = -50
        case 3:
            brakingForce = 150
        default:
            engineForce = 0
        }
        
        vehicle.applyEngineForce(engineForce, forWheelAt: 0)
        vehicle.applyEngineForce(engineForce, forWheelAt: 1)
        vehicle.applyBrakingForce(brakingForce, forWheelAt: 0)
        vehicle.applyBrakingForce(brakingForce, forWheelAt: 1)
    }
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}
