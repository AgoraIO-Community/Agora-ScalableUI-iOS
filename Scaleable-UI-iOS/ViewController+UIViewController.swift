//
//  ViewController+UIViewController.swift
//  Scaleable-UI-iOS
//
//  Created by Max Cobb on 22/02/2021.
//

import UIKit

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.videoUsers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(
            withReuseIdentifier: "collectionItem", for: indexPath
        ) as! AgoraCollectionItem
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let agoraCell = cell as? AgoraCollectionItem else {
            fatalError("cell is not agoracollectionitem")
        }
        let videoUID = self.videoUsers[indexPath.row]
        guard let canvas = self.usersCanvasMap[videoUID],
              let canvasView = canvas.view else {
            fatalError("could not get canvas and view for \(videoUID)")
        }
        agoraCell.canvas = canvas
        agoraCell.addSubview(canvasView)
        canvasView.frame = agoraCell.bounds
        canvasView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if videoUID != self.myUserID {
            print("\(videoUID) high")
            self.agkit.setRemoteVideoStream(videoUID, type: .high)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let agoraCell = cell as? AgoraCollectionItem,
              let userID = agoraCell.canvas?.uid else {
            fatalError("cell is not agoracollectionitem")
        }
        print("end displaying \(userID)")
        agoraCell.canvas?.view?.removeFromSuperview()
        agoraCell.canvas = nil
        if userID != self.myUserID {
            print("\(userID) low")
            self.agkit.setRemoteVideoStream(userID, type: .low)
        }
    }

}
