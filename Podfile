platform :ios, '7.0'
xcodeproj 'SecureReader.xcodeproj'
source 'https://github.com/CocoaPods/Specs.git'

pod 'InAppSettingsKit', '~> 2.2'
pod 'YapDatabase/SQLCipher', '~> 2.6'
pod 'PureLayout', '~> 2.0'
pod 'Mantle', '~> 1.5'
pod 'FormatterKit/TimeIntervalFormatter', '~> 1.6'
pod 'wpxmlrpc', '~> 0.5'
pod 'HockeySDK', '~> 3.6'
pod 'SSKeychain', '~> 1.2'
pod 'PSTAlertController', :git => 'https://github.com/steipete/PSTAlertController.git', :commit => '68a1327dbf71a6d1b97a121352bc774f469abd14'
pod 'VENTouchLock', '~> 1.0'

pod 'MWFeedParser/NSString+HTML', '~> 1.0'

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