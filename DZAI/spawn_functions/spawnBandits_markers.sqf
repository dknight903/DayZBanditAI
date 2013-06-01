/*
	spawnBandits_markers version 0.08
	
	Usage: [_minAI, _addAI, _patrolDist, _trigger, _markerArray, _numGroups (optional)] call fnc_spawnBandits_markers;
	Description: Called through (mapname)_config.sqf. Spawns a specified number groups of AI units at a randomly selected marker.
*/
private ["_minAI","_addAI","_patrolDist","_trigger","_markerArray","_equipType","_numGroups","_grpArray","_triggerPos","_gradeChances","_totalAI","_spawnCount"];
if (!isServer) exitWith {};

_minAI = _this select 0;							//Mandatory minimum number of AI units to spawn
_addAI = _this select 1;							//Maximum number of additional AI units to spawn
_patrolDist = _this select 2;
_trigger = _this select 3;
_markerArray = _this select 4;						//Array of markers to select spawn points/reference point for patrolling. These markers should be placed within 100m (approx) of each other.
_equipType = if ((count _this) > 5) then {_this select 5} else {1};		//(Optional) Select the item probability table to use (0: Newbie, 1: Average, 2: High-end)
_numGroups = if ((count _this) > 6) then {_this select 6} else {1};		//(Optional) Number of groups of x number of units each to spawn

if (DZAI_numAIUnits >= DZAI_maxAIUnits) exitWith {diag_log format["DZAI Warning: Maximum number of AI reached! (%1)",DZAI_numAIUnits];}; //Check if there are too many AI units in the game.

_grpArray = _trigger getVariable ["GroupArray",[]];			//Retrieve groups created by the trigger, or create an empty group array if none found.
if (count _grpArray > 0) exitWith {if (DZAI_debugLevel > 0) then {diag_log "DZAI Debug: Active groups found. Exiting spawn script (spawnBandits_markers)";};};						//Exit script if active groups still exist.

_totalAI = DZAI_spawnExtra + _minAI + round(random _addAI);	//Calculate the total number of AI to spawn per group
if (_totalAI == 0) exitWith {};								//Only run script if there is at least one bandit to spawn

_triggerPos = getpos _trigger;
_gradeChances = [_equipType] call fnc_getGradeChances;
_spawnCount = (_totalAI * _numGroups);

if (DZAI_debugLevel > 0) then {diag_log format["DZAI Debug: Spawning %1 new AI groups of %2 units each (spawnBandits_markers).",_numGroups,_totalAI];};
for "_j" from 1 to _numGroups do {
	private ["_unitGroup","_marker","_markerPos"];
	_unitGroup = createGroup resistance;						//All units spawned from the same trigger will be part of the same group.
	_marker = _markerArray call BIS_fnc_selectRandom;			//Choose random marker from the array to use as a spawn point. All units of a group will spawn at the same location.
	_markerPos = getMarkerPos _marker;
	for "_i" from 1 to _totalAI do {
		private ["_unit"];
		_unit = [_unitGroup,_markerPos,_trigger,3,_gradeChances] call fnc_createAI;
		if (DZAI_debugLevel > 1) then {diag_log format["DZAI Extended Debug: AI %1 of %2 spawned (spawnBandits_markers).",_i,_totalAI];};
	};
	_unitGroup selectLeader ((units _unitGroup) select 0);
	0 = [_unitGroup,_triggerPos,_patrolDist,DZAI_debugMarkers] spawn fnc_BIN_taskPatrol;
	_grpArray = _grpArray + [_unitGroup];							//Add the new group to the trigger's group array.
};
0 = [_trigger,_grpArray,_spawnCount,_patrolDist,_gradeChances,_markerArray] spawn fnc_initTrigger;

true