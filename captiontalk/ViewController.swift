//
//  ViewController.swift
//  captiontalk
//
//  Created by Aaron Liu on 11/4/16.
//  Copyright © 2016 Aaron Liu. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController,AVCaptureFileOutputRecordingDelegate{
    var captureSession: AVCaptureSession!
    var previewLayer = AVCaptureVideoPreviewLayer()
    var deleteVideoHelper: FileManager? = FileManager()
    
    @IBOutlet weak var bigLabel: UILabel!
    @IBOutlet weak var smallLabel: UILabel!
    @IBOutlet weak var fatButton: UIButton!
    let videoFileOutput = AVCaptureMovieFileOutput()
    private var tempFilePath: NSURL = {
        
        let tempPath = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tempMovie.mp4")?.absoluteString
        if FileManager.default.fileExists(atPath: tempPath!) {
            do {
                try FileManager.default.removeItem(atPath: tempPath!)
            } catch { }
        }
        return NSURL(string: tempPath!)!
    }()


    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        //add hold and release gestures to uibutton
        fatButton.addTarget(self, action: #selector(holdDown(sender:)), for: UIControlEvents.touchDown)
        fatButton.addTarget(self, action: #selector(holdRelease(sender:)), for: UIControlEvents.touchUpInside)
        
        // initialize front-facing camera
        captureSession = AVCaptureSession()
        
        let frontCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front)
        let frontCameraInput: AVCaptureDeviceInput
        
        do {
                frontCameraInput = try AVCaptureDeviceInput(device: frontCameraDevice)
        }
        catch{
            print("no camera available")
            return
        }
        
        if (captureSession.canAddInput(frontCameraInput)){
            captureSession.addInput(frontCameraInput)
        }
        
        else{
            print ("capture session cannot add input")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = self.view.layer.bounds
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.view.layer.insertSublayer(previewLayer, at: 0)
        captureSession.addOutput(videoFileOutput)
        captureSession.startRunning()
        
        
       
        



        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if(captureSession?.isRunning == false){
            captureSession.startRunning();
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if(captureSession?.isRunning == true) {
            captureSession.stopRunning();
        }
    }

    func holdDown(sender:UIButton){
        let recordingDelegate:AVCaptureFileOutputRecordingDelegate? = self
        
        
      //  let filePath = NSURL.fileURL(withPath: NSTemporaryDirectory(),isDirectory: true)
        print ("hold down")
        videoFileOutput.startRecording(toOutputFileURL: tempFilePath as URL!, recordingDelegate: recordingDelegate)
        
        
    }
    
    func holdRelease(sender:UIButton){
        print ("release")
        videoFileOutput.stopRecording()
        
    }
    

 
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        print("recording start start")
    }
    
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        print ("recording finished")
        print(outputFileURL)
    }
    
    
}

