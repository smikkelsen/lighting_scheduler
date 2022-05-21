Configure ENV variables. First create a .env.development.local which is in .gitignore, and fill out the config
```bash
cp ./.env.development ./.env.development.local
```
Update the cached definitions for patterns and zones
```ruby
Pattern.update_cached
Zone.update_cached
```
                    
##Display
Think of the Display object as the final result that displays on the house.
If you've got a collection of zones, each with individual patterns you'd like to 
display, this is how they will be grouped together. In the example below you find
that one pattern is configured for the first and last zone, and a different pattern 
is configured for the second zone.
```ruby
Display.create(
  name: '4th of July 1', 
  display_patterns_attributes: [
    {pattern: Pattern.first, zones: [Zone.first, Zone.last]},
    {pattern: Pattern.second, zones: [Zone.second]},
  ]
)
```
Alternatively you can add it like this:
```ruby
d = Display.new(name: '4th of July 2')
d.display_patterns.new(pattern: Pattern.first, zones: [Zone.first, Zone.last])
d.display_patterns.new(pattern: Pattern.second, zones: [Zone.second])
d.save!
```
Currently, there are no validations to ensure you don't use a zone more than once in a display.
If you do this, than the as the display is activated, the last Display Pattern configured 
with the zone will win.

To activate a Display, simply:
`Display.first.activate`

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

## Pattern
Patterns are cached in the database, and can be updated by calling the `update_cached` class method.

A single pattern can be activated:
```ruby
Pattern.first.activate(:all) # activate the pattern on all zones
```