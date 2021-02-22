//
//  ViewController+AgoraRtcEngineDelegate.swift
//  Scaleable-UI-iOS
//
//  Created by Max Cobb on 22/02/2021.
//

import AgoraRtcKit

extension ViewController: AgoraRtcEngineDelegate {
    func rtcEngine(
        _ engine: AgoraRtcEngineKit,
        remoteVideoStateChangedOfUid uid: UInt,
        state: AgoraVideoRemoteState,
        reason: AgoraVideoRemoteStateReason,
        elapsed: Int
    ) {
        switch state {
        case .decoding, .starting:
            if self.usersCanvasMap[uid] == nil {
                let newCanvas = AgoraRtcVideoCanvas()
                newCanvas.uid = uid
                newCanvas.view = UIView()
                self.usersCanvasMap[uid] = newCanvas
                self.videoUsers.append(uid)
                self.agkit.setupRemoteVideo(newCanvas)
                self.agkit.setRemoteVideoStream(uid, type: .low)
                self.collectionView?.reloadData()
            } else {
                self.usersCanvasMap[uid]?.view?.isHidden = false
            }
        case .stopped: usersCanvasMap[uid]?.view?.isHidden = true
        default: break
        }
    }
    func rtcEngine(
        _ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt,
        reason: AgoraUserOfflineReason
    ) {
        usersCanvasMap[uid]?.view?.removeFromSuperview()
        usersCanvasMap[uid]?.view = nil
        usersCanvasMap.removeValue(forKey: uid)
        self.videoUsers.removeAll{ $0 == uid }
        self.collectionView?.reloadData()
    }
}

