# frozen_string_literal: true

require_relative 'lib/solidus_afterpay/version'

Gem::Specification.new do |spec|
  spec.name = 'solidus_afterpay'
  spec.version = SolidusAfterpay::VERSION
  spec.authors = ['Christian Rimondi', 'Jordy Garcia']
  spec.email = 'contact@solidus.io'

  spec.summary = 'Solidus extension for using Afterpay in your store.'
  spec.homepage = 'https://github.com/solidusio-contrib/solidus_afterpay#readme'
  spec.license = 'Apache-2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/solidusio-contrib/solidus_afterpay'
  spec.metadata['changelog_uri'] = 'https://github.com/solidusio-contrib/solidus_afterpay/blob/master/CHANGELOG.md'

  spec.required_ruby_version = Gem::Requirement.new('>= 2.5', '< 4')

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  files = Dir.chdir(__dir__) { `git ls-files -z`.split("\x0") }

  spec.files = files.grep_v(%r{^(test|spec|features)/})
  spec.bindir = "exe"
  spec.executables = files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'afterpay', '~> 0.6.0'
  spec.add_dependency 'solidus_core', ['>= 2.0.0']
  spec.add_dependency 'solidus_support', '~> 0.5'

  spec.add_development_dependency 'solidus_dev_support', '~> 2.5'
  spec.add_development_dependency 'vcr', '~> 6.0'
  spec.add_development_dependency 'webmock', '~> 3.14'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
