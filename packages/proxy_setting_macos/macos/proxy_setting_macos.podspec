#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'proxy_setting_macos'
  s.version          = '0.0.0'
  s.summary          = 'MacOS implementation of the proxy_setting plugin.'
  s.description      = <<-DESC
  A macOS implementation of the url_launcher plugin.
                       DESC
  s.homepage         = 'https://github.com/ueki-tomohiro/proxy_setting/url_launcher_macos'
  s.license          = { :type => 'BSD', :file => '../LICENSE' }
  s.author           = { 'Flutter Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :http => 'https://github.com/ueki-tomohiro/proxy_setting/url_launcher_macos' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
  end

