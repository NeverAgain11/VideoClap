# VideoClap

[![CI Status](https://img.shields.io/travis/lai001/VideoClap.svg?style=flat)](https://travis-ci.org/lai001/VideoClap)
[![Version](https://img.shields.io/cocoapods/v/VideoClap.svg?style=flat)](https://cocoapods.org/pods/VideoClap)
[![License](https://img.shields.io/cocoapods/l/VideoClap.svg?style=flat)](https://cocoapods.org/pods/VideoClap)
[![Platform](https://img.shields.io/cocoapods/p/VideoClap.svg?style=flat)](https://cocoapods.org/pods/VideoClap)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

* iOS 9.0 or later
* Swift 5

## Installation

To install it, simply add the following line to your Podfile:

```ruby
pod 'VideoClap', :git => 'https://github.com/lai001/VideoClap.git', :commit => 'f141572a0be05f3d41fa5f721da50bc4c5b3d075'

def config_rule(new_rule, file_patterns, output_files, script)
  new_rule.name = "Files '#{file_patterns}' using Script"
  new_rule.compiler_spec = 'com.apple.compilers.proxy.script'
  new_rule.file_patterns = file_patterns
  new_rule.file_type = 'pattern.proxy'
  new_rule.is_editable = '1'
  new_rule.output_files = output_files
  new_rule.input_files = []
  new_rule.output_files_compiler_flags = []
  new_rule.script = script
  new_rule.run_once_per_architecture = '0'
end

def add_build_rule(target_name, project)
  project.targets.each do |target|
    if target.name == target_name
      puts "Updating #{target.name} rules"
      new_rule0 = project.new(Xcodeproj::Project::Object::PBXBuildRule)
      config_rule(new_rule0,
                  '*.ci.metal',
                  ["$(DERIVED_FILE_DIR)/${INPUT_FILE_BASE}.air"],
                  "xcrun metal -c -fcikernel \"${INPUT_FILE_PATH}\" -o \"${SCRIPT_OUTPUT_FILE_0}\"\n")
      new_rule1 = project.new(Xcodeproj::Project::Object::PBXBuildRule)
      config_rule(new_rule1,
                  '*.ci.air',
                  ["$(METAL_LIBRARY_OUTPUT_DIR)/$(INPUT_FILE_BASE).metallib"],
                  "xcrun metallib -cikernel \"${INPUT_FILE_PATH}\" -o \"${SCRIPT_OUTPUT_FILE_0}\"\n")
                  
      target.build_rules.append(new_rule0)
      target.build_rules.append(new_rule1)
      project.objects_by_uuid[new_rule0.uuid] = new_rule0
      project.objects_by_uuid[new_rule1.uuid] = new_rule1
      project.save()
    end
  end
end

post_install do |installer|
    add_build_rule("VideoClap", installer.pods_project)
end
```

## Author

lai001, 1104698042@qq.com

## License

VideoClap is available under the MIT license. See the LICENSE file for more info.
