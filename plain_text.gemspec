# -*- encoding: utf-8 -*-

require 'rake'

Gem::Specification.new do |s|
  s.name = %q{plain_text}
  s.version = "0.1"
  # s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  %w(countchar).each do |f|
    s.executables << f
  end
  s.bindir = 'bin'
  s.authors = ["Masa Sakano"]
  s.date = %q{2019-10-25}
  s.summary = %q{Module to handle Plain-Text}
  s.description = %q{This module provides utility functions and methods to handle plain text, classes Part/Paragraph/Boundary to represent the logical structure of a document and ParseRule to describe the rules to parse plain text to produce a Part-type Ruby instance.}
  # s.email = %q{abc@example.com}
  s.extra_rdoc_files = [
    # "LICENSE",
     "README.en.rdoc",
  ]
  s.license = 'MIT'
  s.files = FileList['.gitignore','lib/**/*.rb','[A-Z]*','test/**/*.rb', '*.gemspec', 'bin'].to_a.delete_if{ |f|
    ret = false
    arignore = IO.readlines('.gitignore')
    arignore.map{|i| i.chomp}.each do |suffix|
      if File.fnmatch(suffix, File.basename(f))
        ret = true
        break
      end
    end
    ret
  }
  s.files.reject! { |fn| File.symlink? fn }
  # s.add_runtime_dependency 'rails'
  # s.add_development_dependency "bourne", [">= 0"]
  s.homepage = %q{https://www.wisebabel.com}
  s.rdoc_options = ["--charset=UTF-8"]

  # s.require_paths = ["lib"]	# Default "lib"
  s.required_ruby_version = '>= 2.0'
  s.test_files = Dir['test/**/*.rb']
  s.test_files.reject! { |fn| File.symlink? fn }
  # s.requirements << 'libmagick, v6.0' # Simply, info to users.
  # s.rubygems_version = %q{1.3.5}      # This is always set automatically!!

  s.metadata["yard.run"] = "yri" # use "yard" to build full HTML docs.
end

