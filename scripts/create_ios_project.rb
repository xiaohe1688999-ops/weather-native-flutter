#!/usr/bin/env ruby
# 一次性生成可复现的 Xcode 项目；生成的项目文件纳入版本控制。
require 'xcodeproj'
require 'fileutils'

root = File.expand_path('..', __dir__)
destination = File.join(root, 'ios-host/WeatherHost.xcodeproj')
abort 'Project exists; remove it explicitly before regenerating.' if File.exist?(destination)
project = Xcodeproj::Project.new(destination)
target = project.new_target(:application, 'WeatherHost', :ios, '15.0')
tests = project.new_target(:ui_test_bundle, 'WeatherHostUITests', :ios, '15.0')
tests.add_dependency(target)
test_group = project.main_group.new_group('WeatherHostUITests', 'WeatherHostUITests')
tests.source_build_phase.add_file_reference(test_group.new_file('WeatherHostUITests.swift'))
tests.build_configurations.each do |config|
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'dev.weather.nativehost.uitests'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['TEST_TARGET_NAME'] = 'WeatherHost'
end
group = project.main_group.new_group('WeatherHost', 'WeatherHost')
Dir.glob(File.join(root, 'ios-host/WeatherHost/*.swift')).sort.each do |path|
  target.source_build_phase.add_file_reference(group.new_file(File.basename(path)))
end

[
  ['WeatherCore', 'WeatherCore'],
  ['../weather_flutter/build/ios/SwiftPackages/FlutterNativeIntegration', 'FlutterNativeIntegration']
].each do |path, name|
  package = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
  package.relative_path = path
  project.root_object.package_references << package
  product = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  product.package = package
  product.product_name = name
  target.package_product_dependencies << product
  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.product_ref = product
  target.frameworks_build_phase.files << build_file
end

project.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
end
target.build_configurations.each do |config|
  settings = config.build_settings
  settings['SWIFT_VERSION'] = '5.0'
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'dev.weather.nativehost'
  settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
  settings['CURRENT_PROJECT_VERSION'] = '1'
  settings['MARKETING_VERSION'] = '1.0'
  settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  settings['INFOPLIST_FILE'] = 'WeatherHost/Info-$(CONFIGURATION).plist'
  settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  settings['CODE_SIGN_STYLE'] = 'Automatic'
  settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
  settings['FLUTTER_SWIFT_PACKAGE_OUTPUT'] = '$(SRCROOT)/../weather_flutter/build/ios/SwiftPackages'
  settings['FLUTTER_APPLICATION_PATH'] = '$(SRCROOT)/../weather_flutter'
  settings['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks']
end
phase = target.new_shell_script_build_phase('Build Flutter')
phase.shell_script = '/bin/sh "$FLUTTER_SWIFT_PACKAGE_OUTPUT/Scripts/flutter_integration.sh" assemble'
phase.input_file_list_paths = ['$(FLUTTER_SWIFT_PACKAGE_OUTPUT)/Scripts/FlutterAssembleInputs.xcfilelist']
phase.always_out_of_date = '1'
project.save

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.add_test_target(tests)
scheme.set_launch_target(target)
action = Xcodeproj::XCScheme::ExecutionAction.new(nil, :shell_script)
content = Xcodeproj::XCScheme::ShellScriptActionContent.new
content.title = 'Prepare Flutter'
content.script_text = '/bin/sh "$FLUTTER_SWIFT_PACKAGE_OUTPUT/Scripts/flutter_integration.sh" prebuild'
content.buildable_reference = Xcodeproj::XCScheme::BuildableReference.new(target)
action.action_content = content
scheme.build_action.add_pre_action(action)
scheme.launch_action.build_configuration = 'Debug'
scheme.archive_action.build_configuration = 'Release'
scheme.save_as(destination, 'WeatherHost', true)
puts destination
