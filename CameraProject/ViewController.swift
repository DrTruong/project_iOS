//
//  ViewController.swift
//  CameraProject
//
//  Created by Kis User on 4/19/21.
//

import UIKit
import AVFoundation
import PhotosUI

class ViewController: UIViewController, UIGestureRecognizerDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate{
    
    @IBOutlet weak var currencyQuality: UIPickerView!
    
    @IBOutlet var gestureRecognizer: UIPinchGestureRecognizer!
    @IBOutlet weak var previewView: UIView!
    
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var image: UIImage!
    
    var usingFrontCamera = false
    let arrayQuality = ["Low", "Medium", "High", "cif352x288", "hd1280x720", "hd1920x1080", "hd4K3840x2160", "iFrame1280x720", "iFrame960x540", "vga640x480"]

    var deviceInput = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        captureSession = AVCaptureSession()
        
        do {
            
            deviceInput?.isFocusModeSupported(.continuousAutoFocus)

            try deviceInput?.lockForConfiguration()
            deviceInput?.focusMode = .continuousAutoFocus
            deviceInput?.unlockForConfiguration()


            let input = try AVCaptureDeviceInput(device: deviceInput!)
            stillImageOutput = AVCapturePhotoOutput()
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)

                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                videoPreviewLayer.videoGravity = .resizeAspectFill
                videoPreviewLayer.connection?.videoOrientation = .portrait
                previewView.layer.addSublayer((videoPreviewLayer)!)

                self.captureSession.startRunning()

                self.videoPreviewLayer.frame = self.previewView.bounds

            }
        }
        catch let error{
            print(error.localizedDescription)
        }
    }



    @IBAction func tapToFocus(_ sender: UITapGestureRecognizer) {
        let devicePoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: sender.location(in: sender.view))
        focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
    }

    private func focus(with focusMode: AVCaptureDevice.FocusMode,
                       exposureMode: AVCaptureDevice.ExposureMode,
                       at devicePoint: CGPoint,
                       monitorSubjectAreaChange: Bool) {

        DispatchQueue.main.async {
            do {
                try self.deviceInput?.lockForConfiguration()
                if self.deviceInput!.isFocusPointOfInterestSupported && ((self.deviceInput?.isFocusModeSupported(focusMode)) != nil) {
                    self.deviceInput?.focusPointOfInterest = devicePoint
                    self.deviceInput?.focusMode = focusMode
                }

                if self.deviceInput!.isExposurePointOfInterestSupported && ((self.deviceInput?.isExposureModeSupported(exposureMode)) != nil) {
                    self.deviceInput?.exposurePointOfInterest = devicePoint
                    self.deviceInput?.exposureMode = exposureMode
                }

                self.deviceInput?.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                self.deviceInput?.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
        
        
    }


    @IBAction func didTakePhoto(_ sender: Any) {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])

        stillImageOutput.capturePhoto(with: settings, delegate: self)
    }
    
    

    
    @IBAction func rotateCam(_ sender: Any) {
        
        captureSession.beginConfiguration()
        if let inputs = captureSession.inputs as? [AVCaptureDeviceInput]{
            for input in inputs{
                captureSession.removeInput(input)
            }
        }
        
        usingFrontCamera = !usingFrontCamera
        
        captureSession.sessionPreset = .photo
        
        DispatchQueue.main.async{
            let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
            let devices = deviceDiscoverySession.devices
            for device in devices{
                if self.usingFrontCamera && device.position == .front{
                    self.deviceInput = device
                }else if device.position == .back{
                    self.deviceInput = device
                }
            }
        }
        
        DispatchQueue.main.async {
                    do {
                        let captureDeviceInput = try AVCaptureDeviceInput(device: self.deviceInput!)
                        if self.captureSession.canAddInput(captureDeviceInput) {
                            self.captureSession.addInput(captureDeviceInput)
                        }
                        self.stillImageOutput = AVCapturePhotoOutput()
                        self.stillImageOutput.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format:[AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
                        if self.captureSession.canAddOutput(self.stillImageOutput) {
                            self.captureSession.addOutput(self.stillImageOutput)
                        }
                    } catch {
                        print(error)
                    }
                }
        
        captureSession.commitConfiguration()
        captureSession.startRunning()
    }
    
    @IBAction func accessLibrary(_ sender: Any) {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        present(vc, animated: true)
    }
    
    
    @IBAction func pinchToZoom(_ sender: UIPinchGestureRecognizer) {
        guard let zoomView = gestureRecognizer.view else{
            return
        }

        zoomView.transform = zoomView.transform.scaledBy(x: gestureRecognizer.scale, y: gestureRecognizer.scale)

        gestureRecognizer.scale = 1
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currencyQuality.dataSource = self
        currencyQuality.delegate = self
    }
    
}

extension ViewController: UIPickerViewDataSource{
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return arrayQuality.count
    }
}

extension ViewController: UIPickerViewDelegate{
    
    // chon mot quality
    func pickerView(_ pickerView: UIPickerView, titleForRow row:Int, forComponent component: Int) -> String?{
        return arrayQuality[row]
    }
    
    // xu ly khi chon mot quality
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let quality = arrayQuality[row]

        switch quality {
        case "Low":
            captureSession.sessionPreset = .low
        case "Medium":
            captureSession.sessionPreset = .medium
        case "cif352x288":
            captureSession.sessionPreset = .cif352x288
        case "hd1280x720":
            captureSession.sessionPreset = .hd1280x720
        case "hd1920x1080":
            captureSession.sessionPreset = .hd1920x1080
        case "hd4K3840x2160":
            captureSession.sessionPreset = .hd4K3840x2160
        case "iFrame1280x720":
            captureSession.sessionPreset = .iFrame1280x720
        case "iFrame960x540":
            captureSession.sessionPreset = .iFrame960x540
        case "vga640x480":
            captureSession.sessionPreset = .vga640x480
        default:
            captureSession.sessionPreset = .high
        }
    }
}

extension ViewController: AVCapturePhotoCaptureDelegate{
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(){
            image = UIImage(data: imageData)
            // save capture
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            dismiss(animated: true, completion: nil)
            print("Save successful")
        }
    }
}
