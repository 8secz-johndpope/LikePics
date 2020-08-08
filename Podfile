# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

def test_shared_pods
    pod 'Quick',         '~> 2.2.0'
    pod 'Nimble',        '~> 8.0.5'
end

target 'Persistence' do
  use_frameworks!

  pod 'RealmSwift', '~> 5.3.3'

  target 'PersistenceTests' do
    inherit! :search_paths
    test_shared_pods
  end

end

target 'Domain' do
  use_frameworks!

  target 'DomainTests' do
    inherit! :search_paths
    test_shared_pods
  end

end

target 'TBox' do
  use_frameworks!

  target 'TBoxTests' do
    inherit! :search_paths
    test_shared_pods
  end

end
