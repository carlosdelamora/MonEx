# MonEx

This application is for people to exchange (physical) currency directly with one another. The user can make an offer which will be online for everyone to see. Alternatively, it may browse existing offers created by other users. If someone is interested in an existing offer it may request it, or send a counteroffer trying to improve their return for their money. Once both parties agree on the amount to exchange they can proceed to see the exact location of each other. Moreover, once the agreement has been reached communication will be allowed through the app via text messages so the parties can agree on a location to meet.

## Installation

The code is written using Swift 3, you need to use Xcode 8.x in order to compile it. Run the command in terminal

```
git clone https://github.com/carlosdelamora/MonEx.git 

```

Open Xcode 8 and select _MonEx.xcworkspace_ from the repository you just cloned.

## Usage

In order to test the application you need to use an IOS device with IOS 10.2 or greater. It wont work as expected if you use the simulator because we have notifications. The application will take a couple of minutes to load on your device, give it time.

In order to enter the app you need to authenticate in one of the following ways

* email and password, an email verification will be sent, so you need access to the email account
* Facebook account
* gmail account

An alert view controller will pop asking for permission to use your location, and to receive notifications. It is important that you allow both in order for the application to run as expected. You will be asked to create a profile before you can start making offers or requests.

## License
Copyright © 2017 Carlos De la Mora. All rights reserved.
