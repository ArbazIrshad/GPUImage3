//
//  HaldLookupFilter.swift
//  GPUImage
//
//  Created by Muhammad Haroon on 03/07/2025.
//

public class HaldFilter: BasicOperation {
    public var intensity: Float = 1.0 { didSet { uniformSettings["intensity"] = intensity } }
    public var lookupImage: PictureInput? {  // TODO: Check for retain cycles in all cases here
        didSet {
            lookupImage?.addTarget(self, atTargetIndex: 1)
            lookupImage?.processImage()
        }
    }

    public init() {
        super.init(fragmentFunctionName: "haldFragment", numberOfInputs: 2)

        ({ intensity = 1.0 })()
    }
}
