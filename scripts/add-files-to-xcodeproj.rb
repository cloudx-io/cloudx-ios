#!/usr/bin/env ruby
# Add source files to an Xcode project target, creating groups that mirror the
# on-disk folder path relative to the project's main group.
#
#   ruby scripts/add-files-to-xcodeproj.rb <project.xcodeproj> <target> <file> [file...]
#
# Idempotent: files already referenced are skipped. .m/.swift/.mm go into the
# Sources build phase; .h is reference-only.
require 'xcodeproj'

project_path, target_name, *files = ARGV
abort "usage: #{$0} <project.xcodeproj> <target> <file>..." if files.empty?

project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == target_name } or abort "target #{target_name} not found"
project_dir = File.dirname(File.expand_path(project_path))

files.each do |file|
  abs = File.expand_path(file)
  rel = abs.sub("#{project_dir}/", '')
  if project.files.any? { |f| f.real_path.to_s == abs }
    puts "skip   #{rel} (already referenced)"
    next
  end
  # Prefer the existing group whose on-disk path is the file's directory (groups
  # may be named differently from their folder, or nest their path), so files
  # land next to their siblings instead of in a parallel group tree.
  dir = File.dirname(abs)
  group = project.groups.flat_map { |g| [g] + g.recursive_children_groups }
                 .find { |g| g.real_path.to_s == dir }
  unless group
    group = project.main_group
    File.dirname(rel).split('/').each do |part|
      next if part == '.'
      group = group.children.find { |c| c.is_a?(Xcodeproj::Project::Object::PBXGroup) && c.real_path.to_s == File.join(group.real_path.to_s, part) } ||
              group.new_group(part, part)
    end
  end
  ref = group.new_file(abs)
  target.add_file_references([ref]) if %w[.m .mm .swift].include?(File.extname(abs))
  puts "added  #{rel}"
end
project.save
