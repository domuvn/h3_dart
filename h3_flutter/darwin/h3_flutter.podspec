#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint h3_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'h3_flutter'
  s.version          = '0.7.0'
  s.summary          = 'H3 Flutter plugin'
  s.description      = <<-DESC
A Flutter plugin providing FFI bindings to the H3 C library.
                       DESC
  s.homepage         = 'https://github.com/festelo/h3_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Ilia Beregovskii' => 'festeloqq@gmail.com' }
  s.source           = { :path => '.' }

  s.vendored_frameworks = 'Libs/h3.xcframework'
  s.preserve_paths = 'Libs/h3.xcframework/**/*'

  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.13'

  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
  }

  s.ios.pod_target_xcconfig = {
    # Flutter.framework does not contain a i386 slice.
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }

end
