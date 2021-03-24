#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_native_admob'
  s.version          = '0.0.1'
  s.summary          = 'Admob native ad plugin for Flutter'
  s.description      = <<-DESC
Admob native ad plugin for Flutter
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.ios.deployment_target = '10.0'
  s.dependency 'Flutter'
  s.dependency 'Google-Mobile-Ads-SDK'
  s.dependency 'mopub-ios-sdk', '5.15.0'
  s.dependency 'FBAudienceNetwork'
  s.dependency 'MoPub-FacebookAudienceNetwork-Adapters', '6.2.1.0'
  s.dependency 'MoPub-AdMob-Adapters', '7.69.0.1'
  s.dependency 'PureLayout'
  s.static_framework = true
end

