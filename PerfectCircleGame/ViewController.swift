//
//  ViewController.swift
//  PerfectCircleGame
//
//  Created by Акбала Тлеугалиева on 21.04.2023.
//

import UIKit
import SnapKit

class ViewController: UIViewController {
        
    private var drawView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        return v
    }()
    
    private var dotView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 10
        return v
    }()
    
    private var currentPercantageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24.0, weight: .bold)
        label.textColor = .green
        label.textAlignment = .center
        return label
    }()
    
    private var highestValue: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24.0, weight: .bold)
        label.textColor = .green
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    lazy var resetButton: UIButton = {
        let button = UIButton()
        button.setTitle("Reset", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .blue
        button.layer.cornerRadius = 8.0
        button.isHidden = true
        button.addTarget(self, action: #selector(resetAction(_:)), for: .touchUpInside)
        return button
    }()
    
    var dotLayer = CAShapeLayer()
    var lastPoint = CGPoint()
    var radius: CGFloat = 0.0 // perfect circle radius
    var centerPoint = CGPoint()
    var combinedPath = UIBezierPath()
    var highestQuality: CGFloat = 0.0
    var timer: Timer?
    var minRadius: CGFloat = 35.0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(drawView)
        
        drawView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        drawView.addSubview(dotView)
        dotView.snp.makeConstraints { make in
            make.centerX.equalTo(drawView.snp.centerX)
            make.centerY.equalTo(drawView.snp.centerY)
            make.width.equalTo(20)
            make.height.equalTo(20)
        }
        
        drawView.addSubview(currentPercantageLabel)
        currentPercantageLabel.snp.makeConstraints { make in
            make.bottom.equalTo(dotView.snp.top).offset(-15)
            make.centerX.equalToSuperview()
        }
        drawView.addSubview(resetButton)
        resetButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-50)
            make.centerX.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(40)
        }
        drawView.addSubview(highestValue)
        highestValue.snp.makeConstraints { make in
            make.bottom.equalTo(resetButton.snp.top).offset(-50)
            make.centerX.equalToSuperview()
        }
        
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = UIFont.boldSystemFont(ofSize: 25)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = "Try to draw a perfect circle!"
        
        drawView.addSubview(label)
        label.snp.makeConstraints{ make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(30)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        drawView.addGestureRecognizer(panGesture)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    
    // MARK: @objc actions
    
    @objc func resetAction(_ sender: UIButton) {
        currentPercantageLabel.text = ""
        highestValue.isHidden = true
        sender.isHidden = true
        drawView.layer.sublayers?.forEach { layer in
            if layer is CAShapeLayer {
                layer.removeFromSuperlayer()
            }
        }
    }

    @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        let point = gestureRecognizer.location(in: drawView)
        centerPoint = dotView.center
        switch gestureRecognizer.state {
        case .began:
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: false, block: { [weak self] _ in
                self?.showRestartAlert("Too slow!") //  если игрок рисует слишком медленно
            })
            radius = point.distance(to: centerPoint) //Если у нас есть центральная точка, то расстояние от начальной точки до центральной точки можно рассматривать как радиус идеальной окружности
            
            highestValue.isHidden = true
            resetButton.isHidden = true
            combinedPath.removeAllPoints()
            lastPoint = point
            drawView.layer.sublayers?.forEach { layer in
                if layer is CAShapeLayer {
                    layer.removeFromSuperlayer()
                }
            }
        case .changed:

            let path = UIBezierPath()
            path.move(to: lastPoint)
            path.addLine(to: point)
            lastPoint = point

            let newLineLayer = CAShapeLayer()
            newLineLayer.path = path.cgPath
            newLineLayer.strokeColor = UIColor.green.cgColor
            newLineLayer.lineWidth = 4.0
            drawView.layer.addSublayer(newLineLayer)

            let currentRadius = point.distance(to: centerPoint) // расстояние от текущей точки и до центральной точки
            
            if currentRadius < minRadius { // если игрок рисует слишком близко к точке
                showRestartAlert("Too close!")
            }
            
            let error = abs(currentRadius - radius)
            let colorPercentage = ((1.0 - error / radius) * 100.0) // тут мы вычисляем абсолютное значение разницы между текущим и целевым радиусом, чтобы определить, насколько близок текущий радиус к целевому.
            

            newLineLayer.strokeColor = color(forPercentage: Double(colorPercentage)).cgColor // По мере ухудшения качества круга изменять цвет в более красный
        
            //  Compare with the ideal circle
            
            let currentPath = UIBezierPath(ovalIn: CGRect(x: centerPoint.x - currentRadius, y: centerPoint.y - currentRadius, width: currentRadius * 2, height: currentRadius * 2))
            
            let perfectPath = UIBezierPath(ovalIn: CGRect(x: centerPoint.x - radius, y: centerPoint.y - radius, width: radius * 2, height: radius * 2))

            combinedPath.append(currentPath)
            
            let quality = calculateCircleQuality(expectedPath: perfectPath, userPath: combinedPath) * 100
            if quality > highestQuality {
                highestQuality = quality
            }
            currentPercantageLabel.textColor = color(forPercentage: Double(colorPercentage))
            currentPercantageLabel.text = "\(String(format: "%.1f", quality)) %"
        case .ended:
            timer?.invalidate()
            highestValue.text = "\(String(format: "%.1f", highestQuality)) %"
            highestValue.isHidden = false
            resetButton.isHidden = false
        default:
            break
        }
    }
    
    
    
    private func calculateCircleQuality(expectedPath: UIBezierPath , userPath: UIBezierPath) -> Double {
        // Тут я долго думала как определить качество круга. У нас есть радиус и примерный путь идеального круга.
        // Поэтому я решила вычислить отклонение периметра нарисованного круга от ожидаемого периметра и делит эту разницу на ожидаемый периметр
        
        let userPerimeter = userPath.cgPath.boundingBoxOfPath.width * CGFloat.pi
        let expectedPerimeter = expectedPath.cgPath.boundingBoxOfPath.width * CGFloat.pi

        let quality = 1.0 - abs(userPerimeter - expectedPerimeter) / expectedPerimeter

        let qualityLowerBound: Double = 0.0
        let finalQuality = max(quality, qualityLowerBound)

        return finalQuality
    }

    
    private func color(forPercentage percentage: Double) -> UIColor { // возвращает цвет в зависимости от этого значения
        let green = UIColor(red: 0/255, green: 255/255, blue: 0/255, alpha: 1)
        let yellow = UIColor(red: 255/255, green: 255/255, blue: 0/255, alpha: 1)
        let orange = UIColor(red: 255/255, green: 165/255, blue: 0/255, alpha: 1)
        let red = UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 1)
        
        if percentage >= 95 {
            return green
        } else if percentage >= 90 {
            return UIColor.interpolate(from: green, to: yellow, percent: CGFloat(percentage - 90) / 5)
        } else if percentage >= 80 {
            return UIColor.interpolate(from: yellow, to: orange, percent: CGFloat(percentage - 80) / 10)
        } else {
            return UIColor.interpolate(from: orange, to: red, percent: CGFloat(percentage) / 80)
        }
    }
    
    private func showRestartAlert(_ message: String) {
        let alert = UIAlertController(title: "Game Over", message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart", style: .default) { [weak self] _ in
            self?.currentPercantageLabel.text = ""
            self?.drawView.layer.sublayers?.forEach { layer in
                if layer is CAShapeLayer {
                    layer.removeFromSuperlayer()
                }
            }
        }
        alert.addAction(restartAction)
        present(alert, animated: true)
    }
}

// MARK: - Extensions

extension UIColor {
    
//   чтобы сделать плавный переход
    
    static func interpolate(from: UIColor, to: UIColor, percent: CGFloat) -> UIColor {
        var fRed: CGFloat = 0, fGreen: CGFloat = 0, fBlue: CGFloat = 0, fAlpha: CGFloat = 0
        var tRed: CGFloat = 0, tGreen: CGFloat = 0, tBlue: CGFloat = 0, tAlpha: CGFloat = 0
        
        from.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha)
        to.getRed(&tRed, green: &tGreen, blue: &tBlue, alpha: &tAlpha)
        
        let red = fRed + (percent * (tRed - fRed))
        let green = fGreen + (percent * (tGreen - fGreen))
        let blue = fBlue + (percent * (tBlue - fBlue))
        let alpha = fAlpha + (percent * (tAlpha - fAlpha))
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension CGPoint { // возвращает расстояние между двумя точками
    func distance(to point: CGPoint) -> CGFloat {
        return hypot(point.x - x, point.y - y)
    }
}
