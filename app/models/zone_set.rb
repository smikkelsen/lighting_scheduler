class ZoneSet < ApplicationRecord

  after_save :update_default_zone_set

  has_many :zones, dependent: :destroy
  has_many :displays, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :default, -> { where(default_zone_set: true).first }

  def self.create_from_current(name)
    zs = ZoneSet.create(name: name)
    Zone.current.each do |cz|
      Zone.create(cz.dup.attributes.merge(zone_set_id: zs.id))
    end
    zs.reload
  end

  def activate
    zone_hash = Hash.new
    self.zones.each do |z|
      zone_hash[z.name] = { 'numPixels': z.pixel_count, 'portMap': z.port_map }
    end
    WebsocketMessageHandler.msg({ cmd: 'toCtlrSet', save: true, zones: zone_hash })
    Zone.update_cached
  end

  private
  def update_default_zone_set
    return unless self.default_zone_set
    ZoneSet.where.not(id: self.id).update_all(default_zone_set: false)
  end
end
