namespace :zones do
  desc "Migrate YAML port_map data to JSON format"
  task migrate_port_maps: :environment do
    puts "Migrating YAML port_map data to JSON..."

    updated_count = 0
    Zone.find_each do |zone|
      if zone.port_map.is_a?(String)
        begin
          # Try parsing as YAML first
          parsed = YAML.safe_load(zone.port_map, permitted_classes: [Symbol])
          zone.update_column(:port_map, parsed)
          updated_count += 1
          puts "  Updated Zone ##{zone.id} (#{zone.name})"
        rescue => e
          puts "  ERROR: Failed to parse Zone ##{zone.id} (#{zone.name}): #{e.message}"
        end
      end
    end

    puts "\nMigration complete. Updated #{updated_count} zone(s)."
  end
end
