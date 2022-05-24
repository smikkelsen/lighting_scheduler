class Pattern < ApplicationRecord
  include ZoneHelper

  def self.update_cached
    patterns = WebsocketMessageHandler.msg({ cmd: 'toCtlrGet', get: [['patternFileList']] })["patternFileList"]
    updated = []
    patterns.each do |pattern|
      next if pattern['name'].blank?
      p = Pattern.where(name: pattern['name'], folder: pattern['folders']).first_or_initialize
      p.custom = !pattern['readOnly']
      p.save
      updated << p.id
    end
    Pattern.where.not(id: updated).destroy_all
  end

  def activate(zones = :all)
    zones = parameterize_zones(zones)
    if zones.empty?
      Rails.logger.debug("No matching zones to run pattern")
      return
    end
    pattern = { file: full_path, state: 1, zoneName: zones, data: "", id: "" }
    msg = { cmd: 'toCtlrSet', "runPattern": pattern }
    Rails.logger.debug msg
    # WebsocketMessageHandler.msg(msg)
  end

  def full_path
    ([self.folder, self.name] - [nil]).join('/')
  end

  def pattern_data
    @pattern_data ||= WebsocketMessageHandler.msg({ cmd: 'toCtlrGet', get: [['patternFileData', folder, name]] })
  end
end
