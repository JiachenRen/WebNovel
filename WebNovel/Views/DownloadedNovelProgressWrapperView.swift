//
//  DownloadedNovelProgressWrapperView.swift
//  WebNovel
//
//  Created by Jiachen Ren on 7/10/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit

@IBDesignable
class DownloadedNovelProgressWrapperView: UIView {

    @IBInspectable var cornerRadius: CGFloat = 4
    @IBInspectable var lineWidth: CGFloat = 0.5
    @IBInspectable var color: UIColor = .lightGray
    @IBInspectable var strokeAlpha: CGFloat = 0.5
    @IBInspectable var fillAlpha: CGFloat = 0.1
    
    override func draw(_ rect: CGRect) {
        let shrinked = CGRect(
            origin: CGPoint(x: rect.minX + lineWidth, y: rect.minY + lineWidth),
            size: CGSize(width: rect.width - lineWidth * 2, height: rect.height - lineWidth * 2)
        )
        let roundedRect = UIBezierPath(roundedRect: shrinked, cornerRadius: cornerRadius)
        color.withAlphaComponent(fillAlpha).setFill()
        roundedRect.fill()
        color.withAlphaComponent(strokeAlpha).setStroke()
        roundedRect.lineWidth = lineWidth
        roundedRect.stroke()
    }
    
}
