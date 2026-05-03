#!/usr/bin/env ruby
require "image_processing/vips"
require "fileutils"

SOURCE_DIR = File.expand_path("../assets/images", __dir__)
BACKUP_DIR = File.expand_path("../assets/images_originals", __dir__)
MAX_DIMENSION = 2048
QUALITY = 85
EXTENSIONS = %w[.jpg .jpeg .png].freeze

FileUtils.mkdir_p(BACKUP_DIR)

processed = 0
total_before = 0
total_after = 0

Dir.glob(File.join(SOURCE_DIR, "*")).each do |path|
  next unless File.file?(path)
  next unless EXTENSIONS.include?(File.extname(path).downcase)

  original_name = File.basename(path)
  basename = File.basename(path, ".*")
  webp_path = File.join(SOURCE_DIR, "#{basename}.webp")
  size_before = File.size(path)

  # Backup
  FileUtils.cp(path, File.join(BACKUP_DIR, original_name))

  # Optimise
  result = ImageProcessing::Vips
           .source(path)
           .resize_to_limit(MAX_DIMENSION, MAX_DIMENSION)
           .convert("webp")
           .saver(quality: QUALITY)
           .call

  FileUtils.mv(result.path, webp_path)
  File.delete(path) if path != webp_path

  size_after = File.size(webp_path)
  total_before += size_before
  total_after += size_after
  processed += 1

  puts "✓ #{original_name} → #{basename}.webp  (#{(size_before / 1024.0 / 1024).round(2)}M → #{(size_after / 1024.0 / 1024).round(2)}M)"
end

puts ""
puts "═══════════════════════════════════════"
puts "#{processed} images traitées"
puts "Avant : #{(total_before / 1024.0 / 1024).round(1)} Mo"
puts "Après : #{(total_after / 1024.0 / 1024).round(1)} Mo"
puts "Économie : #{(100 - (total_after.to_f / total_before * 100)).round(1)}%"
puts "═══════════════════════════════════════"
puts "Backups : #{BACKUP_DIR}"
