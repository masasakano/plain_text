# -*- encoding: utf-8 -*-

# Author: M. Sakano (Wise Babel Ltd)

$stdout.sync=true
$stderr.sync=true

# print '$LOAD_PATH=';p $LOAD_PATH
arlibbase = %w(plain_text)

arlibrelbase = arlibbase.map{|i| "../lib/"+i}

arlibrelbase.each do |elibbase|
  require_relative elibbase
end	# arlibbase.each do |elibbase|

print "NOTE: Running: "; p File.basename(__FILE__)
print "NOTE: Library relative paths: "; p arlibrelbase
arlibbase4full = arlibbase.map{|i| i.sub(%r@^(../)+@, "")}
puts  "NOTE: Library full paths for #{arlibbase4full.inspect}: "
arlibbase4full.each do |elibbase|
  ar = $LOADED_FEATURES.grep(/(^|\/)#{Regexp.quote(File.basename(elibbase))}(\.rb)?$/).uniq
  print elibbase+": " if ar.empty?; p ar
end

#################################################
# Unit Test
#################################################

#if $0 == __FILE__
gem "minitest"
# require 'minitest/unit'
require 'minitest/autorun'
# MiniTest::Unit.autorun

class TestUnitPlainTextUtil < MiniTest::Test
  T = true
  F = false
  SCFNAME = File.basename(__FILE__)
  include PlainText::Util

  def setup
  end

  def teardown
  end

  def test_arind2ranges
    assert_equal [(1..3), (6..7), (9..9)], arind2ranges([1,2,3,6,7,9])
  end
end
