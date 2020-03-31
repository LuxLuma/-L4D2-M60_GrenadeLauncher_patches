/*  
*    Copyright (C) 2019  LuxLuma		acceliacat@gmail.com
*
*    This program is free software: you can redistribute it and/or modify
*    it under the terms of the GNU General Public License as published by
*    the Free Software Foundation, either version 3 of the License, or
*    (at your option) any later version.
*
*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU General Public License for more details.
*
*    You should have received a copy of the GNU General Public License
*    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/


#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

#define GAMEDATA "M60_GrenadeLauncher_patches"
#define PLUGIN_VERSION	"1.0"


Address M60_Drop = Address_Null;
int M60_Drop_PatchRestoreBytes;

Address Ammo_Use = Address_Null;
int Ammo_Use_PatchRestoreBytes;


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "[L4D2]M60_NoDrop_AmmoPile_patch",
	author = "Lux",
	description = "Prevents m60 from dropping and allows use of ammo piles",
	version = PLUGIN_VERSION,
	url = "https://github.com/LuxLuma"
};

public void OnPluginStart()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);
	if(hGamedata == null) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	Patch_M60_Drop(hGamedata);
	Patch_M60_Ammo(hGamedata);
	
	delete hGamedata;
}

void Patch_M60_Drop(Handle &hGamedata)
{
	Address patch;
	int offset;
	int byte;
	
	patch = GameConfGetAddress(hGamedata, "CRifle_M60::PrimaryAttack");
	if(!patch) 
	{
		LogError("Error finding the 'CRifle_M60::PrimaryAttack' signature.");
		return;
	}
	
	offset = GameConfGetOffset(hGamedata, "CRifle_M60::PrimaryAttack");
	if(offset == -1)
	{
		LogError("Invalid offset for 'CRifle_M60::PrimaryAttack'.");
		return;
	}
	
	byte = LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8);
	if(byte == 0x75 || byte == 0x85)
	{
		M60_Drop = patch + view_as<Address>(offset);
		M60_Drop_PatchRestoreBytes = LoadFromAddress(M60_Drop, NumberType_Int8);
		
		if(byte == 0x75)
		{
			StoreToAddress(M60_Drop, 0xEB, NumberType_Int8);
		}
		else
		{
			StoreToAddress(M60_Drop, 0x8D, NumberType_Int8);
		}
	}
	else
	{
		LogError("Incorrect offset for 'CRifle_M60::PrimaryAttack'.");
		return;
	}
	
	PrintToServer("M60_NoDrop_AmmoPile_patch:Prevent drop patch applied 'CRifle_M60::PrimaryAttack'");
}

void Patch_M60_Ammo(Handle &hGamedata)
{
	Address patch;
	int offset;
	int byte;
	
	patch = GameConfGetAddress(hGamedata, "CWeaponAmmoSpawn::Use");
	if(!patch) 
	{
		LogError("Error finding the 'CWeaponAmmoSpawn::Use' signature.");
		return;
	}
	
	offset = GameConfGetOffset(hGamedata, "CWeaponAmmoSpawn::Use_M60_Patch");
	if(offset == -1)
	{
		LogError("Invalid offset for 'CWeaponAmmoSpawn::Use_M60_Patch'.");
		return;
	}
	
	byte = LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8);
	if(byte != 0x25)
	{
		LogError("Incorrect offset for 'CWeaponAmmoSpawn::Use_M60_Patch'.");
		return;
	}
	
	Ammo_Use = patch + view_as<Address>(offset);
	Ammo_Use_PatchRestoreBytes = LoadFromAddress(Ammo_Use, NumberType_Int8);
	StoreToAddress(Ammo_Use, 0xFF, NumberType_Int8);
	
	PrintToServer("M60_NoDrop_AmmoPile_patch:Ammo piles allow use 'CWeaponAmmoSpawn::Use_M60_Patch'");
}

public void OnPluginEnd()
{
	if(M60_Drop != Address_Null)
	{
		StoreToAddress(M60_Drop, M60_Drop_PatchRestoreBytes, NumberType_Int8);
		PrintToServer("M60_NoDrop_AmmoPile_patch:'CRifle_M60::PrimaryAttack' restored");
	}
	
	if(Ammo_Use != Address_Null)
	{
		StoreToAddress(Ammo_Use, Ammo_Use_PatchRestoreBytes, NumberType_Int8);
		PrintToServer("M60_NoDrop_AmmoPile_patch:'CWeaponAmmoSpawn::Use_M60_Patch' restored");
	}
}
