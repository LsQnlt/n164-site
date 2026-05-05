#!/usr/bin/env ruby
require "fileutils"

# Dossiers à scanner
SCAN_DIRS = ["_films", "_membres", "_data", "_includes", "_layouts", "."].freeze
SCAN_EXTENSIONS = %w[.md .markdown .html .yml .yaml].freeze
ROOT = File.expand_path("..", __dir__)

# Regex : capture une extension d'image dans un chemin /assets/images/...
PATTERN = %r{(/assets/images/[^\s"'<>]+?)\.(jpg|jpeg|png)\b}i

DRY_RUN = ARGV.include?("--dry-run")
puts "[DRY-RUN] Aucun fichier ne sera modifié." if DRY_RUN

modified_files = 0
total_replacements = 0
seen_paths = Set.new

SCAN_DIRS.each do |dir|
  full_dir = File.join(ROOT, dir)
  next unless Dir.exist?(full_dir)

  Dir.glob(File.join(full_dir, "**", "*")).each do |path|
    next unless File.file?(path)
    next unless SCAN_EXTENSIONS.include?(File.extname(path).downcase)
    next if path.include?("/_site/") || path.include?("/node_modules/")
    next unless seen_paths.add?(path)

    content = File.read(path)
    new_content = content.gsub(PATTERN) do
      basename = Regexp.last_match(1)
      webp_path = File.join(ROOT, "#{basename}.webp")
      if File.exist?(webp_path)
        "#{basename}.webp"
      else
        warn "⚠ webp manquant, référence conservée : #{basename}.#{Regexp.last_match(2)}"
        Regexp.last_match(0)
      end
    end

    next if content == new_content

    count = content.scan(PATTERN).size
    File.write(path, new_content) unless DRY_RUN
    relative = path.sub("#{ROOT}/", "")
    prefix = DRY_RUN ? "~" : "✓"
    puts "#{prefix} #{relative} (#{count} référence#{'s' if count > 1})"
    modified_files += 1
    total_replacements += count
  end
end

puts ""
puts "═══════════════════════════════════════"
puts "#{modified_files} fichiers modifiés"
puts "#{total_replacements} références remplacées"
puts "═══════════════════════════════════════"
