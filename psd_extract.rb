#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require "psd"
require 'trollop'
require 'pp'
require 'yaml'
require 'active_support/core_ext/hash/slice'
include Trollop

def clean_node(node)
  h = {}

  h[:text]= node[:text].slice(:value, :font, :css) if node[:text]
  if node[:children]
    children = node[:children].map {|child| clean_node(child)}.compact
    h[:children] = children
  end
  if h.empty? or (h[:children] and h[:children].empty?)
    nil
  else
    h
  end
end

opts = options do
  banner <<-EOF
Extract some things from psd !
  Exemple : #$0 *.psd
  EOF
  # opt :input, "Input file(s)", :type => :string, :short => "-i"
  opt :debug, "enable PSD.debug", :type => :boolean, :short => "-d"
end

PSD.debug = true if opts[:debug]

die "Give me some input files!" if ARGV.empty?

ARGV.each do |file|
  psd_file = PSD.new(file)
  psd_file.parse!

  basename = File.basename(file, ".psd")
  Dir.mkdir basename unless Dir.exist? basename

  dest_path = "#{basename}"

  puts "#Exporting #{file} in #{dest_path}..."

  tree = psd_file.tree.to_hash
  File.open("#{dest_path}/#{basename}.yml", "w") do |infos_file|
    infos_file.write clean_node(tree).to_yaml
  end
  puts "#{psd_file.slices.size} slices"
  psd_file.slices.each_with_index do |slice, index|
    slice.to_png
    slice.save_as_png "#{dest_path}/slice-#{index}.png"
  end

  psd_file.image.save_as_png "#{dest_path}/#{basename}.png"
  system "convert #{dest_path}/#{basename}.png #{dest_path}/#{basename}.pdf"
end

puts "done!"








