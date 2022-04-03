#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'proxy_setting_ios'
  s.version          = '0.0.2'
  s.summary          = 'iOS implementation of the detect_proxy_setting plugin.'
  s.description      = <<-DESC
  An iOS implementation of the detect_proxy_setting plugin.
                       DESC
  s.homepage         = 'https://github.com/ueki-tomohiro/proxy_setting/packages/proxy_setting_ios'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Tomohiro Ueki' => 'tomohiro.ueki.com' }
  s.source           = { :http => 'https://github.com/ueki-tomohiro/proxy_setting/packages/proxy_setting_ios' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end

