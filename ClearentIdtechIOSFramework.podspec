#
#  Be sure to run `pod spec lint ClearentIdtechIOSFramework.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name          = "ClearentIdtechIOSFramework"
  s.version       = "4.0.36"
  s.summary       = "ClearentIdtechIOSFramework summary"
  s.homepage      = "http://api.clearent.com/swagger.html#!/Quest_API_Integration/Mobile_Transactions_using_SDKs"
  s.license       = "TBD"
  s.author        = { "Carmen Jurcovan" => "carmen.jurcovan@ro.ibm.com" }
  s.platform      = :ios, "13.0"
  s.swift_version = "5.3"
  s.requires_arc  = true

  s.exclude_files = "ClearentIdtechIOSFramework/**/Info.plist"
  s.resource      = 'ClearentIdtechIOSFramework/ClearentIdtechMessages.bundle'
  s.source        = { :git => "git@github.com:clearent/ClearentIdtechIOSFramework.git", :tag => 'v-' + s.version.to_s }
  s.source_files  = "ClearentIdtechIOSFramework/**/*.{h,m,swift}"
  s.resources     = "ClearentIdtechIOSFramework/**/*.{storyboard,plist,xib,strings,otf,xcassets,json,svg,png,css,html,js}"

  s.vendored_frameworks = 'IDTech.xcframework','CocoaLumberjack.xcframework'
  s.frameworks          = 'CFNetwork', 'AudioToolbox','AVFoundation','MediaPlayer','ExternalAccessory'
  s.pod_target_xcconfig = {'OTHER_SWIFT_FLAGS' => '-Xcc -Wno-error=non-modular-include-in-framework-module' ,
                           'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
                           'ARCHS' => 'arm64 x86_64',
                           'VALID_ARCHS' =>'arm64',
                           'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64',
                           'DEFINES_MODULE' => 'YES',
                           'ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES' => 'YES'}

  s.user_target_xcconfig = {'OTHER_SWIFT_FLAGS' => '-Xcc -Wno-error=non-modular-include-in-framework-module' ,
                           'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
                           'ARCHS' => 'arm64 x86_64',
                           'VALID_ARCHS' =>'arm64',
                           'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64',
                           'DEFINES_MODULE' => 'YES',
                           'ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES' => 'YES'}
end
