Pod::Spec.new do |spec|
  spec.name = "INCoreData"
  spec.version = "1.0.0" # auto-generated
  spec.swift_version = "5.5.2" # auto-generated
  spec.summary = "That library supports dynamic CoreData features."
  spec.description = "Library INCoreData"
  spec.homepage = "https://github.com/indieSoftware/INCoreData"
  spec.license = 'MIT'
  spec.author = { "Sven Korset" => "sven.korset@indie-software.com" }
  spec.license = { :type => "MIT", :file => "LICENSE" }
  spec.ios.deployment_target = "15.0"
  spec.source = { :git => "https://github.com/indieSoftware/INCoreData.git", :tag => "1.0.0" }
  spec.source_files = "Sources/INCoreData/**/*.{swift}"
  spec.module_name = 'INCoreData'
end
