# dfsstats

- This resource requires DFS Base. https://github.com/DarkFeather-Studios/fivem_framework
- This resource is a complete in-place replacement for ESX_Staus - you can still use the ESX_status events and DFS Stats will track them. It fixes a server hitch/crash vulnerability with per-frame stat transactions while using ESX_Status. You may need to modify "hunger" and "thirst" in your scripts to instead be "Food" and "Water". ESX_Status registration of stats is non-compatible with DFS Stats, but is now oodles easier for anyone with a few days of coding or more under their belt.
- This resource may cause issues when modifying health from an external, non-game source. Try to use the embedded events for health changes not caused by game events.
- This resource requires MySQL Async and the SQL file provided with esx_status. This dependencie may take more than an hour to remove.

Included stats are
- Health
- Armor
- Food
- Water
- Stress

Exports;

Client
- GetStat(string StatName); returns the value of StatName, or nil if it does not exist.
- ModStat(string StatName, int Amount); Alters the value of StatName by Amount.
- GetStatMax(string StatName); Returns the maximum value of StatName.
- SetStatMax(string StatName, int NewMaximumAmount); Sets the maximum a stat can be. Note; Health and Amor may not behave as expected when altering these, but this should be an easy fix.
- ResetStatMaxes(); Resets all stat maximum values to their defaults.
- ResetStats(); Rests all stats to their current maximums or minumums. Food goes up, stress goes down.
