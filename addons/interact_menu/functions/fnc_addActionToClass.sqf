#include "..\script_component.hpp"
/*
 * Author: esteldunedain
 * Inserts an ACE action to a class, under a certain path.
 * Note: This function is NOT global.
 *
 * Arguments:
 * 0: TypeOf of the class <STRING>
 * 1: Type of action, 0 for actions, 1 for self-actions <NUMBER>
 * 2: Parent path of the new action <ARRAY>
 * 3: Action <ARRAY>
 * 4: Use Inheritance <BOOL> (default: false)
 * 5: Classes excluded from inheritance (children included) <ARRAY> (default: [])
 *
 * Return Value:
 * The entry full path, which can be used to remove the entry, or add children entries <ARRAY>.
 *
 * Example:
 * [typeOf cursorTarget, 0, ["ACE_TapShoulderRight"], VulcanPinchAction] call ace_interact_menu_fnc_addActionToClass;
 *
 * Public: Yes
 */

if (!hasInterface) exitWith { [] };
if (!params [["_objectType", "", [""]], ["_typeNum", 0, [0]], ["_parentPath", [], [[]]], ["_action", [], [[]], 11]]) exitWith {
    ERROR("Bad Params");
    []
};
private _useInheritance = _this param [4, false, [false]];
private _excludedClasses = _this param [5, [], [[]]];
TRACE_6("addActionToClass",_objectType,_typeNum,_parentPath,_action,_useInheritance,_excludedClasses);

if (_useInheritance) exitWith {
    BEGIN_COUNTER(addAction);
    private _cfgVehicles = configFile >> "CfgVehicles"; // store this so we don't resolve for every element
    _excludedClasses = (_excludedClasses apply {configName (_cfgVehicles >> _x)}) - [""]; // ends up being faster than toLower'ing everything else
    if (_objectType == "CAManBase") then {
        GVAR(inheritedActionsMan) pushBack [_typeNum, _parentPath, _action, _excludedClasses];
        {
            private _type = _x;
            if (_excludedClasses findIf {_type isKindOf _x} == -1) then { // skip excluded classes and children
                [_x, _typeNum, _parentPath, _action] call FUNC(addActionToClass);
            };
        } forEach (GVAR(inheritedClassesMan) - _excludedClasses);
    } else {
        GVAR(inheritedActionsAll) pushBack [_objectType, _typeNum, _parentPath, _action, _excludedClasses];
        {
            private _type = _x;
            if (_type isKindOf _objectType && {_excludedClasses findIf {_type isKindOf _x} == -1}) then {
                [_type, _typeNum, _parentPath, _action] call FUNC(addActionToClass);
            };
        } forEach (GVAR(inheritedClassesAll) - _excludedClasses);
    };
    END_COUNTER(addAction);

    // Return the full path
    (_parentPath + [_action select 0])
};

_objectType = _objectType call EFUNC(common,getConfigName);

// Ensure the config menu was compiled first
if (_typeNum == 0) then {
    [_objectType] call FUNC(compileMenu);
} else {
    [_objectType] call FUNC(compileMenuSelfAction);
};

private _namespace = [GVAR(ActNamespace), GVAR(ActSelfNamespace)] select _typeNum;
private _actionTrees = _namespace getOrDefault [_objectType, [], true];

if (_parentPath isEqualTo ["ACE_MainActions"]) then {
    [_objectType, _typeNum] call FUNC(addMainAction);
};

private _parentNode = [_actionTrees, _parentPath] call FUNC(findActionNode);
if (isNil "_parentNode") exitWith {
    ERROR_4("Failed to add action - action (%1) to parent %2 on object %3 [%4]",(_action select 0),_parentPath,_objectType,_typeNum);
    []
};

// Add action node as children of the correct node of action tree
(_parentNode select 1) pushBack [_action,[]];

// Return the full path
(_parentPath + [_action select 0])
