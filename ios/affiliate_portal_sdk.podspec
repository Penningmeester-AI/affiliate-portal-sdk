Pod::Spec.new do |s|
  s.name             = 'affiliate_portal_sdk'
  s.version          = '0.0.1'
  s.summary          = 'Afflicate attribution SDK iOS implementation'
  s.description      = 'Platform channel for launch URL (referrer is Android-only).'
  s.homepage         = 'https://github.com/your-org/affiliate-portal-sdk-flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Afflicate' => 'support@afflicate.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
