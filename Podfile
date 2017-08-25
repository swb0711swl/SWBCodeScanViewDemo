# Uncomment this line to define a global platform for your project
platform :ios, '9.0'
use_frameworks!

target 'SWBQRCodeScanDemo' do
  pod 'ReactiveCocoa', '~> 4.2.2'
pod 'Masonry'

post_install do |installer|
      installer.pods_project.targets.each do |target|
          target.build_configurations.each do |config|
              config.build_settings['SWIFT_VERSION'] = '2.3'
          end
      end
  end

end
