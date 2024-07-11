//
//  CameraView.swift
//  cashdine1
//
//  Created by Vasyl Maryna on 28.04.2024.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @State private var scannedCode: String?

    var body: some View {
        VStack {
            if let code = scannedCode {
                Text("Scanned QR Code: \(code)")
            } else {
                ScannerView(scannedCode: $scannedCode)
            }
        }
    }
}

struct ScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?

    func makeUIViewController(context: Context) -> ScannerViewController {
        let scannerViewController = ScannerViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    class Coordinator: NSObject, ScannerViewControllerDelegate {
        var parent: ScannerView

        init(parent: ScannerView) {
            self.parent = parent
        }

        func didFindCode(_ code: String) {
            parent.scannedCode = code
        }
    }
}

protocol ScannerViewControllerDelegate: AnyObject {
    func didFindCode(_ code: String)
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: ScannerViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }

        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {
            return
        }

        let captureSession = AVCaptureSession()
        captureSession.addInput(input)

        let metadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(metadataOutput)

        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(x: view.bounds.origin.x, y: view.bounds.origin.y + 20, width: view.bounds.width, height: view.bounds.height - 20)
        previewLayer.videoGravity = .resizeAspectFill
        
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else {
                return
            }
            guard let stringValue = readableObject.stringValue else {
                return
            }
            delegate?.didFindCode(stringValue)
        }
    }
}

