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

let publisherHeight = 180
let publisherWidth = 120

let screenSize: CGRect = UIScreen.main.bounds
let screenWidth = screenSize.width;
let screenHeight = screenSize.height

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
        
        let xPosition = screenWidth - CGFloat(publisherWidth);
        let yPosition = screenHeight - CGFloat(publisherHeight) - controlButtonsStack.frame.size.height
        
        if let pubView = publisher.view {
            pubView.frame = CGRect(x: Int(xPosition), y: Int(yPosition), width: publisherWidth, height: publisherHeight)
            pubView.layer.zPosition = 1;
            view.addSubview(pubView)
        }
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
            subsView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight - controlButtonsStack.frame.size.height)
            view.addSubview(subsView)
        }
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("Subscriber failed: \(error.localizedDescription)")
    }
}
