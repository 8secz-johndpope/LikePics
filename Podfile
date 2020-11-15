use_frameworks!
platform :ios, '14.0'

def test_shared_pods
    pod 'Quick',         '~> 3.0.0'
    pod 'Nimble',        '~> 9.0.0'
end

target 'TBox' do
  pod 'LicensePlist', '~> 3.0.4'
  pod 'SwiftGen', '~> 6.0'
  pod 'Sourcery', '~> 1.0'

  target 'TBoxTests' do
    inherit! :search_paths
    test_shared_pods
  end
end

target 'Persistence' do
  pod 'RealmSwift', '~> 10.0.0'

  target 'PersistenceTests' do
    inherit! :search_paths
    test_shared_pods
  end
end

target 'Domain' do
  target 'DomainTests' do
    inherit! :search_paths
    test_shared_pods
  end
end

target 'ShareExtension' do
end

target 'TBoxUIKit' do
  pod 'Kingfisher', '~> 5.15.3'

  target 'TBoxUIKitTests' do
    inherit! :search_paths
    test_shared_pods
  end
end

target 'TBoxCore' do
  pod 'Erik', '~> 5.0.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
    end
  end
end

