import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins 
/// Detects the largest upright rectangle (a “document”), deskews it,
/// and returns a perspective-corrected UIImage. Falls back to original
/// if nothing confident is found.
func autoCropped(_ image: UIImage) -> UIImage {
    guard let cg = image.cgImage else { return image }

    let req = VNDetectRectanglesRequest()
    req.maximumObservations = 1
    req.minimumConfidence   = 0.6
    req.minimumAspectRatio  = 0.3

    let handler = VNImageRequestHandler(cgImage: cg, orientation: .up)
    try? handler.perform([req])

    guard let rect = req.results?.first as? VNRectangleObservation else {
        return image          // nothing found
    }

    // Convert normalised Vision points → pixels
    let ci   = CIImage(cgImage: cg)
    let w    = ci.extent.width, h = ci.extent.height
    let tl   = rect.topLeft     .applying(.init(scaleX: w, y: h))
    let tr   = rect.topRight    .applying(.init(scaleX: w, y: h))
    let bl   = rect.bottomLeft  .applying(.init(scaleX: w, y: h))
    let br   = rect.bottomRight .applying(.init(scaleX: w, y: h))

    // Perspective correction
    let filt = CIFilter.perspectiveCorrection()
    filt.inputImage   = ci
    filt.topLeft      = tl
    filt.topRight     = tr
    filt.bottomLeft   = bl
    filt.bottomRight  = br

    guard
        let outCI = filt.outputImage,
        let outCG = CIContext().createCGImage(outCI, from: outCI.extent)
    else { return image }

    return UIImage(cgImage: outCG, scale: image.scale, orientation: image.imageOrientation)
}
