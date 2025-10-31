Pod::Spec.new do |spec|
  spec.name         = "SynheartEmotion"
  spec.version      = "0.1.0"
  spec.summary      = "On-device emotion inference from biosignals (HR/RR) for iOS applications"
  spec.description  = <<-DESC
    SynheartEmotion is an on-device library that infers momentary emotions from 
    biosignals (heart rate and RR intervals) using WESAD-trained machine learning models.
    All processing happens locally for privacy with <5ms inference latency.
  DESC
  spec.homepage     = "https://github.com/synheart-ai/synheart-emotion"
  spec.license      = { :type => "MIT", :file => "../../LICENSE" }
  spec.author       = { "Israel Goytom" => "israel@synheart.ai", "Synheart AI" => "noreply@synheart.com" }
  
  spec.ios.deployment_target = "13.0"
  spec.osx.deployment_target = "10.15"
  spec.watchos.deployment_target = "6.0"
  spec.tvos.deployment_target = "13.0"
  
  spec.source       = { 
    :git => "https://github.com/synheart-ai/synheart-emotion.git",
    :tag => "#{spec.version}"
  }
  
  spec.source_files = "Sources/SynheartEmotion/**/*.swift"
  spec.swift_version = "5.0"
  
  spec.requires_arc = true
  
  spec.social_media_url = "https://synheart.ai"
end

