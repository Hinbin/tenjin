# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'omniauth/wonde/version'

Gem::Specification.new do |spec|
  spec.name          = 'omniauth-wonde'
  spec.version       = Omniauth::Wonde::VERSION
  spec.authors       = ['Hinbin']
  spec.email         = ['nicholashoulton@gmail.com']

  spec.summary       = 'oAuth2 Gem for access to Wonde.'
  spec.description   = 'oAuth2 Gem for access to Wonder data'
  spec.homepage      = 'http://www.google.com.'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
    spec.metadata['rubygems_mfa_required'] = 'true'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
          'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # Use Dir.glob (not `git ls-files`) so the gemspec loads in build
  # environments where git is unavailable, e.g. Docker/Render deploys.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('**/*', File::FNM_DOTMATCH).reject do |f|
      File.directory?(f) || f.match(%r{^(test|spec|features)/})
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 13.0'
end
