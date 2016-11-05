//
//  ViewController.swift
//  captiontalk
//
//  Created by Aaron Liu on 11/4/16.
//  Copyright © 2016 Aaron Liu. All rights reserved.
//

import UIKit
import AVFoundation
import QuartzCore
import Speech
class ViewController: UIViewController,AVCaptureFileOutputRecordingDelegate, SFSpeechRecognizerDelegate{
    var captureSession: AVCaptureSession!
    var previewLayer = AVCaptureVideoPreviewLayer()
    var deleteVideoHelper: FileManager? = FileManager()
    var speechString = String()

    @IBOutlet weak var progressBarBack: UIView!
    @IBOutlet weak var progressBar: UIView!
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

    //speech private vars
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        //add hold and release gestures to uibutton
        fatButton.addTarget(self, action: #selector(holdDown(sender:)), for: UIControlEvents.touchDown)
        fatButton.addTarget(self, action: #selector(holdRelease(sender:)), for: UIControlEvents.touchUpInside)
        fatButton.addTarget(self, action: #selector(holdRelease(sender:)), for: UIControlEvents.touchDragExit)
        // hide progressbar
        progressBar.isHidden = true
        progressBarBack.isHidden = true
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
        
        // set up speech
      
        SFSpeechRecognizer.requestAuthorization { (authStatus) in  //4
            
           
            var isButtonEnabled = true
            switch authStatus {  //5
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            if (isButtonEnabled == true){
                self.fatButton.isEnabled = true
            }
            else{
                self.fatButton.isEnabled = false
            }
        }
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
        if (self.smallLabel.isHidden == false){
            self.smallLabel.isHidden = true
            self.bigLabel.isHidden = true
        }
        if (progressBar.isHidden == true){
            progressBar.isHidden = false
            progressBarBack.isHidden = false
            

            UIView.animate(withDuration: 5, animations: { 
                self.progressBar.transform = CGAffineTransform(scaleX: 0.000001, y: 1)
            }, completion: { (completion) in
                if (self.videoFileOutput.isRecording == true){
                    self.videoFileOutput.stopRecording()
                }
            })
        }
        videoFileOutput.startRecording(toOutputFileURL: tempFilePath as URL!, recordingDelegate: recordingDelegate)
        recordSpeech()
        
    }
    
    func holdRelease(sender:UIButton){
        if (self.smallLabel.isHidden == true){
            self.smallLabel.isHidden = false
            self.bigLabel.isHidden = false
        }
        videoFileOutput.stopRecording()
        if (progressBar.isHidden == false){
            progressBar.isHidden = true
            progressBarBack.isHidden = true
            progressBar.layer.removeAllAnimations()
            progressBar.transform = CGAffineTransform(scaleX: 1, y: 1)
            }
        if (audioEngine.isRunning == true){
            audioEngine.stop()
            recognitionRequest?.endAudio()
        }
        
    }
    

    func recordSpeech() -> Void {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                self.speechString = (result?.bestTranscription.formattedString)!
                print(self.speechString)
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.fatButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
    }


    //AVCaptureFileOutputRecordingDelegate delegate methods
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        print("recording...")
    }
    
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        print ("DONE!")
    }
    
    
    // speechrecognizer delegate
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            fatButton.isEnabled = true
        } else {
            fatButton.isEnabled = false
        }
    }
    
    
}

