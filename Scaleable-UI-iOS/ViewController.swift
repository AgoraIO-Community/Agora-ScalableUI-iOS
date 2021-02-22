//
//  ViewController.swift
//  Scaleable-UI-iOS
//
//  Created by Max Cobb on 16/02/2021.
//

import UIKit
import AgoraRtcKit
import SceneKit

class ViewController: UIViewController {

    /// videoUsers is a list of all joined members
    var videoUsers: [UInt] = []
    /// usersCanvasMap finds the AgoraRtcVideoCanvas for a user ID
    var usersCanvasMap: [UInt: AgoraRtcVideoCanvas] = [:]
    var myUserID: UInt = 0
    var agkit: AgoraRtcEngineKit {
        let agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: <#App ID#>, delegate: self)
        agoraKit.enableVideo()
        agoraKit.setChannelProfile(.liveBroadcasting)
        agoraKit.setClientRole(.broadcaster)
        agoraKit.enableDualStreamMode(true)
        agoraKit.setParameters("""
          { "che.video.lowBitRateStreamParameter": {
            "width":160,"height":120,"frameRate":5,"bitRate":45
          }}
        """)
        return agoraKit
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupViews()
        self.agkit.joinChannel(
            byToken: nil, channelId: "test", info: nil, uid: 0
        ) { _, uid, _ in
            self.myUserID = uid
            self.videoUsers.append(self.myUserID)
            let localCanvas = AgoraRtcVideoCanvas()
            localCanvas.uid = self.myUserID
            localCanvas.view = UIView()
            self.usersCanvasMap[self.myUserID] = localCanvas
            self.agkit.setupLocalVideo(localCanvas)
            self.collectionView?.reloadData()
        }
    }
    var collectionView: UICollectionView?
    func setupViews() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.itemSize = CGSize(
            width: self.view.bounds.width / 2 - 40,
            height: self.view.bounds.width / 2 - 40
        )

        flowLayout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        let scrollView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        scrollView.register(
            AgoraCollectionItem.self,
            forCellWithReuseIdentifier: "collectionItem"
        )
        scrollView.dataSource = self
        scrollView.delegate = self
        self.view.addSubview(scrollView)
        scrollView.frame = self.view.bounds

        // leaving room for buttons at the bottom
        scrollView.frame.size.height -= 50
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.collectionView = scrollView
    }
}
