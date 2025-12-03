require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = 'ExpoPhotos'
  s.version      = package['version']
  s.summary      = package['description']
  s.description  = package['description']
  s.license      = package['license']
  s.author       = package['author']
  s.homepage     = package['homepage']
  s.platform     = :ios, '15.0'
  s.swift_version = '5.9'
  s.source       = { git: package['repository'] || 'https://github.com/hortemo/expo-photos' }
  s.static_framework = true

  s.dependency 'ExpoModulesCore'
  s.dependency 'React-Core'
  s.dependency 'SDWebImageWebPCoder', '0.15.0'

  s.source_files = 'ios/**/*.{h,m,swift}'
  s.requires_arc = true
end
