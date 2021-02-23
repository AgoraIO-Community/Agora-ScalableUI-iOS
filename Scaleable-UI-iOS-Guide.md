# Building Scalable UI for iOS using Agora

One of the biggest challenges facing any developer is building applications that can scale. With a video-conferencing application using Agora the main scaling issue is the bandwidth of your local device, especially if there are many incoming video streams. And as the number of participants rises, it becomes increasingly difficult to make sure that your application can keep up.

In this tutorial, you will see how to use Agora to build an application that can scale to up to 17 users by optimizing the bandwidth usage of the incoming video streams.

# Prerequisites

- An Agora developer account (see [How To Get Started with Agora](https://www.agora.io/en/blog/how-to-get-started-with-agora?utm_source=medium&utm_medium=blog&utm_campaign=ios-scalable-ui))
- Xcode 9.0 or later
- iOS device with minimum iOS 10.0
- A basic understanding of iOS development
- CocoaPods

# Setup

Create an iOS project in Xcode, then install the CocoaPod AgoraUIKit_iOS. This pod contains some useful classes that make the setup of our project and utilisation of the Agora SDK much easier, although it is by no means a requirement of streaming multiple channels.

```ruby
target 'Your App' do
  pod 'AgoraRtcEngine_iOS', '3.3.0'
end
```

Run `pod init`, and open the .xcworkspace file to get started.


# Connect to Agora

As an initial step in this app, we will request permissions for accessing the camera and microphone, to get that out of the way.

First, add both [NSCameraUsageDescription](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/plist/info/NSCameraUsageDescription) and [NSMicrophoneUsageDescription](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW25) to `Info.plist`, along with text descriptions. See [here](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/requesting_authorization_for_media_capture_on_ios) for more information on these, along with code samples of how to request and get authorisation states.

Next we are going to get connected to Agora using the already installed SDK. Import `AgoraRtcKit` at the top of your swift file to get started, then add the following code to your ViewController:

```swift
class ViewController: UIViewController {
    /// local user ID, initially set as zero.
    var myUserID: UInt = 0
    
    /// videoUsers is a list of all joined members
    var videoUsers: [UInt] = []
    /// usersCanvasMap finds the AgoraRtcVideoCanvas for a user ID
    var usersCanvasMap: [UInt: AgoraRtcVideoCanvas] = [:]

    /// collectionView will display our camera streams later
    var collectionView: UICollectionView?
    /// agkit defines our AgoraRtcEngineKit
    var agkit: AgoraRtcEngineKit {
        // the next line will fail if ViewController
        // does not have the AgoraRtcEngineDelegate protocol
        let agoraEngine = AgoraRtcEngineKit.sharedEngine(
            withAppId: "<#App ID#>",
            delegate: self
        )
        agoraEngine.enableVideo()
        // We are using the live broadcasting mode for this example
        agoraEngine.setChannelProfile(.liveBroadcasting)
        agoraEngine.setClientRole(.broadcaster)
        // dual stream mode is essential for scaling this application
        agoraEngine.enableDualStreamMode(true)
        agoraEngine.setParameters("""
          { "che.video.lowBitRateStreamParameter": {
            "width":160,"height":120,"frameRate":5,"bitRate":45
          }}
        """)
        return agoraEngine
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the next line once you get to the UI layout section
        // self.setupViews()
        // Connect to a channel named "test"
        self.agkit.joinChannel(
            byToken: nil, channelId: "test", info: nil, uid: 0
        ) { _, uid, _ in
            // set the user ID that Agora has assigned this user
            self.myUserID = uid
        }
    }
}
```

In the above code snippet we set up the Agora engine in with dual stream mode enabled, and the low-bitrate stream being very small and only 5 frames per second. This is the key part of making our app scalable to 17 users. A lower bitrate means less traffic will be coming in for many of the users streaming to us and we can optimise which users take up more badwidth.

Now we will add some of the delegate methods, which will keep track of our and others state in the Agora RTC Channel:

```swift
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
                // One canvas is created for each remote user
                let newCanvas = AgoraRtcVideoCanvas()
                newCanvas.uid = uid
                newCanvas.view = UIView()
                // Records of each user's canvas is added
                self.usersCanvasMap[uid] = newCanvas
                // userIDs are kept in an array, because the
                // order of a dictionary is not guaranteed.
                self.videoUsers.append(uid)
                self.agkit.setupRemoteVideo(newCanvas)
                self.collectionView?.reloadData()
            } else {
                usersCanvasMap[uid]?.view?.isHidden = false
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
```

Above we are using a list of user IDs to keep track of all users whose videos are currently streaming to us, and creating canvases to render all the video streams. We are also calling `self.collectionView?.reloadData()` whenever the items in `videoUsers` and `usersCanvasMap` change, to update the UI once it is created below.

However, we are missing our local user stream, add the following to the `joinChannel` callback:

```swift
self.videoUsers.append(self.myUserID)
let localCanvas = AgoraRtcVideoCanvas()
localCanvas.uid = self.myUserID
localCanvas.view = UIView()
self.usersCanvasMap[self.myUserID] = localCanvas
self.agkit.setupLocalVideo(localCanvas)
self.collectionView?.reloadData()
```

In the next section, we will see how to take those video canvases to display them in a UICollectionView, and choose which users are assigned the higher or lower quality streams.

# Set Up the UI for Scale

There will be only one screen to our application, where all the streamers in the channel will be shown.

We start by adding a UICollectionView, which will contain all our video streams and scroll through them vertically. For this example we will have it fill the entire screen, leaving room at the bottom for some simple buttons for pausing the camera, muting the microphone, etc.

```swift
extension ViewController {
    func setupViews() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        
        // Each collection view item will be a square, which is
        // just a little bit smaller than half the width
        // of our parent view.
        flowLayout.itemSize = CGSize(
            width: self.view.bounds.width / 2 - 40,
            height: self.view.bounds.width / 2 - 40
        )
        flowLayout.sectionInset = UIEdgeInsets(
            top: 10, left: 10, bottom: 10, right: 10
        )
        let scrollView = UICollectionView(
            frame: .zero, collectionViewLayout: flowLayout
        )
        scrollView.frame = self.view.bounds

        // leaving room for buttons at the bottom
        scrollView.frame.size.height -= 50
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        self.view.addSubview(scrollView)
        self.collectionView = scrollView
    }
}
```

With this UICollectionView, we are going to define a custom `UICollectionViewCell`, and make sure to register it with the collection view. We will also set the dataSource and delegate for this UICollectionView.

```swift
/// Item in the collection view to contain the user's video feed.
class AgoraCollectionItem: UICollectionViewCell {
    /// View for the video frame.
    var canvas: AgoraRtcVideoCanvas?

    var uid: UInt? { self.canvas?.uid }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .systemGray
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// Add to the first snippet
extension ViewController {
    // ...
    
    func setupViews() {
        // ...
        scrollView.register(
            AgoraCollectionItem.self,
            forCellWithReuseIdentifier: "collectionItem"
        )
        scrollView.dataSource = self
        scrollView.delegate = self
        // ...
    }
    // ...
}
```

Above the delegate and dataSource have been set, as well as AgoraCollectionItem being declared and registered with the identifier "collectionItem".

Next we set the dataSource protocol to the viewController. There are two required methods in the `UICollectionViewDataSource` protocol; one for declaring the number of items in a section, and one for getting an instance of a cell. We only have one section, so just return the videoUsers.count for the number of items, and dequeue a reusable cell for the other method. This either creates a new cell or fetches a recycled one from the UICollectionView class instance:

```swift
extension ViewController: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        self.videoUsers.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(
            withReuseIdentifier: "collectionItem", for: indexPath
        ) as! AgoraCollectionItem
    }
}
```

Using two delegate methods from `UICollectionViewDelegate`, `willDisplay` and `didEndDisplaying`, we can determine which cell is on screen at any time, and thus base what bitrate to set the videos to:

```swift
extension ViewController: UICollectionViewDelegate {
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
        // set the cell's new canvas and set the view
        agoraCell.canvas = canvas
        agoraCell.addSubview(canvasView)
        canvasView.frame = agoraCell.bounds
        canvasView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        if videoUID != self.myUserID {
            // if not local user, set the stream to high quality
            self.agkit.setRemoteVideoStream(videoUID, type: .high)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let agoraCell = cell as? AgoraCollectionItem,
              let userID = agoraCell.canvas?.uid else {
            fatalError("cell is not agoracollectionitem")
        }
        // release rendering camera view from its parent
        agoraCell.canvas?.view?.removeFromSuperview()
        agoraCell.canvas = nil
        if userID != self.myUserID {
            // cell is moving off screen, only receive low bitrate
            // from this remote user.
            self.agkit.setRemoteVideoStream(userID, type: .low)
        }
    }
}
```

This is the most important part of this example. Ensuring that we only receive a high quality stream for users who are on screen means that we are optimising the bandwidth our device is capable of, by prioritising the most relevant streams.

At this point, we are connected to the channel and all our video feeds will appear in a scrolling grid formation, with a small gap at the bottom, where a button will be placed:

![img](https://cdn-images-1.medium.com/max/800/1*qnwofZO-Ty4mRfXF_ouwhQ.jpeg)

# Leaving the Channel

Let's add a button at the bottom of our page to leave and then re-join the call.

```swift
extension ViewController {
    func addJoinLeave() {
    
        // Create and style the button
        let btn = UIButton(type: .roundedRect)
        btn.setTitle("Leave", for: .normal)
        btn.backgroundColor = .systemRed
        btn.backgroundColor = .secondarySystemBackground
        btn.layer.cornerRadius = 10

        // set the button action
        btn.addTarget(
            self, action: #selector(leaveChannel),
            for: .touchUpInside
        )

        // Positioning the button
        self.view.addSubview(btn)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(
            equalTo: self.view.safeAreaLayoutGuide.widthAnchor
        ).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        btn.bottomAnchor.constraint(
            equalTo: self.view.safeAreaLayoutGuide.bottomAnchor
        ).isActive = true

        // reference to leaveButton to be added to ViewController
        self.leaveButton = btn
    }
}
```

When leaving the channel; we need to clear all the canvases and the views they are sending video frames to, remove them from the UICollectionView, as well as telling the Agora Engine that we wish to leave the channel. This is an example of that logic in this case:

```swift
extension ViewController {
    @objc func leaveChannel() {
        if self.agkit.leaveChannel() == 0 {
            for (_, item) in usersCanvasMap.enumerated() {
                item.value.view?.removeFromSuperview()
                item.value.view = nil
            }
            usersCanvasMap.removeAll()
            self.videoUsers.removeAll()
            self.collectionView?.reloadData()

            self.leaveButton?.isHidden = true
        }
    }
}
```

![img](https://cdn-images-1.medium.com/max/1200/1*V-g06VcRg1pcvZ7ecv9_vA.jpeg)

# Testing

You now have a video chat application that can scale to up to 17 users by optimising settings for incoming streams.

You can find a complete application using all of the above code on GitHub:

[**AgoraIO-Community/Agora-ScalableUI-iOS**
*Contribute to AgoraIO-Community/Agora-ScalableUI-iOS development by creating an account on GitHub.*github.com](https://github.com/AgoraIO-Community/Agora-ScalableUI-iOS)

## Other Resources

For more information about building applications using Agora.io SDKs, take a look at the[ Agora Video Call Quickstart Guide](https://docs.agora.io/en/Video/start_call_ios?platform=iOS&utm_source=medium&utm_medium=blog&utm_campaign=real-time-messaging-video-dynamic-channels) and[ Agora API Reference](https://docs.agora.io/en/Video/API Reference/oc/docs/headers/Agora-Objective-C-API-Overview.html?utm_source=medium&utm_medium=blog&utm_campaign=real-time-messaging-video-dynamic-channels).

I also invite you to[ join the Agoira.io Developer Slack community](http://bit.ly/2IWexJQ).