# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

target 'CometDClient' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for CometDClient
  pod 'Starscream', '4.0.3'
  pod 'SwiftyJSON', '~> 5.0'
  pod 'XCGLogger', '~> 7.0.1'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = 'YES'
    end
  end
end
