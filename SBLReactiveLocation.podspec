Pod::Spec.new do |s|
  s.name         = "SBLReactiveLocation"
  s.version      = "0.1.0"
  s.summary      = "A reactive wrapper around the CLLocationManager"

  s.description  = <<-DESC
                    A ReactiveCocoa based wrapper around the CLLocationManager of CoreLocation. The implementation tries to
                    stay as close as possible to the original CLLocationManager implementation
                    while exposing the updates that are traditionally handled by a
                    CLLocationManagerDelegate as RACSignals.
                   DESC

  s.homepage     = "https://github.com/sbl/SBLReactiveLocation"
  s.license      = "MIT"

  s.author             = { "Stephen Lumenta" => "stephen.lumenta@gmail.com" }
  s.social_media_url   = "http://twitter.com/bruitism"

  s.requires_arc = true
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/sbl/SBLReactiveLocation.git", :tag => "0.1.0" }

  s.source_files = "SBLReactiveLocation"
  s.dependency "ReactiveCocoa", "~> 2.3.1"
end
