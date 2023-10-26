# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

def common_pods
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Noteshelf
  pod 'Firebase/RemoteConfig'
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'

  #common_pods
  pod 'Reachability'
#  pod 'Evernote-SDK-iOS', :git => 'https://github.com/Evernote/evernote-sdk-mac'
  pod 'SwiftLint'
  pod 'MSGraphMSALAuthProvider', :git => 'https://github.com/AkshayFT/msgraph-sdk-objc-auth'
  pod 'ZendeskSupportSDK'
  pod 'TPInAppReceipt'
end

target 'Noteshelf3' do
  common_pods
  pod 'GoogleMLKit/DigitalInkRecognition'
end
