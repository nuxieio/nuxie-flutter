Pod::Spec.new do |s|
  s.name             = 'nuxie_flutter_native'
  s.version          = '0.1.0'
  s.summary          = 'Native iOS implementation for nuxie_flutter'
  s.description      = <<-DESC
Native iOS implementation for nuxie_flutter.
                       DESC
  s.homepage         = 'https://github.com/nuxieio/nuxie-flutter'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Nuxie' => 'support@nuxie.io' }
  s.source           = { :path => '.' }
  s.source_files     = 'nuxie_flutter_native/Sources/nuxie_flutter_native/**/*'
  s.dependency       'Flutter'
  s.platform         = :ios, '15.0'
  s.swift_version    = '5.9'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
