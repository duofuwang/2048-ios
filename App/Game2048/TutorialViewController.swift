import UIKit
import ImageIO

final class TutorialViewController: UIViewController {
    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        let title = label(NSLocalizedString("tutorial", comment: ""), size: 60, fontName: "HelveticaNeue-UltraLight")
        let stepOne = label(
            NSLocalizedString("t1", comment: ""),
            size: 20, fontName: "HelveticaNeue-Light"
        )
        let gridView = UIImageView(image: animatedGIF(named: "grid"))
        gridView.contentMode = .scaleAspectFit
        let stepTwo = label(
            NSLocalizedString("t2", comment: ""),
            size: 20, fontName: "HelveticaNeue-Light"
        )
        let addImage = UIImageView(image: UIImage(named: "add"))
        addImage.contentMode = .scaleAspectFit
        let stepThree = label(NSLocalizedString("t3", comment: ""), size: 20, fontName: "HelveticaNeue-Light")
        let maxImage = UIImageView(image: UIImage(named: "max"))
        maxImage.contentMode = .scaleAspectFit
        let best = label(NSLocalizedString("bol", comment: ""), size: 40, fontName: "HelveticaNeue-Light")

        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage(named: "yes_default"), for: .normal)
        closeButton.setImage(UIImage(named: "yes_press"), for: .highlighted)
        closeButton.imageView?.contentMode = .scaleAspectFit
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        for subview in [title, stepOne, gridView, stepTwo, addImage, stepThree, maxImage, best, closeButton] {
            stack.addArrangedSubview(subview)
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),

            stepOne.widthAnchor.constraint(equalTo: stack.widthAnchor),
            stepTwo.widthAnchor.constraint(equalTo: stack.widthAnchor),
            stepThree.widthAnchor.constraint(equalTo: stack.widthAnchor),

            gridView.widthAnchor.constraint(equalToConstant: 150),
            gridView.heightAnchor.constraint(equalToConstant: 150),
            addImage.widthAnchor.constraint(equalToConstant: 220),
            addImage.heightAnchor.constraint(equalToConstant: 55),
            maxImage.widthAnchor.constraint(equalToConstant: 70),
            maxImage.heightAnchor.constraint(equalToConstant: 70),
            closeButton.widthAnchor.constraint(equalToConstant: 90),
            closeButton.heightAnchor.constraint(equalToConstant: 90),
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    private func label(_ text: String, size: CGFloat, fontName: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UIColor(hex: 0x4D4D4D)
        label.font = UIFont(name: fontName, size: size) ?? .systemFont(ofSize: size)
        return label
    }

    private func animatedGIF(named name: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        let count = CGImageSourceGetCount(source)
        var frames: [UIImage] = []
        var duration: Double = 0
        for index in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            frames.append(UIImage(cgImage: cgImage))
            if let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? NSDictionary,
               let gif = properties[kCGImagePropertyGIFDictionary] as? NSDictionary,
               let delay = gif[kCGImagePropertyGIFUnclampedDelayTime] as? Double {
                duration += delay
            }
        }
        return frames.isEmpty ? nil : UIImage.animatedImage(with: frames, duration: duration)
    }
}
