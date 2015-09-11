platform :ios, '8.0'
# use_frameworks!     # Blocking on GCDWebServer and DZReadability dynamic framework issues
xcodeproj 'SecureReader.xcodeproj'
source 'https://github.com/CocoaPods/Specs.git'

pod 'InAppSettingsKit', '~> 2.2'
pod 'YapDatabase/SQLCipher', '~> 2.7'
pod 'PureLayout', '~> 3.0'
pod 'Mantle', '~> 2.0'
pod 'FormatterKit/TimeIntervalFormatter', '~> 1.6'
pod 'wpxmlrpc', '~> 0.5'
pod 'HockeySDK-Source', '~> 3.7'
pod 'SSKeychain', '~> 1.2'
pod 'PSTAlertController', :git => 'https://github.com/steipete/PSTAlertController.git', :commit => '68a1327dbf71a6d1b97a121352bc774f469abd14'
pod 'VENTouchLock', '~> 1.0'
pod 'KVOController', '~> 1.0'
pod 'MRProgress', '~> 0.8'
pod 'DZReadability', '~> 0.2'
pod 'JSQMessagesViewController', '~> 7.1'
pod 'VTAcknowledgementsViewController', '~> 0.14'
pod 'MWFeedParser/NSString+HTML', '~> 1.0'
pod 'JTSImageViewController', '~> 1.4'

# Tor support
pod 'CPAProxy', :path => 'Submodules/CPAProxy/CPAProxy.podspec'

# Our RSS parser
pod 'RSSAtomKit', :path => 'Submodules/RSSAtomKit/RSSAtomKit.podspec'

# IOCipher
pod 'IOCipher/GCDWebServer', :path => 'Submodules/IOCipher/IOCipher.podspec'

# Swipeable table cells with action buttons
pod 'SWTableViewCell', '~> 0.3.7'

# Swipeable media views
pod 'SwipeView', '~> 1.3'

# SVG file support (onboarding illustrations)
pod 'SVGgh', '~> 1.1'

target "SecureReaderTests" do
    pod 'IOCipher/GCDWebServer', :path => 'Submodules/IOCipher/IOCipher.podspec'
    pod 'URLMock', '~> 1.2.3'
end
