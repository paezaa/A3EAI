private ["_targetPlayer", "_vehicle", "_startPos", "_unitLevel", "_unitGroup", "_paraGroup", "_cargoAvailable", "_unit", "_vehiclePos", "_parachute", "_unitsAlive", "_trigger", "_rearm"];
	
_vehicle = _this select 0;
_targetPlayer = _this select 1;

_target = if ((owner _targetPlayer) isEqualTo 0) then {_vehicle} else {_targetPlayer};
_startPos = getPosATL _target;
_startPos set [2,0];

_unitLevel = _unitGroup getVariable ["unitLevel",1];
_paraGroup = ["static"] call A3EAI_createGroup;

for "_i" from 1 to _cargoAvailable do {
	_unit = [_paraGroup,_unitLevel,[0,0,0]] call A3EAI_createUnit;
	_vehiclePos = (getPosATL _vehicle);
	_parachute = createVehicle ["Steerable_Parachute_F", [_vehiclePos select 0, _vehiclePos select 1, (_vehiclePos select 2)], [], (-10 + (random 10)), "FLY"];
	_unit moveInDriver _parachute;
	_unit call A3EAI_addTempNVG;
	uiSleep 0.5;
};

_unitsAlive = {alive _x} count (units _paraGroup);
_paraGroup setVariable ["GroupSize",_unitsAlive];
_paraGroup setVariable ["trigger",_trigger];

_trigger = createTrigger ["EmptyDetector",_startPos];
_trigger enableSimulationGlobal false;
_trigger setTriggerArea [600, 600, 0, false];
_trigger setTriggerActivation ["ANY", "PRESENT", true];
_trigger setTriggerTimeout [5, 5, 5, true];
_trigger setTriggerText (format ["Heli AI Reinforcement %1",mapGridPosition _vehicle]);
_trigger setTriggerStatements ["{if (isPlayer _x) exitWith {1}} count thisList != 0;","","0 = [thisTrigger] spawn A3EAI_despawn_static;"];
_trigger setVariable ["isCleaning",false];
_trigger setVariable ["GroupArray",[_paraGroup]];
_trigger setVariable ["unitLevel",_unitLevel];
_trigger setVariable ["maxUnits",[_unitsAlive,0]];
_trigger setVariable ["respawn",false]; //landed AI units should never respawn
_trigger setVariable ["permadelete",true]; //units should be permanently despawned
_trigger setVariable ["spawnType","static"];

[_trigger,"A3EAI_staticTriggerArray"] call A3EAI_updateSpawnCount;
0 = [_trigger] spawn A3EAI_despawn_static;

[_paraGroup,_startPos] call A3EAI_setFirstWPPos;
0 = [_paraGroup,_startPos,100] spawn A3EAI_BIN_taskPatrol;
_rearm = [_paraGroup,_unitLevel] spawn A3EAI_addGroupManager;

if (A3EAI_HCIsConnected) then {
	A3EAI_sendGroupTriggerVars_PVC = [[_unitGroup,_trigger],[_paraGroup],75,1,1,[_unitsAlive,0],0,"static",false,true];
	A3EAI_HCObjectOwnerID publicVariableClient "A3EAI_sendGroupTriggerVars_PVC";
};

_trigger enableSimulation true;

true