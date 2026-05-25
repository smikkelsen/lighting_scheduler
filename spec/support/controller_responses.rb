# Realistic controller response fixtures based on actual Jellyfish controller
module ControllerResponses
  def self.zones_response(zones_hash = simple_zone)
    {
      'cmd' => 'fromCtlr',
      'save' => true,
      'zones' => zones_hash
    }
  end

  # Simple single zone (use this as default in tests)
  def self.simple_zone
    {
      'All Lights' => {
        'numPixels' => 512,
        'portMap' => [
          {
            'ctlrName' => 'JellyFish-CF1D.local',
            'phyEndIdx' => 511,
            'phyPort' => 1,
            'phyStartIdx' => 0,
            'zoneRGBStartIdx' => 0
          }
        ]
      }
    }
  end

  # Complex multi-zone set (use for advanced testing)
  def self.complex_zones
    {
      'Corners Bottom Peak' => {
        'numPixels' => 20,
        'portMap' => [
          {
            'ctlrName' => 'JellyFish-CF1D.local',
            'phyEndIdx' => 94,
            'phyPort' => 4,
            'phyStartIdx' => 113,
            'zoneRGBStartIdx' => 0
          }
        ]
      },
      'Corners Front Left' => {
        'numPixels' => 20,
        'portMap' => [
          {
            'ctlrName' => 'JellyFish-CF1D.local',
            'phyEndIdx' => 138,
            'phyPort' => 2,
            'phyStartIdx' => 129,
            'zoneRGBStartIdx' => 0
          },
          {
            'ctlrName' => 'JellyFish-CF1D.local',
            'phyEndIdx' => 134,
            'phyPort' => 4,
            'phyStartIdx' => 143,
            'zoneRGBStartIdx' => 10
          }
        ]
      },
      'Corners Front Right' => {
        'numPixels' => 20,
        'portMap' => [
          {
            'ctlrName' => 'JellyFish-CF1D.local',
            'phyEndIdx' => 54,
            'phyPort' => 4,
            'phyStartIdx' => 73,
            'zoneRGBStartIdx' => 0
          }
        ]
      },
      'Corners Rear Left' => {
        'numPixels' => 20,
        'portMap' => [
          {
            'ctlrName' => 'JellyFish-CF1D.local',
            'phyEndIdx' => 81,
            'phyPort' => 2,
            'phyStartIdx' => 62,
            'zoneRGBStartIdx' => 0
          }
        ]
      },
      'Corners Rear Right' => {
        'numPixels' => 20,
        'portMap' => [
          {
            'ctlrName' => 'JellyFish-CF1D.local',
            'phyEndIdx' => 9,
            'phyPort' => 2,
            'phyStartIdx' => 0,
            'zoneRGBStartIdx' => 0
          },
          {
            'ctlrName' => 'JellyFish-CF1D.local',
            'phyEndIdx' => 0,
            'phyPort' => 4,
            'phyStartIdx' => 9,
            'zoneRGBStartIdx' => 10
          }
        ]
      },
      'Corners Top Peak' => {
        'numPixels' => 20,
        'portMap' => [
          {
            'ctlrName' => 'JellyFish-CF1D.local',
            'phyEndIdx' => 13,
            'phyPort' => 1,
            'phyStartIdx' => 32,
            'zoneRGBStartIdx' => 0
          }
        ]
      },
      'Corners Filler' => {
        'numPixels' => 209,
        'portMap' => [
          {
            'ctlrName' => 'JellyFish-CF1D.local',
            'phyEndIdx' => 33,
            'phyPort' => 1,
            'phyStartIdx' => 45,
            'zoneRGBStartIdx' => 0
          },
          {
            'ctlrName' => 'JellyFish-CF1D.local',
            'phyEndIdx' => 0,
            'phyPort' => 1,
            'phyStartIdx' => 12,
            'zoneRGBStartIdx' => 13
          },
          {
            'ctlrName' => 'JellyFish-CF1D.local',
            'phyEndIdx' => 61,
            'phyPort' => 2,
            'phyStartIdx' => 10,
            'zoneRGBStartIdx' => 26
          },
          {
            'ctlrName' => 'JellyFish-CF1D.local',
            'phyEndIdx' => 128,
            'phyPort' => 2,
            'phyStartIdx' => 82,
            'zoneRGBStartIdx' => 78
          },
          {
            'ctlrName' => 'JellyFish-CF1D.local',
            'phyEndIdx' => 10,
            'phyPort' => 4,
            'phyStartIdx' => 53,
            'zoneRGBStartIdx' => 125
          },
          {
            'ctlrName' => 'JellyFish-CF1D.local',
            'phyEndIdx' => 74,
            'phyPort' => 4,
            'phyStartIdx' => 93,
            'zoneRGBStartIdx' => 169
          },
          {
            'ctlrName' => 'JellyFish-CF1D.local',
            'phyEndIdx' => 114,
            'phyPort' => 4,
            'phyStartIdx' => 133,
            'zoneRGBStartIdx' => 189
          }
        ]
      }
    }
  end

  # Pattern responses
  def self.pattern_list_response
    {
      'patternFileList' => [
        { 'name' => 'Twinkle', 'folders' => 'Christmas', 'readOnly' => true },
        { 'name' => 'Chase', 'folders' => 'Christmas', 'readOnly' => true },
        { 'name' => 'Warm White', 'folders' => 'Christmas', 'readOnly' => true },
        { 'name' => 'Rainbow', 'folders' => 'General', 'readOnly' => true },
        { 'name' => 'Custom Pattern', 'folders' => 'Custom', 'readOnly' => false }
      ]
    }
  end

  def self.pattern_data_response(pattern_name = 'Twinkle')
    {
      'patternFileData' => {
        'jsonData' => {
          'effect' => 'twinkle',
          'speed' => 5,
          'brightness' => 100
        }.to_json
      }
    }
  end

  # Pattern activation responses
  def self.pattern_activation_response(state = 1)
    {
      'cmd' => 'fromCtlr',
      'ledPower' => state == 1
    }
  end

  # Turn off response
  def self.turn_off_response
    pattern_activation_response(0)
  end
end
