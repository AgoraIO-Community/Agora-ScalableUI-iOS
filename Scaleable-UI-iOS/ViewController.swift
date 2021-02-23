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
        self.addJoinLeave()
        self.joinChannel()
    }
    var joinLeaveButton: UIButton?
    func addJoinLeave() {
        let btn = UIButton(type: .roundedRect)
        btn.setTitle("Leave", for: .normal)
        btn.backgroundColor = .systemRed
        btn.backgroundColor = .secondarySystemBackground
        btn.layer.cornerRadius = 10
        btn.addTarget(self, action: #selector(toggleJoinChannel), for: .touchUpInside)
        self.joinLeaveButton = btn
        self.view.addSubview(btn)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.widthAnchor).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        btn.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        btn.isEnabled = false
        btn.isHidden = true
    }

    func joinChannel() {
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
            self.joinLeaveButton?.setTitle("Leave", for: .normal)
            self.joinLeaveButton?.backgroundColor = .systemRed
            self.joinLeaveButton?.isEnabled = true
            self.joinLeaveButton?.isHidden = false
        }
    }

    func leaveChannel() {
        if self.agkit.leaveChannel() == 0 {
            for (_, item) in usersCanvasMap.enumerated() {
                item.value.view?.removeFromSuperview()
                item.value.view = nil
            }
            usersCanvasMap.removeAll()
            self.videoUsers.removeAll()
            self.collectionView?.reloadData()

            self.joinLeaveButton?.setTitle("Join", for: .normal)
            self.joinLeaveButton?.backgroundColor = .systemGreen
        }
        self.joinLeaveButton?.isEnabled = true
    }

    @objc func toggleJoinChannel() {
        self.joinLeaveButton?.isEnabled = false
        if self.joinLeaveButton?.title(for: .normal) == "Leave" {
            self.leaveChannel()
        } else {
            self.joinChannel()
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
