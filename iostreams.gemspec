lib = File.expand_path("lib", __dir__)
$:.unshift lib unless $:.include?(lib)

# Maintain your gem's version:
require "io_streams/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name                  = "iostreams"
  s.version               = IOStreams::VERSION
  s.platform              = Gem::Platform::RUBY
  s.authors               = ["Reid Morrison"]
  s.homepage              = "https://iostreams.rocketjob.io"
  s.summary               = "Input and Output streaming for Ruby."
  s.files                 = Dir["lib/**/*", "bin/*", "LICENSE", "Rakefile", "README.md"]
  s.test_files            = Dir["test/**/*"]
  s.license               = "Apache-2.0"
  s.required_ruby_version = ">= 2.3"
end
