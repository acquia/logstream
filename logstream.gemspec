libpath = File.join(File.dirname(__FILE__), 'lib')
$LOAD_PATH.unshift(libpath) unless $LOAD_PATH.include?(libpath)

Gem::Specification.new do |s|
  s.name = "logstream"
  s.version = "2.0.0"
  s.date = Time.now.strftime("%Y-%m-%d")

  s.author = "Acquia Engineering"
  s.homepage = "https://github.com/acquia/logstream"

  s.licenses = ['MIT']

  s.summary = "Acquia Logstream tools and library"
  s.description = "Logstream is an Acquia service for streaming logs from Acquia Cloud."

  s.files = Dir["[A-Z]*", "{bin,etc,lib,test}/**/*"]
  s.bindir = "bin"
  s.executables = Dir["bin/*"].map { |f| File.basename(f) }.select { |f| f =~ /^[\w\-]+$/ }
  s.test_files = Dir["test/**/*"]

  s.add_runtime_dependency('faye-websocket', ['~> 0.10.0'])
  s.add_runtime_dependency('thor', ['~> 0.20.0'])

  s.required_ruby_version = '>= 2.4'
end
