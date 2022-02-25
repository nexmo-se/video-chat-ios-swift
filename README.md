Video Chat iOS Swift Sample App
===============================

This application shows how to build a video chat app with OpenTok iOS SDK.

## Prerequisites

- Node.js v16.14+
- XCode v13.2.1+
- iOS v15+

Quick Start
-----------
  Backend:
   1. Go to backend folder: `cd backend`

   2. Run `npm install` to install all dependencies from NPM.

   3. copy the `env.example` file to `.env` and fill the variables needed

   4. Run `node .` to execute node index.js file

   5. Open new terminal, run `ngrok http $SERVER_PORT` to expose local development server.


   Frontend:
   1. Install CocoaPods as described in [CocoaPods Getting Started](https://guides.cocoapods.org/using/getting-started.html#getting-started).
 
   2. In Terminal, type `pod install`.
 
   3. Reopen your project in Xcode using the new `.xcworkspace` file.
 
   4. In the RoomViewController.swift file, replace the backendURL variable empty strings
    with the URL created by ngrok:
 
     ```swift
    // *** Fill in the backendURL for session creation, backend folder: ./backend ***
    //  let backendURL = ""
     ```
 
   5. Use Xcode to build and run the app on an iOS simulator or device.

   6. After you enter a room name, it connects to an OpenTok session and
   publishes an audio-video stream from your device to the session.

   7. Run the app on a second client. You can do this by deploying the app to an
   iOS device and testing it in the simulator at the same time. Or you can use
   the browser_demo.html file to connect in a browser (see the following
   section).

   When the second client connects, it also publishes a stream to the session,
   and both clients subscribe to (view) each other’s stream.


Application Notes
-------------------

   To add a second publisher (which will display as a subscriber in your emulator), either run the app a second time in an iOS device or use the OpenTok Playground to connect to the session in a supported web browser (Chrome, Firefox, or Internet Explorer 10-11) by following the steps below:

   1. Go to [OpenTok Playground](https://tokbox.com/developer/tools/playground) (must be logged into your [Account](https://tokbox.com/account))
   2. Select the **Join existing session** tab
   3. Click "Yes" for **Have an existing token?** section
   3. Copy the apiToken value from Xcode debug area in the **Token** input field
   4. Click **Join Session**
   5. On the next screen, click **Connect**, then click **Publish Stream**
   6. You can adjust the Publisher options (not required), then click **Continue** to connect and begin publishing and subscribing


Configuration Notes
-------------------

*   You can test in the iOS Simulator or on a supported iOS device. However, the
    XCode iOS Simulator does not provide access to the camera. When running in
    the iOS Simulator, an OTPublisher object uses a demo video instead of the
    camera.
