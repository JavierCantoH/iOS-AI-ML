//
//  PredictionsApi.swift
//  AppML
//
//  Created by Luis Javier Canto Hurtado on 04/05/23.
//

import UIKit
import Alamofire

class PredictionsApi: UIViewController {
    
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
        label.text = ""
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    @objc private func clearCanvas() {
        canvasView.clearCanvas()
        digitLabel.text = ""
    }
    
    @objc private func recognizeDigit() {
        let image = UIImage(view: canvasView) // get UIImage from CanvasView
        // scale the image to the required size of 28x28 for better recognition results
        let scaledImage = scaleImage(image: image, toSize: CGSize(width: 28, height: 28))
        
        guard let imageData = scaledImage.pngData() else {
            print("Error al convertir la imagen en datos PNG")
            return
        }
        
        let pixelData = imageData.pixelData() // Obtener datos de píxeles de la imagen
        
        let flattenedPixelData = pixelData.compactMap { $0 } // Aplanar los valores de píxeles en una sola matriz
        
        var reshapedPixelData = Array(repeating: Float(0.0), count: 784) // Crear una matriz de tamaño 784 rellenada con ceros
        
        for (index, value) in flattenedPixelData.enumerated() {
            reshapedPixelData[index] = Float(value)
        }
        
        let parameters = [
            "instances": [[reshapedPixelData]]
        ]
        
        AF.request("https://linear-model-service-javiercantoh.cloud.okteto.net/v1/models/linear-model:predict", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil)
            .validate()
            .responseDecodable(of: ImageResponse.self) { response in
                switch response.result {
                case .success(let value):
                    let predictedClass = value.predictions[0].enumerated().max(by: { $0.element < $1.element })?.offset
                    print("predictions: \(value.predictions[0])")
                    if let predictedClass = predictedClass {
                        self.digitLabel.text = "\(predictedClass)"
                    } else {
                        self.digitLabel.text = "Failed"
                    }
                case .failure(let error):
                    print("API request error: \(error)")
                    self.digitLabel.text = "API error"
                }
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

// Función para obtener los datos de píxeles de la imagen
private extension Data {
    func pixelData() -> [Float] {
        var pixelData: [Float] = []
        self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> Void in
            let pointer = bytes.baseAddress?.assumingMemoryBound(to: UInt8.self)
            let pixelBuffer = UnsafeBufferPointer(start: pointer, count: self.count)
            
            for pixel in pixelBuffer {
                let pixelValue = Float(pixel) / 255.0
                pixelData.append(pixelValue)
            }
        }
        return pixelData
    }
}

struct ImageResponse: Codable {
    let predictions: [[Float]]
}
