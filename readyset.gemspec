# frozen_string_literal: true

require_relative 'lib/readyset/version'

Gem::Specification.new do |spec|
  spec.name = 'readyset'
  spec.version = Readyset::VERSION
  spec.authors = ['ReadySet Technology, Inc.']
  spec.email = ['info@readyset.io']
  spec.licenses = ['MIT']

  spec.summary = 'A Rails adapter for ReadySet, a partially-stateful, incrementally-maintained ' \
                 'SQL cache.'
  spec.description = 'This gem provides a Rails adapter to the ReadySet SQL cache.'
  spec.homepage = 'https://readyset.io'
  spec.required_ruby_version = '>= 3.0'

  spec.metadata['allowed_push_host'] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/readysettech/readyset-rails'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w(bin/ test/ spec/ features/ .git .github))
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'actionpack', ['>= 6.1', '<= 7.1']
  spec.add_dependency 'activerecord', ['>= 6.1', '<= 7.1']
  spec.add_dependency 'activesupport', ['>= 6.1', '<= 7.1']
  spec.add_dependency 'colorize', '~> 1.1'
  spec.add_dependency 'concurrent-ruby', '~> 1.2'
  spec.add_dependency 'progressbar', '~> 1.13'
  spec.add_dependency 'rake', '~> 13.0'
  spec.add_dependency 'terminal-table', '~> 3.0'

  spec.add_development_dependency 'combustion', '~> 1.3'
  spec.add_development_dependency 'factory_bot', '~> 6.4'
  spec.add_development_dependency 'pg', '~> 1.5'
  spec.add_development_dependency 'pry', '~> 0.14'
  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_development_dependency 'rspec-rails', '~> 6.0'
  spec.add_development_dependency 'rubocop-airbnb', '~> 6.0'
  spec.add_development_dependency 'timecop', '~> 0.9'
end
