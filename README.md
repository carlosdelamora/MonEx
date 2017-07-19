# MonEx

This application is for people to exchange (physical) currency directly with one another. The user can make an offer which will be online for everyone to see. Alternatively, it may browse current offers created by other users. If someone is interested in a current offer, it may request it, or send a counter offer trying to improve their return for their money. Once both parties agree on the amount to exchange, they can proceed to see the exact location of each other. Moreover, once the users come to an agreement communication will be allowed through the app via text messages so the parties can agree on a location to meet.

## Installation

The code is written using Swift 3, you need to use Xcode 8.x in order to compile it. Run the command in terminal

```
git clone https://github.com/carlosdelamora/MonEx.git

```

Open Xcode 8 and select _MonEx.xcworkspace_ from the repository you just cloned.

## Usage

To test the application, you need to use an IOS device with IOS 10.2 or greater. MonEx won't work as expected if you use the Xcode simulator to test it. We have notifications that trigger actions in the application, and the simulator is incapable of receiving notifications. In fact, to test the application, we strongly advise for the use of two devices and two MonEx accounts.

The application contains a lot of functionalities therefore if will take a couple of minutes to load on your device, give it time.

To enter the app you need to authenticate in one of the following ways

* email and password, an email verification will be sent, so you need access to the email account
* Facebook account
* gmail account

An alert view controller will pop asking for permission to use your location and to receive notifications. It is important that you allow both for the application to run as expected. You will be asked to create a profile before you can start making offers or requests.

## License
Copyright © 2017 Carlos De la Mora. All rights reserved.

