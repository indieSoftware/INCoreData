Pod::Spec.new do |spec| 
  spec.name         = "INCoreData"
 spec.version = "2.0.0" # auto-generated
 spec.swift_versions = ['5.7'] # auto-generated
  spec.summary      = "That library supports dynamic CoreData features."
  spec.homepage     = "https://github.com/indieSoftware/INCoreData"
  spec.author       = { "Sven Korset" => "sven.korset@indie-software.com" }
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.ios.deployment_target = "15.0"
  spec.source       = { :git => "https://github.com/indieSoftware/INCoreData.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources/INCoreData/**/*.{swift}"
  spec.module_name = 'INCoreData'
  spec.dependency 'INCommons'
end
