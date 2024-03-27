#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>

/* ~ [ ZP Extra Item Settings ] ~ */
new const ITEM_NAME[] = "Crossfire M4a1";
const ITEM_PRICE = 0;

/* ~ [ Weapon Resources ] ~ */
new const WEAPON_MODEL_VIEW[] = "models/bader/v_cross_m4a1.mdl";
new const WEAPON_MODEL_PLAYER[] = "models/bader/p_cross_m4a1.mdl";
new const WEAPON_MODEL_WORLD[] = "models/bader/w_cross_m4a1.mdl";

new const WEAPON_REFERENCE[] = "weapon_ak47";
const WEAPON_SPECIAL_CODE = 68546546;

const WEAPON_BPAMMO = 90;
const WEAPON_AMMO = 40;

#define m_iWeaponState 74

/* ~ [ Weapon Primary Attack ] ~ */
new const WEAPON_SHOOT_SOUND[] = "bader/tb_m4-1.wav";
#define WEAPON_SOUND_STAB_KNIFE "weapons/tb_slash-knife.wav"
const Float: WEAPON_SHOOT_RATE = 0.15;
const Float: WEAPON_SHOOT_PUNCHANGLE = 0.1;
const Float: WEAPON_SHOOT_DAMAGE = 3.65;

/* ~ [ Weapon Muzzleflash ] ~ */
//#define CUSTOM_MUZZLEFLASH_ENABLED

#if defined CUSTOM_MUZZLEFLASH_ENABLED
new const ENTITY_MUZZLE_CLASSNAME[] = "bader";
new const ENTITY_MUZZLE_SPRITE[] = "sprites/x.spr";

const Float: ENTITY_MUZZLE_NEXTTHINK = x.x;
#endif

/* ~ [ Animations Settings ] ~ */
const Float: WEAPON_ANIM_IDLE_TIME = 2.50;
const Float: WEAPON_ANIM_RELOAD_TIME = 1.47;
const Float: WEAPON_ANIM_DRAW_TIME = 0.67;
const Float: WEAPON_ANIM_SHOOT_TIME = 0.22;
#define WEAPON_ANIM_STAB_KNIFE_TIME  200.0/200.0

new g_iszModelIndexBloodSpray,
    g_iszModelIndexBloodDrop;



enum _: iWeaponAnims
{
    WEAPON_ANIM_IDLE = 0,
    WEAPON_ANIM_RELOAD,
    WEAPON_ANIM_DRAW,
    WEAPON_ANIM_SHOOT
}

#define WEAPON_ANIM_STAB_KNIFE 6

/* ~ [ Weapon List ] ~ */
new const WEAPON_WEAPONLIST[] = "weapon_ak47";
new const iWeaponList[] = { 2, 90, -1, -1, 0, 1, 28, 0 };
// https://wiki.alliedmods.net/CS_WeaponList_Message_Dump
 
/* ~ [ Definitions ] ~ */
#define IsCustomWeapon(%0) (pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)
#define IsPdataSafe(%0) (pev_valid(%0) == 2)

#define WEAPON_ANIM_EXTENSION_STAB_KNIFE "knife"


/* ~ [ Knife Configs ] ~ */

#define WEAPON_STAB_KNIFE_DISTANCE 125.0
#define WEAPON_STAB_KNIFE_DAMAGE random_float(200.0, 400.0)
#define WEAPON_STAB_KNIFE_KNOCKBACK 250.0

// CBaseAnimating
#define m_flFrameRate 36
#define m_flGroundSpeed 37
#define m_flLastEventCheck 38
#define m_fSequenceFinished 39
#define m_fSequenceLoops 40


// CBaseMonster
#define m_Activity 73
#define m_IdealActivity 74
#define m_LastHitGroup 75


// CBasePlayer
#define m_flPainShock 108
#define m_iPlayerTeam 114
#define m_flLastAttackTime 220


#define DONT_BLEED -1
#define PDATA_SAFE 2
#define ACT_RANGE_ATTACK1 28


/* ~ [ Offsets ] ~ */
const m_iClip = 51;
const linux_diff_player = 5;
const linux_diff_weapon = 4;
#define linux_diff_animation 4
const m_rpgPlayerItems = 367;
const m_pNext = 42
const m_iId = 43;
const m_iPrimaryAmmoType = 49;
const m_rgAmmo = 376;
const m_flNextAttack = 83;
const m_flTimeWeaponIdle = 48;
const m_flNextPrimaryAttack = 46;
const m_maxFrame = 35;
const m_flNextSecondaryAttack = 47;
const m_pPlayer = 41;
const m_fInReload = 54;
const m_pActiveItem = 373;
const m_rgpPlayerItems_iWeaponBox = 34;

/* ~ [ Global Parameters ] ~ */
new HamHook: gl_HamHook_TraceAttack[4],

    gl_iszAllocString_Entity,
    gl_iszAllocString_ModelView,
    gl_iszAllocString_ModelPlayer,

    #if defined CUSTOM_MUZZLEFLASH_ENABLED
    gl_iszAllocString_MuzzleFlash,
    #endif

    gl_iMsgID_Weaponlist,
    
    gl_iItemID;

/* ~ [ AMX Mod X ] ~ */
public plugin_init()
{
    register_plugin("Custom Weapon Template", "2.1", "Cristian505 \ Batcoh: Code Base");
    // Created & tested in AMX Mod X 1.9.0 on 11/4/2023.

    // Fakemeta
    register_forward(FM_UpdateClientData,    "FM_Hook_UpdateClientData_Post",      true);
    register_forward(FM_SetModel,            "FM_Hook_SetModel_Pre",              false);

    // Hamsandwich
    RegisterHam(Ham_Item_Deploy,            WEAPON_REFERENCE,    "CWeapon__Deploy_Post",           true);
    RegisterHam(Ham_Weapon_PrimaryAttack,   WEAPON_REFERENCE,    "CWeapon__PrimaryAttack_Pre",    false);
    RegisterHam(Ham_Weapon_Reload,          WEAPON_REFERENCE,	 "CWeapon__Reload_Pre",           false);
    RegisterHam(Ham_Item_PostFrame,         WEAPON_REFERENCE,	 "CWeapon__PostFrame_Pre",        false);
    RegisterHam(Ham_Item_Holster,           WEAPON_REFERENCE,	 "CWeapon__Holster_Post",          true);
    RegisterHam(Ham_Item_AddToPlayer,       WEAPON_REFERENCE,    "CWeapon__AddToPlayer_Post",      true);
    RegisterHam(Ham_Weapon_WeaponIdle,      WEAPON_REFERENCE,    "CWeapon__Idle_Pre",             false);

    // Trace Attack
    gl_HamHook_TraceAttack[0] = RegisterHam(Ham_TraceAttack,    "func_breakable",    "CEntity__TraceAttack_Pre",  false);
    gl_HamHook_TraceAttack[1] = RegisterHam(Ham_TraceAttack,	"info_target",	     "CEntity__TraceAttack_Pre",  false);
    gl_HamHook_TraceAttack[2] = RegisterHam(Ham_TraceAttack,	"player",            "CEntity__TraceAttack_Pre",  false);
    gl_HamHook_TraceAttack[3] = RegisterHam(Ham_TraceAttack,	"hostage_entity",    "CEntity__TraceAttack_Pre",  false);

    // Entity
    #if defined CUSTOM_MUZZLEFLASH_ENABLED
    RegisterHam(Ham_Think,					"env_sprite",		"CMuzzleFlash__Think_Pre", false);
    #endif

    // Alloc String
    gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
    gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
    gl_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, WEAPON_MODEL_PLAYER);

    #if defined CUSTOM_MUZZLEFLASH_ENABLED
    gl_iszAllocString_MuzzleFlash = engfunc(EngFunc_AllocString, ENTITY_MUZZLE_CLASSNAME);
    #endif

    // Messages
    gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");

    // Ham Hook
    fm_ham_hook(false);

    // Register ZP Extra Item
    gl_iItemID = zp_register_extra_item(ITEM_NAME, ITEM_PRICE, ZP_TEAM_HUMAN);
}

public plugin_precache()
{
    // Precache Models
    engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
    engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER);
    engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_WORLD);

    // Precache Sprites
    #if defined CUSTOM_MUZZLEFLASH_ENABLED
    engfunc(EngFunc_PrecacheModel, ENTITY_MUZZLE_SPRITE);
    #endif

    // Precache Sounds
    engfunc(EngFunc_PrecacheSound, WEAPON_SHOOT_SOUND);
    engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_STAB_KNIFE); 
    precache_sound("bader/tb_clipout-2.wav")
    precache_sound("bader/tb_clipin-1.wav")   
    precache_sound("bader/tb_bader_1.wav")   

    // Precache generic
    new szWeaponList[128]; formatex(szWeaponList, charsmax(szWeaponList), "sprites/%s.txt", WEAPON_WEAPONLIST);
    engfunc(EngFunc_PrecacheGeneric, szWeaponList);

    // Hook weapon
    register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");
}

/* ~ [ Zombie Plague ] ~ */
public zp_extra_item_selected(iPlayer, iItem)
{
    if(iItem == gl_iItemID)
    {
        Command_GiveWeapon(iPlayer);
    }
}

/* ~ [ Commands ] ~ */
public Command_HookWeapon(iPlayer)
{
    engclient_cmd(iPlayer, WEAPON_REFERENCE);
    return PLUGIN_HANDLED;
}

public Command_GiveWeapon(iPlayer)
{
    static iWeapon; iWeapon = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_Entity);
    if(!IsPdataSafe(iWeapon)) return FM_NULLENT;

    set_pev(iWeapon, pev_impulse, WEAPON_SPECIAL_CODE);
    ExecuteHam(Ham_Spawn, iWeapon);
    set_pdata_int(iWeapon, m_iClip, WEAPON_AMMO, linux_diff_weapon);
    UTIL_DropWeapon(iPlayer, ExecuteHamB(Ham_Item_ItemSlot, iWeapon));

    if(!ExecuteHamB(Ham_AddPlayerItem, iPlayer, iWeapon))
    {
	set_pev(iWeapon, pev_flags, pev(iWeapon, pev_flags) | FL_KILLME);
	return 0;
    }

    ExecuteHamB(Ham_Item_AttachToPlayer, iWeapon, iPlayer);
    UTIL_WeaponList(iPlayer, true);

    static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iWeapon, m_iPrimaryAmmoType, linux_diff_weapon);

    if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) < WEAPON_BPAMMO)
    set_pdata_int(iPlayer, iAmmoType, WEAPON_BPAMMO, linux_diff_player);

    emit_sound(iPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    return 1;
}

/* ~ [ Hamsandwich ] ~ */
public CWeapon__Deploy_Post(iWeapon)
{
    if(!IsPdataSafe(iWeapon) || !IsCustomWeapon(iWeapon)) return;

    static iPlayer; iPlayer = get_pdata_cbase(iWeapon, m_pPlayer, linux_diff_weapon);

    set_pev_string(iPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);
    set_pev_string(iPlayer, pev_weaponmodel2, gl_iszAllocString_ModelPlayer);

    UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_DRAW);

    set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
    set_pdata_float(iWeapon, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
}

public CWeapon__PrimaryAttack_Pre(iWeapon)
{
    if(!IsPdataSafe(iWeapon) || !IsCustomWeapon(iWeapon)) return HAM_IGNORED;

    static iAmmo; iAmmo = get_pdata_int(iWeapon, m_iClip, linux_diff_weapon);
    if(!iAmmo)
    {
        ExecuteHam(Ham_Weapon_PlayEmptySound, iWeapon);
        set_pdata_float(iWeapon, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

        return HAM_SUPERCEDE;
    }

    static fw_TraceLine; fw_TraceLine = register_forward(FM_TraceLine, "FM_Hook_TraceLine_Post", true);
    static fw_PlayBackEvent; fw_PlayBackEvent = register_forward(FM_PlaybackEvent, "FM_Hook_PlaybackEvent_Pre", false);
    fm_ham_hook(true);		

    ExecuteHam(Ham_Weapon_PrimaryAttack, iWeapon);
		
    unregister_forward(FM_TraceLine, fw_TraceLine, true);
    unregister_forward(FM_PlaybackEvent, fw_PlayBackEvent);
    fm_ham_hook(false);

    static iPlayer; iPlayer = get_pdata_cbase(iWeapon, m_pPlayer, linux_diff_weapon);

    static Float: vecPunchangle[3];
    pev(iPlayer, pev_punchangle, vecPunchangle);
    vecPunchangle[0] *= WEAPON_SHOOT_PUNCHANGLE
    vecPunchangle[1] *= WEAPON_SHOOT_PUNCHANGLE
    vecPunchangle[2] *= WEAPON_SHOOT_PUNCHANGLE
    set_pev(iPlayer, pev_punchangle, vecPunchangle);

    UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT);

    #if defined CUSTOM_MUZZLEFLASH_ENABLED
    UTIL_CreateMuzzleFlash(iPlayer, ENTITY_MUZZLE_SPRITE, random_float(0.05, 0.06), 150.0, 1);
    #endif

    emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SHOOT_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    set_pdata_float(iPlayer, m_flNextAttack, WEAPON_SHOOT_RATE, linux_diff_player);
    set_pdata_float(iWeapon, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);
    set_pdata_float(iWeapon, m_flNextPrimaryAttack, WEAPON_SHOOT_RATE, linux_diff_weapon);
    set_pdata_float(iWeapon, m_flNextSecondaryAttack, WEAPON_SHOOT_RATE, linux_diff_weapon);

    return HAM_SUPERCEDE;
}

public CWeapon__Reload_Pre(iWeapon)
{
    if(!IsPdataSafe(iWeapon) || !IsCustomWeapon(iWeapon)) return HAM_IGNORED;

    static iAmmo; iAmmo = get_pdata_int(iWeapon, m_iClip, linux_diff_weapon);
    if(iAmmo >= WEAPON_AMMO) return HAM_SUPERCEDE;

    static iPlayer; iPlayer = get_pdata_cbase(iWeapon, m_pPlayer, linux_diff_weapon);
    static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iWeapon, m_iPrimaryAmmoType, linux_diff_weapon);

    if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE;

    set_pdata_int(iWeapon, m_iClip, 0, linux_diff_weapon);
    ExecuteHam(Ham_Weapon_Reload, iWeapon);
    set_pdata_int(iWeapon, m_iClip, iAmmo, linux_diff_weapon);
    set_pdata_int(iWeapon, m_fInReload, 1, linux_diff_weapon);

    UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_RELOAD);

    set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_player);
    set_pdata_float(iWeapon, m_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
    set_pdata_float(iWeapon, m_flNextPrimaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
    set_pdata_float(iWeapon, m_flNextSecondaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);

    return HAM_SUPERCEDE;
}

public CWeapon__PostFrame_Pre(iWeapon)
{ 
    if(!IsCustomWeapon(iWeapon)) return HAM_IGNORED;

    static iPlayer; iPlayer = get_pdata_cbase(iWeapon, m_pPlayer, linux_diff_weapon);

    if(get_pdata_int(iWeapon, m_iWeaponState, linux_diff_weapon) == 0)
    {
        static iButton; iButton = pev(iPlayer, pev_button);
        
        if(iButton & IN_ATTACK2 && !get_pdata_int(iWeapon, m_fInReload, linux_diff_weapon) && get_pdata_float(iWeapon, m_flNextSecondaryAttack, linux_diff_weapon) <= 0.0)
        {
            new szAnimation[64];

            formatex(szAnimation, charsmax(szAnimation), pev(iPlayer, pev_flags) & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", WEAPON_ANIM_EXTENSION_STAB_KNIFE);
            UTIL_PlayerAnimation(iPlayer, szAnimation);

            UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_STAB_KNIFE);
            emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_STAB_KNIFE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

            set_pdata_int(iWeapon, m_iWeaponState, 1, linux_diff_weapon);
            set_pdata_float(iWeapon, m_flNextPrimaryAttack, WEAPON_ANIM_STAB_KNIFE_TIME, linux_diff_weapon);
            set_pdata_float(iWeapon, m_flNextSecondaryAttack, WEAPON_ANIM_STAB_KNIFE_TIME, linux_diff_weapon);
            set_pdata_float(iWeapon, m_flTimeWeaponIdle, WEAPON_ANIM_STAB_KNIFE_TIME, linux_diff_weapon);
            set_pdata_float(iPlayer, m_flNextAttack, 57/200.0, linux_diff_player);

            iButton &= ~IN_ATTACK2;
            set_pev(iPlayer, pev_button, iButton);
        }
    }
    else
    {
        new Float: flOrigin[3], Float: flAngle[3], Float: flEnd[3], Float: flViewOfs[3];
        new Float: flForw[3], Float: flUp[3], Float: flRight[3];

        pev(iPlayer, pev_origin, flOrigin);
        pev(iPlayer, pev_view_ofs, flViewOfs);

        flOrigin[0] += flViewOfs[0];
        flOrigin[1] += flViewOfs[1];
        flOrigin[2] += flViewOfs[2];
            
        pev(iPlayer, pev_v_angle, flAngle);
        engfunc(EngFunc_AngleVectors, flAngle, flForw, flRight, flUp);
            
        new iTrace = create_tr2();

        new Float: flSendAngles[] = { 0.0, -10.0, 10.0, -5.0, 5.0, -5.0, 5.0, 0.0, 0.0 }
        new Float: flSendAnglesUp[] = { 0.0, 0.0, 0.0, 7.5, 7.5, -7.5, -7.5, -15.0, 15.0 }
        new Float: flTan;
        new Float: flMul;

        new Float: flFraction;
        new pHit, pHitEntity = -1;

        for(new i; i < sizeof flSendAngles; i++)
        {
            flTan = floattan(flSendAngles[i], degrees);

            flEnd[0] = (flForw[0] * WEAPON_STAB_KNIFE_DISTANCE) + (flRight[0] * flTan * WEAPON_STAB_KNIFE_DISTANCE) + flUp[0] * flSendAnglesUp[i];
            flEnd[1] = (flForw[1] * WEAPON_STAB_KNIFE_DISTANCE) + (flRight[1] * flTan * WEAPON_STAB_KNIFE_DISTANCE) + flUp[1] * flSendAnglesUp[i];
            flEnd[2] = (flForw[2] * WEAPON_STAB_KNIFE_DISTANCE) + (flRight[2] * flTan * WEAPON_STAB_KNIFE_DISTANCE) + flUp[2] * flSendAnglesUp[i];
                
            flMul = (WEAPON_STAB_KNIFE_DISTANCE/vector_length(flEnd));
            flEnd[0] *= flMul;
            flEnd[1] *= flMul;
            flEnd[2] *= flMul;

            flEnd[0] = flEnd[0] + flOrigin[0];
            flEnd[1] = flEnd[1] + flOrigin[1];
            flEnd[2] = flEnd[2] + flOrigin[2];

            engfunc(EngFunc_TraceLine, flOrigin, flEnd, DONT_IGNORE_MONSTERS, iPlayer, iTrace);
            get_tr2(iTrace, TR_flFraction, flFraction);

            if(flFraction == 1.0)
            {
                engfunc(EngFunc_TraceHull, flOrigin, flEnd, HULL_HEAD, iPlayer, iTrace);
                get_tr2(iTrace, TR_flFraction, flFraction);
            
                engfunc(EngFunc_TraceLine, flOrigin, flEnd, DONT_IGNORE_MONSTERS, iPlayer, iTrace);
                pHit = get_tr2(iTrace, TR_pHit);
            }
            else
            {
                pHit = get_tr2(iTrace, TR_pHit);
            }
                
            if(pHit > 0 && pHitEntity != pHit)
            {
                if(pev(pHit, pev_solid) == SOLID_BSP && !(pev(pHit, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY))
                {
                    ExecuteHamB(Ham_TakeDamage, pHit, iPlayer, iPlayer, WEAPON_STAB_KNIFE_DAMAGE, DMG_NEVERGIB | DMG_CLUB);
                }
                else
                {
                    FakeTraceAttack(pHit, iPlayer, WEAPON_STAB_KNIFE_DAMAGE, flForw, iTrace, DMG_NEVERGIB | DMG_CLUB);
                    FakeKnockBack(pHit, flForw, WEAPON_STAB_KNIFE_KNOCKBACK);
                }

                pHitEntity = pHit;
            }
        }

        free_tr2(iTrace);

        set_pdata_int(iWeapon, m_iWeaponState, 0, linux_diff_weapon);
    }


    if(!IsPdataSafe(iWeapon) || !IsCustomWeapon(iWeapon)) return HAM_IGNORED;

    static iClip; iClip = get_pdata_int(iWeapon, m_iClip, linux_diff_weapon);
    if(get_pdata_int(iWeapon, m_fInReload, linux_diff_weapon) == 1)
    {
        static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iWeapon, m_iPrimaryAmmoType, linux_diff_weapon);
        static iPlayer; iPlayer = get_pdata_cbase(iWeapon, m_pPlayer, linux_diff_weapon);
        static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, linux_diff_player);
        static j; j = min(WEAPON_AMMO - iClip, iAmmo);
        
        set_pdata_int(iWeapon, m_iClip, iClip + j, linux_diff_weapon);
        set_pdata_int(iPlayer, iAmmoType, iAmmo - j, linux_diff_player);
        set_pdata_int(iWeapon, m_fInReload, 0, linux_diff_weapon);
    }

    return HAM_IGNORED;
}

public CWeapon__Holster_Post(iWeapon)
{
    if(!IsPdataSafe(iWeapon) || !IsCustomWeapon(iWeapon)) return;

    static iPlayer; iPlayer = get_pdata_cbase(iWeapon, m_pPlayer, linux_diff_weapon);

    set_pdata_float(iWeapon, m_flNextPrimaryAttack, 0.0, linux_diff_weapon);
    set_pdata_float(iWeapon, m_flNextSecondaryAttack, 0.0, linux_diff_weapon);
    set_pdata_float(iWeapon, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
    set_pdata_float(iPlayer, m_flNextAttack, 0.0, linux_diff_player);

    #if defined CUSTOM_MUZZLEFLASH_ENABLED
    new pMuzzleFlash = FM_NULLENT;

    while((pMuzzleFlash = fm_find_ent_by_owner(pMuzzleFlash, ENTITY_MUZZLE_CLASSNAME, iPlayer)) > 0)
    if(IsPdataSafe(pMuzzleFlash)) set_pev(pMuzzleFlash, pev_flags, FL_KILLME);
    #endif
}

public CEntity__TraceAttack_Pre(iVictim, iAttacker, Float: flDamage)
{
    if(!is_user_connected(iAttacker)) return;
	
    static iWeapon; iWeapon = get_pdata_cbase(iAttacker, 373, 5);
    if(!IsPdataSafe(iWeapon) || !IsCustomWeapon(iWeapon)) return;

    flDamage *= WEAPON_SHOOT_DAMAGE
    SetHamParamFloat(3, flDamage);
}

public CWeapon__AddToPlayer_Post(iWeapon, iPlayer)
{
    if(IsPdataSafe(iWeapon) && IsCustomWeapon(iWeapon)) UTIL_WeaponList(iPlayer, true);
    else if(!pev(iWeapon, pev_impulse)) UTIL_WeaponList(iPlayer, false);
}

public CWeapon__Idle_Pre(iWeapon)
{
    if(!IsPdataSafe(iWeapon) || !IsCustomWeapon(iWeapon) || get_pdata_float(iWeapon, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	
    static iPlayer; iPlayer = get_pdata_cbase(iWeapon, m_pPlayer, linux_diff_weapon);

    UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_IDLE);
    set_pdata_float(iWeapon, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon);

    return HAM_SUPERCEDE;
}

public fm_ham_hook(bool: bEnabled)
{
    if(bEnabled)
    {
	EnableHamForward(gl_HamHook_TraceAttack[0]);
	EnableHamForward(gl_HamHook_TraceAttack[1]);
	EnableHamForward(gl_HamHook_TraceAttack[2]);
	EnableHamForward(gl_HamHook_TraceAttack[3]);
    }
    else 
    {
	DisableHamForward(gl_HamHook_TraceAttack[0]);
	DisableHamForward(gl_HamHook_TraceAttack[1]);
	DisableHamForward(gl_HamHook_TraceAttack[2]);
	DisableHamForward(gl_HamHook_TraceAttack[3]);
    }
}

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle)
{
    if(!is_user_alive(iPlayer)) return;

    static iWeapon; iWeapon = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
    if(!IsPdataSafe(iWeapon) || !IsCustomWeapon(iWeapon)) return;

    set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

public FM_Hook_SetModel_Pre(iEntity)
{
    static i, szClassName[32], iWeapon;
    pev(iEntity, pev_classname, szClassName, charsmax(szClassName));

    if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;

    for(i = 0; i < 6; i++)
    {
        iWeapon = get_pdata_cbase(iEntity, m_rgpPlayerItems_iWeaponBox + i, linux_diff_weapon);
		
        if(IsPdataSafe(iWeapon) && IsCustomWeapon(iWeapon))
        {
            engfunc(EngFunc_SetModel, iEntity, WEAPON_MODEL_WORLD);
            return FMRES_SUPERCEDE;
        }
    }

    return FMRES_IGNORED;
}

public FM_Hook_PlaybackEvent_Pre() return FMRES_SUPERCEDE;
public FM_Hook_TraceLine_Post(const Float: vecOrigin1[3], const Float: vecOrigin2[3], iFlags, iAttacker, iTrace)
{
    if(iFlags & IGNORE_MONSTERS) return FMRES_IGNORED;
    if(!is_user_alive(iAttacker)) return FMRES_IGNORED;

    static pHit; pHit = get_tr2(iTrace, TR_pHit);
    static Float: vecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, vecEndPos);

    if(pHit > 0) if(pev(pHit, pev_solid) != SOLID_BSP) return FMRES_IGNORED;


    
	// Tracer
	new Float: vecOrigin[3];
	UTIL_GetWeaponPosition(iAttacker, vecOrigin, 10.0, 11.0, -10.5);

	new Float: vecVelocity[3];
	vecVelocity[0] = vecEndPos[0] - vecOrigin[0];
	vecVelocity[1] = vecEndPos[1] - vecOrigin[1];
	vecVelocity[2] = vecEndPos[2] - vecOrigin[2];

	xs_vec_normalize(vecVelocity, vecVelocity);
	xs_vec_mul_scalar(vecVelocity, 4096.0, vecVelocity);

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_USERTRACER);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	engfunc(EngFunc_WriteCoord, vecVelocity[0]);
	engfunc(EngFunc_WriteCoord, vecVelocity[1]);
	engfunc(EngFunc_WriteCoord, vecVelocity[2]);
	write_byte(20); // Life
	write_byte(5); // Color
	write_byte(5); // Length
	message_end();

	

    engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEndPos, 0);
    write_byte(TE_WORLDDECAL);
    engfunc(EngFunc_WriteCoord, vecEndPos[0]);
    engfunc(EngFunc_WriteCoord, vecEndPos[1]);
    engfunc(EngFunc_WriteCoord, vecEndPos[2]);
    write_byte(random_num(41, 45));
    message_end();
	
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_STREAK_SPLASH);
    engfunc(EngFunc_WriteCoord, vecEndPos[0]);
    engfunc(EngFunc_WriteCoord, vecEndPos[1]);
    engfunc(EngFunc_WriteCoord, vecEndPos[2]);
    write_coord(random_num(-20, 20));
    write_coord(random_num(-20, 20));
    write_coord(random_num(-20, 20)); 
    write_byte(5);
    write_short(70);
    write_short(3);
    write_short(75);
    message_end();

    return FMRES_IGNORED;
}

/* ~ [ Entity ] ~ */
#if defined CUSTOM_MUZZLEFLASH_ENABLED
public CMuzzleFlash__Think_Pre(iSprite)
{
    if(!IsPdataSafe(iSprite)) return HAM_IGNORED;
    if(pev(iSprite, pev_classname) == gl_iszAllocString_MuzzleFlash)
    {
        static Float: flFrame;
        if(pev(iSprite, pev_frame, flFrame) && ++flFrame - 1.0 < get_pdata_float(iSprite, m_maxFrame, linux_diff_weapon))
        {
            set_pev(iSprite, pev_frame, flFrame);
            set_pev(iSprite, pev_nextthink, get_gametime() + ENTITY_MUZZLE_NEXTTHINK);
				
            return HAM_SUPERCEDE;
        }

        set_pev(iSprite, pev_flags, FL_KILLME);
        return HAM_SUPERCEDE;
    }

    return HAM_IGNORED;
}
#endif

/* ~ [ Stocks ] ~ */
stock UTIL_SendWeaponAnim(const iPlayer, const iAnim)
{
    set_pev(iPlayer, pev_weaponanim, iAnim);

    message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
    write_byte(iAnim);
    write_byte(0);
    message_end();
}

stock UTIL_DropWeapon(const iPlayer, const iSlot)
{
    static iEntity, iNext, szWeaponName[32];
    iEntity = get_pdata_cbase(iPlayer, m_rpgPlayerItems + iSlot, linux_diff_player);

    if(iEntity > 0)
    {       
        do 
        {
            iNext = get_pdata_cbase(iEntity, m_pNext, linux_diff_weapon);
            if(get_weaponname(get_pdata_int(iEntity, m_iId, linux_diff_weapon), szWeaponName, charsmax(szWeaponName)))
            engclient_cmd(iPlayer, "drop", szWeaponName);
        } 
		
        while((iEntity = iNext) > 0);
    }
}

#if defined CUSTOM_MUZZLEFLASH_ENABLED
stock UTIL_SetTransparency(iSprite, iRendermode, Float: flAmt, iFx = kRenderFxNone)
{
    set_pev(iSprite, pev_rendermode, iRendermode);
    set_pev(iSprite, pev_renderamt, flAmt);
    set_pev(iSprite, pev_renderfx, iFx);
}

stock UTIL_CreateMuzzleFlash(iPlayer, const szMuzzleSprite[], Float: flScale, Float: flBrightness, iAttachment)
{
    #define ENTITY_SPRITES_INTOLERANCE 100
    if(global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < ENTITY_SPRITES_INTOLERANCE) return FM_NULLENT;
		
    static iSprite, iszAllocStringCached;
    if(iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "env_sprite")))
    iSprite = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
		
    if(!IsPdataSafe(iSprite)) return FM_NULLENT;
		
    set_pev(iSprite, pev_model, szMuzzleSprite);
    set_pev(iSprite, pev_spawnflags, SF_SPRITE_ONCE);
		
    set_pev_string(iSprite, pev_classname, gl_iszAllocString_MuzzleFlash);
    set_pev(iSprite, pev_owner, iPlayer);
    set_pev(iSprite, pev_aiment, iPlayer);
    set_pev(iSprite, pev_body, iAttachment);
		
    UTIL_SetTransparency(iSprite, kRenderTransAdd, flBrightness);
    set_pev(iSprite, pev_scale, flScale);
		
    dllfunc(DLLFunc_Spawn, iSprite);

    return iSprite;
}
#endif

stock UTIL_WeaponList(const iPlayer, bool: bEnabled)
{
    message_begin(MSG_ONE, gl_iMsgID_Weaponlist, _, iPlayer);
    write_string(bEnabled ? WEAPON_WEAPONLIST : WEAPON_REFERENCE);
    write_byte(iWeaponList[0]);
    write_byte(bEnabled ? WEAPON_AMMO : iWeaponList[1]);
    write_byte(iWeaponList[2]);
    write_byte(iWeaponList[3]);
    write_byte(iWeaponList[4]);
    write_byte(iWeaponList[5]);
    write_byte(iWeaponList[6]);
    write_byte(iWeaponList[7]);
    message_end();
}

stock UTIL_PlayerAnimation(const iPlayer, const szAnim[]) 
{
    new iAnimDesired, Float: flFrameRate, Float: flGroundSpeed, bool: bLoops;
        
    if ((iAnimDesired = lookup_sequence(iPlayer, szAnim, flFrameRate, bLoops, flGroundSpeed)) == -1) 
    {
        iAnimDesired = 0;
    }
    
    new Float: flGametime = get_gametime();

    set_pev(iPlayer, pev_frame, 0.0);
    set_pev(iPlayer, pev_framerate, 1.0);
    set_pev(iPlayer, pev_animtime, flGametime);
    set_pev(iPlayer, pev_sequence, iAnimDesired);
    
    set_pdata_int(iPlayer, m_fSequenceLoops, bLoops, linux_diff_animation);
    set_pdata_int(iPlayer, m_fSequenceFinished, 0, linux_diff_animation);
    
    set_pdata_float(iPlayer, m_flFrameRate, flFrameRate, linux_diff_animation);
    set_pdata_float(iPlayer, m_flGroundSpeed, flGroundSpeed, linux_diff_animation);
    set_pdata_float(iPlayer, m_flLastEventCheck, flGametime , linux_diff_animation);
    
    set_pdata_int(iPlayer, m_Activity, ACT_RANGE_ATTACK1, linux_diff_player);
    set_pdata_int(iPlayer, m_IdealActivity, ACT_RANGE_ATTACK1, linux_diff_player);
    set_pdata_float(iPlayer, m_flLastAttackTime, flGametime , linux_diff_player);
}

public FakeTraceAttack(iVictim, iAttacker, Float: flDamage, Float: vecDirection[3], iTrace, ibitsDamageBits)
{
    static Float: flTakeDamage; pev(iVictim, pev_takedamage, flTakeDamage);

    if(flTakeDamage == DAMAGE_NO) return 0; 
    if(!(is_user_alive(iVictim) && zp_get_user_zombie(iVictim))) return 0;

    if(is_user_connected(iVictim)) 
    {
        if(get_pdata_int(iVictim, m_iPlayerTeam, linux_diff_player) == get_pdata_int(iAttacker, m_iPlayerTeam, linux_diff_player)) 
            return 0;
    }

    static iHitgroup; iHitgroup = get_tr2(iTrace, TR_iHitgroup);
    static Float: vecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, vecEndPos);
    static iBloodColor; iBloodColor = ExecuteHamB(Ham_BloodColor, iVictim);
    
    set_pdata_int(iVictim, m_LastHitGroup, iHitgroup, linux_diff_player);

    switch(iHitgroup) 
    {
        case HIT_HEAD:                  flDamage *= 3.0;
        case HIT_LEFTARM, HIT_RIGHTARM: flDamage *= 0.75;
        case HIT_LEFTLEG, HIT_RIGHTLEG: flDamage *= 0.75;
        case HIT_STOMACH:               flDamage *= 1.5;
    }
    
    ExecuteHamB(Ham_TakeDamage, iVictim, iAttacker, iAttacker, flDamage, ibitsDamageBits);
    
    if(zp_get_user_zombie(iVictim)) 
    {
        if(iBloodColor != DONT_BLEED) 
        {
            ExecuteHamB(Ham_TraceBleed, iVictim, flDamage, vecDirection, iTrace, ibitsDamageBits);
            UTIL_BloodDrips(vecEndPos, iBloodColor, floatround(flDamage));
        }
    }

    return 1;
}

public FakeKnockBack(iVictim, Float: vecDirection[3], Float: flKnockBack) 
{
    if(!(is_user_alive(iVictim) && zp_get_user_zombie(iVictim))) return 0;

    set_pdata_float(iVictim, m_flPainShock, 1.0, linux_diff_player);

    static Float:vecVelocity[3]; pev(iVictim, pev_velocity, vecVelocity);

    if(pev(iVictim, pev_flags) & FL_DUCKING) 
        flKnockBack *= 0.7;

    vecVelocity[0] = vecDirection[0] * flKnockBack;
    vecVelocity[1] = vecDirection[1] * flKnockBack;
    vecVelocity[2] = 200.0;

    set_pev(iVictim, pev_velocity, vecVelocity);
    
    return 1;
}


// [ Stocks ]
public UTIL_BloodDrips(Float:vecOrigin[3], iColor, iAmount) {
    if(iAmount > 255) iAmount = 255;
    
    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
    write_byte(TE_BLOODSPRITE);
    engfunc(EngFunc_WriteCoord, vecOrigin[0]);
    engfunc(EngFunc_WriteCoord, vecOrigin[1]);
    engfunc(EngFunc_WriteCoord, vecOrigin[2]);
    write_short(g_iszModelIndexBloodSpray);
    write_short(g_iszModelIndexBloodDrop);
    write_byte(iColor);
    write_byte(min(max(3,iAmount/10),16));
    message_end();
}

stock UTIL_GetWeaponPosition(iPlayer, Float: vecOrigin[3], Float: flAddForward = 0.0, Float: flAddRight = 0.0, Float: flAddUp = 0.0)
{
	static Float: vecAngles[3], Float: vecViewOfs[3];
	static Float: vecDirShooting[3], Float: vecRight[3], Float: vecUp[3];
	
	pev(iPlayer, pev_origin, vecOrigin);
	pev(iPlayer, pev_view_ofs, vecViewOfs);
	
	xs_vec_add(vecOrigin, vecViewOfs, vecOrigin);
	pev(iPlayer, pev_v_angle, vecAngles);
	engfunc(EngFunc_MakeVectors, vecAngles);
	
	global_get(glb_v_forward, vecDirShooting);
	global_get(glb_v_right, vecRight);
	global_get(glb_v_up, vecUp);
	
	xs_vec_mul_scalar(vecDirShooting, flAddForward, vecDirShooting);
	xs_vec_mul_scalar(vecRight, flAddRight, vecRight);
	xs_vec_mul_scalar(vecUp, flAddUp, vecUp);
	
	vecOrigin[0] = vecOrigin[0] + vecDirShooting[0] + vecRight[0] + vecUp[0];
	vecOrigin[1] = vecOrigin[1] + vecDirShooting[1] + vecRight[1] + vecUp[1];
	vecOrigin[2] = vecOrigin[2] + vecDirShooting[2] + vecRight[2] + vecUp[2];
}