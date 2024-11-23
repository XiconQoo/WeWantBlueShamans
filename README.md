# WeWantBlueShamans

This addon simply makes Shamans blue in Classic Era without causing massive taint errors.
I just could not bear pink Shamans and other addons out there cause major bugs to raid frames.

Shamans will be blue in

- raid frames
- nameplates
- chat
- guild list
- who list
- map pins
- and more ...

## Using this in your Addon

This addon adds a global variable `CUSTOM_CLASS_COLORS` which can be used just like the blizzard global variable `RAID_CLASS_COLORS`.

Example usage in an addon:
```
local classColors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
local _, class = UnitClass(unit)
local color = classColors[class]
if color then
    print(color.r, color.g, color.b, color.colorStr)
    print(color:WrapTextInColorCode("This text is class colored"))
end
```

## Credits

This is a modified version of [ClassColors](https://www.curseforge.com/wow/addons/classcolors) by [Phanx](https://www.curseforge.com/members/phanxaddons/projects). Major props to the author.

For reference the github page: https://github.com/phanx-wow/ClassColors