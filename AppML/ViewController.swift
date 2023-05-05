//
//  ViewController.swift
//  AppML
//
//  Created by Luis Javier Canto Hurtado on 04/05/23.
//

import UIKit
import Vision

class ViewController: UIViewController {
    
    private lazy var digitLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .clear
        label.layer.cornerRadius = 10.0
        label.layer.borderColor = UIColor.blue.cgColor
        label.layer.borderWidth = 2.0
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 80, weight: .bold)
        label.textAlignment = .center
        label.textColor = .black
        label.text = "0"
        return label
    }()
    
    private lazy var canvasView: CanvasView = {
        let view = CanvasView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view .backgroundColor = .black
        return view
    }()
    
    private lazy var clearButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Clear", for: .normal)
        button.addTarget(self, action: #selector(clearCanvas), for: .touchUpInside)
        button.backgroundColor = .lightGray
        button.layer.cornerRadius = 10
        return button
    }()
    
    private lazy var recognizeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Recognize", for: .normal)
        button.addTarget(self, action: #selector(recognizeDigit), for: .touchUpInside)
        button.backgroundColor = .blue
        button.layer.cornerRadius = 10
        return button
    }()
    
    private var requests = [VNRequest]() // holds Image Classification Request
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVision()
        view.backgroundColor = .white
        view.addSubview(digitLabel)
        view.addSubview(canvasView)
        view.addSubview(clearButton)
        view.addSubview(recognizeButton)
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            digitLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            digitLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            digitLabel.heightAnchor.constraint(equalToConstant: 100),
            digitLabel.widthAnchor.constraint(equalToConstant: 100),
            canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            canvasView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
            clearButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            clearButton.bottomAnchor.constraint(equalTo: canvasView.topAnchor, constant: -16),
            clearButton.heightAnchor.constraint(equalToConstant: 50),
            clearButton.widthAnchor.constraint(equalToConstant: 100),
            recognizeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            recognizeButton.bottomAnchor.constraint(equalTo: canvasView.topAnchor, constant: -16),
            recognizeButton.heightAnchor.constraint(equalToConstant: 50),
            recognizeButton.widthAnchor.constraint(equalToConstant: 100),
        ])
    }

    private func setupVision() {
        // load MNIST model for the use with the Vision framework
        guard let visionModel = try? VNCoreMLModel(for: MNIST().model) else {fatalError("can not load Vision ML model")}
        // create a classification request and tell it to call handleClassification once its done
        let classificationRequest = VNCoreMLRequest(model: visionModel, completionHandler: self.handleClassification)
        self.requests = [classificationRequest] // assigns the classificationRequest to the global requests array
    }
    
    private func handleClassification(request: VNRequest, error: Error?) {
        guard let observations = request.results else { return }
        // process the ovservations
        let classifications = observations
            .compactMap({$0 as? VNClassificationObservation}) // cast all elements to VNClassificationObservation objects
            .filter({$0.confidence > 0.8}) // only choose observations with a confidence of more than 80%
            .map({$0.identifier}) // only choose the identifier string to be placed into the classifications array
        DispatchQueue.main.async {
            self.digitLabel.text = classifications.first // update the UI with the classification
        }
    }
    
    @objc private func clearCanvas() {
        canvasView.clearCanvas()
    }
    
    @objc private func recognizeDigit() {
        let image = UIImage(view: canvasView) // get UIImage from CanvasView
        // scale the image to the required size of 28x28 for better recognition results
        let scaledImage = scaleImage(image: image, toSize: CGSize(width: 28, height: 28))
        // create a handler that should perform the vision request
        let imageRequestHandler = VNImageRequestHandler(cgImage: scaledImage.cgImage!, options: [:])
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
    
    // scales any UIImage to a desired target size
    private func scaleImage(image: UIImage, toSize size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}
