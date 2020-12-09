#
# Be sure to run `pod lib lint VideoClap.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'VideoClap'
  s.version          = '0.1.0'
  s.summary          = 'A short description of VideoClap.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/lai001/VideoClap'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'lai001' => '1104698042@qq.com' }
  s.source           = { :git => 'https://github.com/lai001/VideoClap.git', :tag => s.version.to_s }
  
  s.dependency 'SwiftyBeaver'
  s.dependency 'lottie-ios'
  s.dependency 'SwiftyTimer'
  s.dependency 'SDWebImage'
  s.dependency 'SSPlayer'
  s.dependency 'SnapKit'
  
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'
  s.swift_version = '5.0'
  
  s.subspec 'Extension' do |ss|
    ss.source_files = 'VideoClap/Classes/Extension/**/*'
  end
  
  s.subspec 'Model' do |ss|
    ss.subspec 'Tracks' do |sss|
        sss.source_files = 'VideoClap/Classes/Model/Tracks/**/*'
    end
    ss.source_files = 'VideoClap/Classes/Model/**/*'
  end
  
  s.subspec 'Core' do |ss|
    ss.source_files = 'VideoClap/Classes/Core/**/*'
  end
  
  s.subspec 'Protocol' do |ss|
    ss.source_files = 'VideoClap/Classes/Protocol/**/*'
  end

  s.subspec 'Utilities' do |ss|
    ss.source_files = 'VideoClap/Classes/Utilities/**/*'
  end
  
  s.subspec 'Transition' do |ss|
    ss.source_files = 'VideoClap/Classes/Transition/**/*'
  end
  
  s.subspec 'Trajectory' do |ss|
    ss.source_files = 'VideoClap/Classes/Trajectory/**/*'
  end
  
  s.subspec 'CustomFilter' do |ss|
    ss.source_files = 'VideoClap/Classes/CustomFilter/**/*'
  end
  
  s.subspec 'MetalLibs' do |ss|
    ss.source_files = 'VideoClap/Classes/MetalLibs/**/*.metal'
  end
  
  s.subspec 'AudioEffects' do |ss|
      ss.source_files = 'VideoClap/Classes/AudioEffects/**/*'
  end
  
  s.subspec 'UI' do |ss|
      ss.source_files = 'VideoClap/Classes/UI/**/*'
  end
  
  s.pod_target_xcconfig = {
    'MTL_COMPILER_FLAGS' => '-fcikernel',
    'MTLLINKER_FLAGS' => '-cikernel',
  }
  
#  s.source_files = 'VideoClap/Classes/**/*'
  
   s.resource_bundles = {
     'VideoClap' => ['VideoClap/Assets/*.mov']
   }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
