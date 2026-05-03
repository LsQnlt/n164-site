#!/usr/bin/env ruby
require "fileutils"

# Dossiers à scanner
SCAN_DIRS = ["_films", "_membres", "_data", "_includes", "_layouts", "."].freeze
SCAN_EXTENSIONS = %w[.md .markdown .html .yml .yaml].freeze
ROOT = File.expand_path("..", __dir__)

# Regex : capture une extension d'image dans un chemin /assets/images/...
PATTERN = %r{(/assets/images/[\w\-.]+?)\.(jpg|jpeg|png)\b}i

modified_files = 0
total_replacements = 0

SCAN_DIRS.each do |dir|
  full_dir = File.join(ROOT, dir)
  next unless Dir.exist?(full_dir)

  Dir.glob(File.join(full_dir, "**", "*")).each do |path|
    next unless File.file?(path)
    next unless SCAN_EXTENSIONS.include?(File.extname(path).downcase)
    next if path.include?("/_site/") || path.include?("/node_modules/")

    content = File.read(path)
    new_content = content.gsub(PATTERN) do
      "#{Regexp.last_match(1)}.webp"
    end

    next if content == new_content

    count = content.scan(PATTERN).size
    File.write(path, new_content)
    relative = path.sub("#{ROOT}/", "")
    puts "✓ #{relative} (#{count} référence#{'s' if count > 1})"
    modified_files += 1
    total_replacements += count
  end
end

puts ""
puts "═══════════════════════════════════════"
puts "#{modified_files} fichiers modifiés"
puts "#{total_replacements} références remplacées"
puts "═══════════════════════════════════════"
