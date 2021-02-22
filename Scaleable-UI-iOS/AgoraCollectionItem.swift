//
//  AgoraCollectionItem.swift
//  Scaleable-UI-iOS
//
//  Created by Max Cobb on 22/02/2021.
//

import UIKit
import AgoraRtcKit

/// Item in the collection view to contain the user's video feed, as well as microphone signal.
class AgoraCollectionItem: UICollectionViewCell {
    /// View for the video frame.
    var canvas: AgoraRtcVideoCanvas?

    var uid: UInt? { self.canvas?.uid }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .systemGray
//        let maskView = UIView(frame: self.bounds)
//        maskView.backgroundColor = .blue
//        maskView.layer.cornerRadius = 64
//        maskView.layer.cornerCurve = .continuous
//        self.mask = maskView
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

