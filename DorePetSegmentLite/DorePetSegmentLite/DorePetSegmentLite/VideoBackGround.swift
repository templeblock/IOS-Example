//
//  VideoBackGround.swift
//  DorePetSegmentLiteDemo
//
//  Copyright © 2020 dore. All rights reserved.
//

import Foundation
import UIKit
//===DoreAI Framework====
import DoreCoreAI
import DorePetSegmentLite
//======================
import AVFoundation


class VideoBackGround: UIViewController, CameraFeedManagerDelegate, PetSegmentLiteDelegate {
    
    @IBAction func btnBack_Action(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var cameraView: CaptureView!
    @IBOutlet weak var maskoutView: UIImageView!
    
    private var modelManager: PetSegmentLiteManager?
    
    
    private var player:AVPlayer!
    
    public var alertView:UIAlertController!
    public var progressView:UIProgressView!
    
    public lazy var cameraCapture = CameraFeedManager(previewView: cameraView, CameraPosition: AVCaptureDevice.Position.back )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //camerasession delegate
        cameraCapture.delegate = self
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        modelManager = PetSegmentLiteManager()
        modelManager?.delegate = self
        
        //  Just create your alert for downloading library files
        alertView = UIAlertController(title: "Loading", message: "Please Wait...!", preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        //  Show it to your users
        present(alertView, animated: true, completion: {
            //  Add your progressbar after alert is shown (and measured)
            let margin:CGFloat = 8.0
            let rect = CGRect(x: margin, y: 72.0, width: self.alertView.view.frame.width - margin * 2.0 , height: 2.0)
            self.progressView = UIProgressView(frame: rect)
            self.progressView!.progress = 0.0
            self.progressView!.tintColor = self.view.tintColor
            self.alertView.view.addSubview(self.progressView!)
            
            //Load license / start initiating
            self.modelManager?.init_data(licKey: HomePage.lickey)
        })
        
        
        
        
        //play video
        let vpath = Bundle.main.path(forResource: "video1", ofType:"mp4")
        player = AVPlayer(url: URL(fileURLWithPath: vpath!))
        player.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(notification:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem)
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = videoView.bounds
        videoView.layer.addSublayer(playerLayer)
        player.play()
        
        
        
    }
    
    
    @objc func playerItemDidReachEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            player.pause()
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
            player.play()
        }
    }
    
    
    //===DorePetSegmentLiteDelegate===
    func onPetSegmentLiteSuccess(_ info: String) {
        self.alertView.dismiss(animated: true, completion: nil)
        //DorePetSegment Library files downloaded successfully...! Ready to run segment
        cameraCapture.checkCameraConfigurationAndStartSession()
    }
    
    func onPetSegmentLiteFailure(_ error: String) {
        self.alertView.dismiss(animated: true, completion: nil)
        //DorePetSegment Library files downloading failed..!
        print(error)
    }
    
    func onPetSegmentLiteProgressUpdate(_ progress: String) {
        //DorePetSegment Library files downloading...!
        print(progress)
        self.progressView!.progress = Float(progress)!
    }
    
    func onPetSegmentLiteDownloadSpeed(_ dps: String) {
        print(dps)
    }
    //==============================
    
    override func viewWillDisappear(_ animated: Bool) {
        cameraCapture.stopSession()
    }
    
    
    func didOutput(pixelBuffer: CVPixelBuffer) {
        
        
        
        
        //run model and get result
        let result:segmentOut  = segmentOut ( features: (self.modelManager?.run_model(onFrame: pixelBuffer))! )
        
        //mask image White - bacground, Black - foreground
        let ciImage:UIImage = getMaskWB(result.semanticPredictions)!
        
        
        
        //extract image
        let rgbCIimage:CIImage = CIImage.init(cvPixelBuffer: pixelBuffer)
        let rgbImage:UIImage = convertCItoUIimage(cmage: rgbCIimage)
        let finalImage:UIImage = cutoutmaskImage(image: rgbImage, mask: ciImage)
        
        
        
        
        DispatchQueue.main.async {
            self.maskoutView.image = finalImage
        }
        
        
        
    }
    
    
    
    
    // MARK: Session Handling Alerts
    func sessionWasInterrupted(canResumeManually resumeManually: Bool) {
        
        
    }
    
    func sessionInterruptionEnded() {
        
    }
    
    func sessionRunTimeErrorOccured() {
        
    }
    
    func presentCameraPermissionsDeniedAlert() {
        let alertController = UIAlertController(title: "Camera Permissions Denied", message: "Camera permissions have been denied for this app. You can change this by going to Settings", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (action) in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func presentVideoConfigurationErrorAlert() {
        let alert = UIAlertController(title: "Camera Configuration Failed", message: "There was an error while configuring camera.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    
    
}


