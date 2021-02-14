# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'InstaClone' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for InstaClone
	pod 'Firebase/Core'
	pod 'Firebase/Database'
	pod 'Firebase/Firestore'
	pod 'Firebase/Storage'
	pod 'Firebase/Auth'
	pod 'ActiveLabel'
	pod 'SDWebImage'
	pod 'JGProgressHUD','~>2.0.3'
	pod 'YPImagePicker'
  target  'InstaCloneTests' do
          inherit! :search_paths
          pod 'Firebase'
          end
end

post_install do |installer|
 installer.pods_project.targets.each do |target|
  target.build_configurations.each do |config|
   config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
  end
 end
end
