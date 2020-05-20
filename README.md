# CometDClient-iOS
CometD is a scalable web event routing bus that allows you to write low-latency, server-side, event-driven web applications. Typical examples of such applications are stock trading applications, web chat applications, online games, and monitoring consoles.

## Features

### Import the framework

First thing is to import the framework. See the Installation instructions on how to add the framework to your project.

```swift
import CometDClient
```
## Installation

### CocoaPods

Check out [Get Started](http://cocoapods.org/) tab on [cocoapods.org](http://cocoapods.org/).

To use CometDClient in your project add the following 'Podfile' to your project

  source 'https://github.com/CocoaPods/Specs.git'
  platform :ios, '10.0'
  use_frameworks!

    pod 'CometDClient', '~> 1.0.0'

Then run:

    pod install

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

Once you have your Swift package set up, adding CometDClient as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .Package(url: "https://github.com/Insurlytech/CometDClient-iOS.git", majorVersion: 1)
]
```

## License

CometDClient is licensed under the MIT License.

## Contact

### Anthony GUIGUEN
* https://github.com/anthonyGuiguen
* anthony@insurlytech.com

### Steven WATREMEZ
* https://github.com/StevenWatremez
* steven@insurlytech.com
