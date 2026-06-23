#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint catapush_flutter_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'catapush_flutter_sdk'
  s.version          = '1.9.0'
  s.summary          = 'Official Catapush plugin for Flutter, supports Android and iOS platforms.'
  s.description      = <<-DESC
Catapush is a simple, reliable and scalable delivery API for transactional push notifications for websites and applications. Ideal for sending data-driven transactional notifications including targeted e-commerce and personalized one-to-one messages.
DESC
  s.homepage         = 'https://www.catapush.com/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Catapush' => 'info@catapush.com' }
  s.source           = { :path => '.' }
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.frameworks = 'SystemConfiguration','MobileCoreServices'

  s.source_files = 'Classes/**/*'
  s.dependency 'catapush-ios-sdk-pod', '2.2.5'
  s.static_framework = true
end
