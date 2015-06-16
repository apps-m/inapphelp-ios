
Pod::Spec.new do |s|
  s.name             = "Inapphelp"
  s.version          = '0.0.6'
  s.summary          = "In-app customer support framework"
  s.description      = 'In-app customer support framework for inapphelp.com help desk. See inapphelp.io for more details'
  s.homepage         = "https://github.com/apps-m/inapphelp-ios"
  s.social_media_url = "https://twitter.com/inapphelp"
  s.license          = 'MIT'
  s.author           = { "Apps-m" => "ios@apps-m.ru" }
  s.platform         = :ios, '7.0'
  s.source           = { :git => "https://github.com/apps-m/inapphelp-ios.git", :tag => "0.0.6", :submodules => true }
  s.source_files     = 'Classes/*/*.{h,m}'
  s.resources        = ['Resources/*.png','Resources/*.storyboard']
  s.dependency         'AFNetworking', '~> 2.0'
  s.dependency         'JCNotificationBannerPresenter', '~> 1.1.2'
  s.frameworks       = 'UIKit', 'CoreGraphics'
  s.requires_arc     = true
end
