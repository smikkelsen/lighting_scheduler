class Zone < ApplicationRecord
  include ZoneHelper
  before_create :set_uuid

  belongs_to :zone_set, optional: true
  serialize :port_map

  validates :uuid, presence: true, uniqueness: {case_sensitive: false, scope: :zone_set_id}

  scope :current, -> { where(zone_set_id: nil) }
  scope :in_set, -> { where.not(zone_set_id: nil) }

  def self.update_cached
    zones = WebsocketMessageHandler.msg({ cmd: 'toCtlrGet', get: [['zones']] })["zones"]
    updated = []
    zones.each do |name, data|
      Rails.logger.debug data
      uuid = Zone.uuid_from_json(data)
      z = Zone.current.where(uuid: uuid).first_or_initialize
      z.name = name
      z.pixel_count = data['numPixels']
      z.port_map = data['portMap']
      z.save
      updated << z.id
    end
    Zone.current.where.not(id: updated).destroy_all
  end

  def turn_off(zones=nil)
    zones ||= self
    super(zones)
  end

  private
  def set_uuid
    self.uuid ||= self.uuid_from_attributes
  end

end
