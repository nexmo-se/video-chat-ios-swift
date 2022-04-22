//
//  RoomViewController.swift
//  Basic-Video-Chat
//
//  Created by iujie on 21/02/2022.
//  Copyright © 2022 tokbox. All rights reserved.
//

import UIKit
import OpenTok


// *** Fill in the backendURL for session creation, backend folder: ./backend ***
let backendURL = ""

let smallFrameHeight: CGFloat = 180;
let smallFrameWidth: CGFloat = 120;

let screenSize: CGRect = UIScreen.main.bounds;
let screenWidth = screenSize.width;
let screenHeight = screenSize.height;

let publisherTag = 1;
let subscriberTag = 2;

struct Session:Decodable {
    var apiKey:String = ""
    var sessionId:String = ""
    var token:String = ""
}

enum SessionError:Error {
    case noDataAvailable
    case canNotProcessData
}


class RoomViewController: UIViewController {
    
    @IBOutlet weak var muteMicButton: UIButton!
    
    @IBOutlet weak var videoButton: UIButton!
    
    @IBOutlet weak var controlButtonsStack: UIStackView!
    
    var currentSession = Session();
    
    lazy var bigFrame = CGSize(width: screenWidth, height: screenHeight);
    lazy var smallFrame = CGSize(width: smallFrameWidth, height: smallFrameHeight);
    lazy var initialSmallFramePosition = CGPoint(x:screenWidth - smallFrameWidth, y:screenHeight - smallFrameHeight - controlButtonsStack.frame.height)
    
    var bigFramePosition = CGPoint(x:0, y:0);
    
    lazy var tapGesture = UITapGestureRecognizer(target: self, action:  #selector(self.smallFrameClickAction))
    lazy var panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.smallFramePanAction))

    
    var roomName = String();
    lazy var session: OTSession = {
        return OTSession(apiKey: currentSession.apiKey, sessionId: currentSession.sessionId, delegate: self)!
    }()
    
    lazy var publisher: OTPublisher = {
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        return OTPublisher(delegate: self, settings: settings)!
    }()
    
    
    var subscriber: OTSubscriber?
    var error: OTError?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        controlButtonsStack.backgroundColor = .gray.withAlphaComponent(0.6);
        controlButtonsStack.layer.zPosition = 2;
         generateSession() {result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let session):
                self.currentSession = session
                print("apitoken: \(session.token)");
                self.doConnect()
            }
        }

    }
    
    func generateSession(completion: @escaping (Result<Session, SessionError>) -> Void) {
        let url = URL(string: "\(backendURL)/session/\(roomName)")!

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in

            guard let sessionData = data, error == nil else {
                completion(.failure(SessionError.noDataAvailable))
                return
            }
            do {
                let decoder = JSONDecoder()
                let sessionResponse = try decoder.decode(Session.self, from: sessionData)
                completion(.success(sessionResponse))
            }
            catch let jsonError as NSError {
                print("JSON decode failed: \(jsonError.localizedDescription)")
                completion(.failure(SessionError.canNotProcessData))
            }
        }
        task.resume()
    }

    /* Toggle action button only if user tap on big screen*/
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        if ((touch.view?.frame.size) == smallFrame) {
            return;
        }
        if (self.controlButtonsStack.frame.origin.y >= screenHeight) {
            UIView.animate(withDuration: 0.5, animations: {() -> Void in
                self.controlButtonsStack.transform = CGAffineTransform(translationX: 0, y: 0);
            })
        }
        else {
            UIView.animate(withDuration: 0.5, animations: {() -> Void in
                self.controlButtonsStack.transform = CGAffineTransform(translationX: 0, y:self.controlButtonsStack.frame.height + 100);
            })
        }
    }

    /* Swap pubsliher and subscriber screen size*/
    @objc func smallFrameClickAction(sender : UITapGestureRecognizer) {
        if (sender.view!.tag == publisherTag) {
            let currentSmallScreenPosition = publisher.view?.frame.origin;
            if let pubView = publisher.view {
                pubView.frame.size = bigFrame;
                pubView.frame.origin = bigFramePosition
                view.sendSubviewToBack(pubView);

                pubView.removeGestureRecognizer(tapGesture)
                pubView.removeGestureRecognizer(panGesture)

            }
            
            if let subsView = subscriber?.view {
                subsView.frame.size = smallFrame;
                subsView.frame.origin = currentSmallScreenPosition!;
                view.bringSubviewToFront(subsView);
                subsView.addGestureRecognizer(tapGesture)
                subsView.addGestureRecognizer(panGesture)
            }
        }
        else if (sender.view!.tag == subscriberTag){
            let currentSmallScreenPosition = subscriber?.view?.frame.origin;
            
            if let pubView = publisher.view {
                pubView.frame.size = smallFrame;
                pubView.frame.origin = currentSmallScreenPosition!;
                view.bringSubviewToFront(pubView);
                pubView.addGestureRecognizer(tapGesture)
                pubView.addGestureRecognizer(panGesture)
            }
            
            if let subsView = subscriber?.view {
                subsView.frame.size = bigFrame;
                subsView.frame.origin = bigFramePosition

                view.sendSubviewToBack(subsView);
                subsView.removeGestureRecognizer(tapGesture)
                subsView.removeGestureRecognizer(panGesture)
            }
        }
    }

    @objc func smallFramePanAction(sender : UIPanGestureRecognizer) {

        if (sender.state == .began || sender.state == .changed) {
            let translation = sender.translation(in: sender.view)
            let changedX = (sender.view?.center.x)! + translation.x
            let changedY = (sender.view?.center.y)! + translation.y
            sender.view?.center = CGPoint(x:changedX, y:changedY)
        }
        if (sender.state == .ended) {
            let translation = sender.translation(in: sender.view)
            let changedX = (sender.view?.center.x)! + translation.x
            let changedY = (sender.view?.center.y)! + translation.y
            
            var xPosition = screenWidth - smallFrameWidth/2;
            var yPosition = changedY;
            
            if (changedX < screenWidth/2) {
                xPosition = smallFrameWidth/2;
            }
            if (changedY > (screenHeight - (smallFrameHeight)/2)) {
                yPosition = screenHeight - (smallFrameHeight)/2
            }
            if (changedY < (smallFrameHeight)/2) {
                yPosition = (smallFrameHeight)/2;
            }
 
            UIView.animate(withDuration: 0.15, animations: {() -> Void in
                sender.view?.center = CGPoint(x:xPosition, y:yPosition)
            })
            
        }
        sender.setTranslation(CGPoint.zero, in: sender.view)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let enterRoomViewController = segue.destination as! EnterRoomViewController
        enterRoomViewController.modalPresentationStyle = .fullScreen
    }
 
    /**
     * Asynchronously begins the session connect process. Some time later, we will
     * expect a delegate method to call us back with the results of this action.
     */
    fileprivate func doConnect() {
        defer {
            processError(error)
        }
        
        session.connect(withToken: self.currentSession.token, error: &error)
    }
    
    /**
     * Sets up an instance of OTPublisher to use with this session. OTPubilsher
     * binds to the device camera and microphone, and will provide A/V streams
     * to the OpenTok session.
     */
    fileprivate func doPublish() {
        defer {
            processError(error)
        }
        
        session.publish(publisher,error: &error)
        
        if let pubView = publisher.view {
            pubView.frame.size = smallFrame;
            pubView.frame.origin = initialSmallFramePosition;

            view.addSubview(pubView)
            pubView.addGestureRecognizer(tapGesture);
            pubView.addGestureRecognizer(panGesture);
            pubView.tag = publisherTag;
        }
        // hide control buttons
        UIView.animate(withDuration: 0.5, animations: {() -> Void in
            self.controlButtonsStack.transform = CGAffineTransform(translationX: 0, y: self.controlButtonsStack.frame.height + 100);

        })
    }
    
    /**
     * Instantiates a subscriber for the given stream and asynchronously begins the
     * process to begin receiving A/V content for this stream. Unlike doPublish,
     * this method does not add the subscriber to the view hierarchy. Instead, we
     * add the subscriber only after it has connected and begins receiving data.
     */
    fileprivate func doSubscribe(_ stream: OTStream) {
        defer {
            processError(error)
        }
        subscriber = OTSubscriber(stream: stream, delegate: self)
        
        session.subscribe(subscriber!, error: &error)
    }
    
    fileprivate func cleanupSubscriber() {
        subscriber?.view?.removeFromSuperview()
        subscriber = nil
    }
    
    fileprivate func cleanupPublisher() {
        publisher.view?.removeFromSuperview()
    }
    
    fileprivate func processError(_ error: OTError?) {
        if let err = error {
            DispatchQueue.main.async {
                let controller = UIAlertController(title: "Error", message: err.localizedDescription, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(controller, animated: true, completion: nil)
            }
        }
    }

    @IBAction func sessiondisconnecterrorendCallButtonTapped(_ sender: Any) {
        session.disconnect(&error)
    }
    
    @IBAction func switchCameraButtonTapped(_ sender: Any) {
        if publisher.cameraPosition == .front {
                publisher.cameraPosition = .back
            } else {
                publisher.cameraPosition = .front
            }
    }
    
 
    @IBAction func muteButtonTapped(_ sender: Any) {
        publisher.publishAudio = !publisher.publishAudio
           
           let buttonImage: UIImage  = {
               if !publisher.publishAudio {
                   return #imageLiteral(resourceName: "icon-mute.png")
               } else {
                   return #imageLiteral(resourceName: "icon-unmute.png")
               }
           }()
           muteMicButton.setImage(buttonImage, for: .normal)
        
        if #available(iOS 15.0, *) {
            muteMicButton.configuration = .filled();
            muteMicButton.clipsToBounds = true;
            muteMicButton.layer.cornerRadius = 30;
            muteMicButton.configuration?.baseBackgroundColor = !publisher.publishAudio ? UIColor.systemRed : UIColor.systemGreen
        } else {
            // Fallback on earlier versions
            muteMicButton.backgroundColor = !publisher.publishAudio ? UIColor.systemRed : UIColor.systemGreen
        }
    }
    
    
    @IBAction func videoButtonTapped(_ sender: Any) {
        publisher.publishVideo = !publisher.publishVideo
           
           let buttonImage: UIImage  = {
               if !publisher.publishVideo {
                    return #imageLiteral(resourceName: "icon-no-video.png")
               } else {
                   return #imageLiteral(resourceName: "icon-video.png")
               }
           }()
        
        videoButton.setImage(buttonImage, for: .normal)
        
        if #available(iOS 15.0, *) {
            videoButton.configuration = .filled();
            videoButton.clipsToBounds = true;
            videoButton.layer.cornerRadius = 30;
            videoButton.configuration?.baseBackgroundColor = !publisher.publishVideo ? UIColor.systemRed : UIColor.systemGreen
        } else {
            // Fallback on earlier versions
            videoButton.backgroundColor = !publisher.publishVideo ? UIColor.systemRed : UIColor.systemGreen
        }
    }
    
}

// MARK: - OTSession delegate callbacks
extension RoomViewController: OTSessionDelegate {
    func sessionDidConnect(_ session: OTSession) {
        print("Session connected")
        doPublish()
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        print("Session disconnected")
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("Session streamCreated: \(stream.streamId)")
        if subscriber == nil {
            doSubscribe(stream)
        }
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("Session streamDestroyed: \(stream.streamId)")
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            cleanupSubscriber()
        }
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("session Failed to connect: \(error.localizedDescription)")
    }
    
}

// MARK: - OTPublisher delegate callbacks
extension RoomViewController: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        print("Publishing")
    }
    
    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        cleanupPublisher()
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            cleanupSubscriber()
        }
    }
    
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print("Publisher failed: \(error.localizedDescription)")
    }
}

// MARK: - OTSubscriber delegate callbacks
extension RoomViewController: OTSubscriberDelegate {
    func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
        if let subsView = subscriber?.view {
            if (publisher.view?.frame.size == bigFrame) {
                subsView.frame.size = smallFrame;
                subsView.frame.origin = initialSmallFramePosition;
                subsView.addGestureRecognizer(tapGesture);
                subsView.addGestureRecognizer(panGesture);
                view.addSubview(subsView)
            }
            else {
                subsView.frame.size = bigFrame;
                subsView.frame.origin = bigFramePosition;
                view.addSubview(subsView)
                view.sendSubviewToBack(subsView);
            }
 
            subsView.tag = subscriberTag;
        }
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("Subscriber failed: \(error.localizedDescription)")
    }
}
