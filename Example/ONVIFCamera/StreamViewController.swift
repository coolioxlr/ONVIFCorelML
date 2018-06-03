import UIKit
import AVKit
import Vision
/**
 This controller plays the live stream through VLC of the URI passed by the previous view controller.
 */
class StreamViewController: UIViewController {
    

    var URI: String?
    @IBOutlet weak var startStopBtn: UIButton!
    @IBOutlet weak var detectedResultLabel: UILabel!
    @IBOutlet weak var movieView: UIView!
    var processing = false
    var processingTimer : Timer?
    var mediaPlayer = VLCMediaPlayer()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Associate the movieView to the VLC media player
        mediaPlayer.drawable = self.movieView
        
        // Create `VLCMedia` with the URI retrieved from the camera
        if let URI = URI {
            let url = URL(string: URI)
            let media = VLCMedia(url: url)
            mediaPlayer.media = media
        }
        
        mediaPlayer.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mediaPlayer.stop()
    }
    
    @objc func extractFrame(){
        
        let size = movieView.frame.size
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        
        let rec = movieView.frame
        
        // Add navigation bar height
        let newRec = CGRect(x: rec.origin.x, y: rec.origin.y - 88, width: rec.size.width, height: rec.size.height)
        movieView.drawHierarchy(in: newRec, afterScreenUpdates: false)
        
        if let image = UIGraphicsGetImageFromCurrentImageContext(){
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            self.recognize(image.cgImage!)
        }
        UIGraphicsEndImageContext();
    
    }
    
    // Run vision and CoreML on Inception3
    func recognize(_ image: CGImage){
        
        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else {
            return }
        
        let request = VNCoreMLRequest(model: model) { (finishedReq, error) in
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else {
                return
            }
            
  
            for result in results{
                if result.confidence >= 0.1{
                print("----------Result-----------")
                print(result.identifier, result.confidence)
                    self.detectedResultLabel.text = result.identifier + " confidence: " + result.confidence.description
                }else{
                    return
                }
            }
            
        }
        
        try? VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
    }
    
    @IBAction func startStopClicked(_ sender: UIButton) {
        if self.processing == false{
            self.startStopBtn.titleLabel?.text = "Stop"
            self.processing = true
            self.processingTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(extractFrame), userInfo: nil, repeats: true)
            
        }else{
            self.startStopBtn.titleLabel?.text = "Start"
            self.processing = false
            self.processingTimer?.invalidate()
            self.processingTimer = nil
        }
    }
}
