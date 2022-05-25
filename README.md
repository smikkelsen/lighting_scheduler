Configure ENV variables. First create a .env.development.local which is in .gitignore, and fill out the config
```bash
cp ./.env.development ./.env.development.local
```

## Pattern
Patterns are cached in the database, and can be updated by calling the `update_cached` class method. When patterns are
pulled from the controller, their attributes are hashed and saved as a uuid so they an later be matched up even if
the name changes.

Update the cached definitions
```ruby
Pattern.update_cached
``` 

A single pattern can be activated:
```ruby
Pattern.first.activate(:all) # activate the pattern on all zones
```
     
## Zone
Zones are cached in the database much like Patterns. Zones that don't belong to a ZoneSet are considered the current
zones. These zones are a reflection of the zones that are currently loaded in the Jellyfish controller. To be sure, you can 
update cached definitions as shown below. this will pull all zones from the controller, find or create them based on the uuid
then it will delete all current zones that weren't in the list. Make sure you save the current zones off into a
ZoneSet (more on that below).

Update the cached definitions
```ruby
Zone.update_cached
``` 

## ZoneSet
A ZoneSet is a set of zones that can be loaded into the Jellyfish controller. These are handy if you want multiple sets
of zones for different display properties. For example, you may want lights to run from left to right all the way around
the house for one display, but another display you'd like the peaks to be one color running one direction, and the rest 
of the house another color running a different direction. The direction is controlled by zone, and thus needs its own
zone each time.

Save off current Zones into a ZoneSet
```ruby 
ZoneSet.create_from_current('My ZoneSet Name')
```

A ZoneSet can be activated (loaded into the Jellyfish controller). This will wipe out all other zones in the controller.
If you are worried about saving those, make sure to update cached zones, then create a zoneset from current zones.
```ruby 
ZoneSet.first.activate
```

## Display
Think of the Display object as the final result that displays on the house.
If you've got a collection of zones, each with individual patterns you'd like to 
display, this is how they will be grouped together. In the example below you find
that one pattern is configured for the first and last zone, and a different pattern 
is configured for the second zone.
```ruby
Display.create(
  name: '4th of July 1',
  description: 'This has red, white, blue on top and bottom peak, with blue white on rest of house, and twinkle effect',
  zone_set: ZoneSet.first,
  display_patterns_attributes: [
    {pattern: Pattern.first, zones: [Zone.first.uuid, Zone.last.uuid]},
    {pattern: Pattern.second, zones: [Zone.second.uuid]},
  ]
)
```
Alternatively you can add it like this:
```ruby
d = Display.new(
  name: '4th of July 2',
  description: 'This has red, white, blue on top and bottom peak, with blue white on rest of house, and twinkle effect',
  zone_set: ZoneSet.first
)
d.display_patterns.new(pattern: Pattern.first, zones: [Zone.first.uuid, Zone.last.uuid])
d.display_patterns.new(pattern: Pattern.second, zones: [Zone.second.uuid])
d.save!
```
Currently, there are no validations to ensure you don't use a zone more than once in a display.
If you do this, than the as the display is activated, the last Display Pattern configured 
with the zone will win.

To activate a Display, simply:
`Display.first.activate`
                    
## Tag
A Tag is a way to categorize your Displays. For example, you may have a display called 'Fourth of July Chase' that you 
Tag as 'July'. You may have a Display that does all warm white lights, that you tag as 'Security', and 'Christmas'. 
     
Tag a display:
```ruby 
display.tags = [Tag.first]
```

You can activate a random display from a tag. Say you have 10 variations of displays all Tagged with 'July'. 
```ruby 
Tag.find_by_name('July').activate_random_display
```

### Turning lights off
The ZoneHelper concern is on multiple classes and has an instance and class method that works the same. The exception
is that an instance methond on Zone overrides the default and when no zones are passed in, it just turns off the one
zone. Some examples:

```ruby
Zone.first.turn_off # turns off the one zone
Display.turn_off # turns everything off
Display.first.turn_off(:all) # same as above
Pattern.turn_off(Zone.first)
Pattern.turn_off(Zone.first.name)
Pattern.turn_off(Zone.first.id)
Pattern.turn_off([Zone.first, Zone.last])
```