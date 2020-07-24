#
#  Be sure to run `pod spec lint CometDClient.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|
  spec.name         = "CometDClient"
  spec.version      = "1.1.0"
  spec.summary      = "Swift client for CometD"
  spec.description  = <<-DESC
  CometD is a scalable web event routing bus that allows you to write low-latency, server-side, event-driven web applications. Typical examples of such applications are stock trading applications, web chat applications, online games, and monitoring consoles.
                   DESC
  spec.homepage     = "https://cometd.org/"
  spec.license      = "MIT"
  spec.author       = { "Anthony GUIGUEN" => "anthony@insurlytech.com" }

  spec.platform     = :ios, "10.0"
  spec.source       = { :git => "https://github.com/Insurlytech/CometDClient-iOS.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources/**/*.swift"
  spec.exclude_files = "Classes/Exclude"
  spec.swift_version = '5.2'

  spec.framework  = "Foundation"
  spec.requires_arc = true

  spec.dependency "Starscream", "4.0.3"
  spec.dependency "SwiftyJSON", "~> 5.0"
  spec.dependency "XCGLogger", "~> 7.0.1"
end
