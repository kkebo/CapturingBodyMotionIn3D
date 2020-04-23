/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample app's main view controller.
*/

import ARKit
import Combine
import RealityKit
import UIKit

class ViewController: UIViewController, ARSessionDelegate {
    @IBOutlet var arView: ARView!

    // The 3D character to display.
    let characterOffset: SIMD3<Float> = [0, 0, 0]  // Offset the character by one meter to the left
    let characterAnchor = AnchorEntity()

    var cancellables = Set<AnyCancellable>()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.session.delegate = self

        // If the iOS device doesn't support body tracking, raise a developer error for
        // this unhandled case.
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }

        // Run a body tracking configration.
        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)

        arView.scene.addAnchor(characterAnchor)

        self.characterAnchor.isEnabled = false

        // Asynchronously load the 3D character.
        Entity.loadBodyTrackedAsync(named: "character/robot")
            .mapError { fatalError("Error: Unable to load model: \($0.localizedDescription)") }
            .sink {
                // Scale the character to human size
                $0.scale = [1.0, 1.0, 1.0]
                self.characterAnchor.addChild($0)
            }
            .store(in: &self.cancellables)
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors.compactMap({ $0 as? ARBodyAnchor }) {
            // Update the position of the character anchor's position.
            let bodyPosition = simd_make_float3(anchor.transform.columns.3)
            characterAnchor.position = bodyPosition + characterOffset
            // Also copy over the rotation of the body anchor, because the skeleton's pose
            // in the world is relative to the body anchor's rotation.
            characterAnchor.orientation = Transform(matrix: anchor.transform).rotation

            if !characterAnchor.isEnabled {
                characterAnchor.isEnabled = true
            }
        }
    }
}
