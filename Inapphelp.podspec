
Pod::Spec.new do |s|
  s.name             = "Inapphelp"
  s.version          = "0.0.2"
  s.summary          = "In-app customer support framework for inapphelp.com help desk"
  s.description      = 'See inapphelp.io for more details'
  s.homepage         = "https://github.com/apps-m/inapphelp-ios"
  s.social_media_url = "https://twitter.com/inapphelp"
  s.license          = 'MIT'
  s.author           = { "Apps-m" => "ios@inapphelp.com" }
  s.platform         = :ios, '7.0'
  s.source           = { :git => "https://github.com/apps-m/inapphelp-ios.git", :tag => "0.0.2", :submodules => true }
  s.resources        = ['Resources/*.png','Resources/*.storyboard']
  s.dependency         'AFNetworking', '~> 2.0'
  s.dependency         'JCNotificationBannerPresenter', '~> 1.1.2'
  s.frameworks       = 'UIKit', 'CoreGraphics'
  s.requires_arc     = true

  s.subspec 'Util' do |ss|
    ss.source_files  = 'Classes/Util/*.{h,m}'
  end

  s.subspec 'Core' do |ss|
    ss.dependency 'Inapphelp/Util'
    ss.source_files  = 'Classes/Core/*.{h,m}'
  end

  s.subspec 'UI' do |ss|
    ss.dependency 'Inapphelp/Util'
    ss.dependency 'Inapphelp/Core'
    ss.source_files = 'Classes/UI/*.{h,m}'
  end

end
