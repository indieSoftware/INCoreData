Pod::Spec.new do |spec| 
  spec.name         = "INCoreData"
  spec.version      = "1.0.3"
  spec.summary      = "That library supports dynamic CoreData features."
  spec.homepage     = "https://github.com/indieSoftware/INCoreData"
  spec.license      = "MIT"
  spec.author       = { "Sven Korset" => "sven.korset@indie-software.com" }
  spec.ios.deployment_target = "14.0"
  spec.source       = { :git => "https://github.com/indieSoftware/INCoreData.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources/INCoreData/**/*.{swift}"
  spec.public_header_files = "Sources/INCoreData/**/*.h"
end