/**
 * DamagePreviewLib
 *
 * Core utility responsible for generating detailed damage previews
 * for abilities in XCOM 2.
 *
 * Responsibilities:
 * - Aggregate damage from multiple sources (weapon, ammo, effects, upgrades)
 * - Separate normal and crit damage breakdowns
 * - Support both template-based and fallback preview systems
 * - Provide detailed per-source damage contributions
 *
 * @author Mr.Nice
 */
class DamagePreviewLib extends Object implements(EI_DamagePreviewHelperAPI);

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

// Computes minimum damage from WeaponDamageValue
`define MINDAM(WEPDAM) ( `WEPDAM.Damage - `WEPDAM.Spread )

// Computes maximum damage from WeaponDamageValue
`define MAXDAM(WEPDAM) ( `WEPDAM.Damage + `WEPDAM.Spread + int(bool(`WEPDAM.PlusOne)) )

// Resolves label string from damage modifier
`define LABELFROMMOD(MOD) class'Helpers'.static.GetMessageFromDamageModifierInfo(`MOD)

// Adds damage item into breakdown (merge or insert)
`define ADDDAMITEM(TYPE, NOTBONUS) if (DamageItem.Min!=0 || DamageItem.Max!=0) \\
	{														\\		
		i=`{TYPE}Damage.InfoList.Find('Label', DamageItem.Label); \\
		if (i!=INDEX_NONE && DamageItem.Label!="")			\\
		{													\\
			`{TYPE}Damage.InfoList[i].Min+=DamageItem.Min;	\\
			`{TYPE}Damage.InfoList[i].Max+=DamageItem.Max;	\\
			if (`{TYPE}Damage.InfoList[i].Min==0 && `{TYPE}Damage.InfoList[i].Max==0) \\
			{												\\
				`{TYPE}Damage.InfoList.Remove(i, 1);		\\
				`if (`NOTBONUS) `else `{TYPE}Damage.Bonus--; `endif \\
			}												\\
		}													\\
		else												\\
		{													\\
			`{TYPE}Damage.InfoList.AddItem(DamageItem);		\\
			`if (`NOTBONUS) `else `{TYPE}Damage.Bonus++; `endif \\
		}													\\
		`{TYPE}Damage.Min+=DamageItem.Min;					\\
		`{TYPE}Damage.Max+=DamageItem.Max;					\\
	}														\\

// Inserts damage item at beginning
`define INSERTDAMITEM(TYPE, NOTBONUS) if (DamageItem.Min!=0 || DamageItem.Max!=0) \\
	{														\\		
		i=`{TYPE}Damage.InfoList.Find('Label', DamageItem.Label); \\
		if (i!=INDEX_NONE && DamageItem.Label!="")			\\
		{													\\
			`{TYPE}Damage.InfoList[i].Min+=DamageItem.Min;	\\
			`{TYPE}Damage.InfoList[i].Max+=DamageItem.Max;	\\
			if (`{TYPE}Damage.InfoList[i].Min==0 && `{TYPE}Damage.InfoList[i].Max==0) \\
			{												\\
				`{TYPE}Damage.InfoList.Remove(i, 1);		\\
				`if (`NOTBONUS) `else `{TYPE}Damage.Bonus--; `endif \\
			}												\\
		}													\\
		else												\\
		{													\\
			`{TYPE}Damage.InfoList.InsertItem(0, DamageItem);	\\
			`if (`NOTBONUS) `else `{TYPE}Damage.Bonus++; `endif \\
		}													\\
		`{TYPE}Damage.Min+=DamageItem.Min;					\\
		`{TYPE}Damage.Max+=DamageItem.Max;					\\
	}														\\

// Adds weapon damage to both Normal and Crit
`define ADDTOBOTH(WEPDAM) DamageItem.Min=`MINDAM(`WEPDAM);	\\
	DamageItem.Max=`MAXDAM(`WEPDAM);		\\
	`ADDDAMITEM(Normal, true);					\\
	DamageItem.Min=`WEPDAM.Crit;			\\
	DamageItem.Max=`WEPDAM.Crit;			\\
	`ADDDAMITEM(Crit, true)						\\

// Inserts weapon damage to both Normal and Crit
`define INSERTTOBOTH(WEPDAM) DamageItem.Min=`MINDAM(`WEPDAM);	\\
	DamageItem.Max=`MAXDAM(`WEPDAM);		\\
	OriginalPierce+=`WEPDAM.Pierce;         \\
	`INSERTDAMITEM(Normal, true);					\\
	DamageItem.Min=`WEPDAM.Crit;			\\
	DamageItem.Max=`WEPDAM.Crit;			\\
	`INSERTDAMITEM(Crit, true)					\\

/**
 * Entry point for damage preview calculation.
 *
 * @param AbilityState   Ability being evaluated
 * @param TargetRef      Target reference
 * @param NormalDamage   Output normal damage breakdown
 * @param CritDamage     Output crit damage breakdown
 */
static function GetDamagePreview(XComGameState_Ability AbilityState, StateObjectReference TargetRef, optional out DamageBreakdown NormalDamage, optional out DamageBreakdown CritDamage)
{
	local X2AbilityTemplate AbilityTemplate;
	local EI_DamagePreviewTemplateAPI EIPreview;
	local int AllowsShield;
	local string AbilityName;

	`TRACE_ENTRY("TargetRef.ObjectID:" @ TargetRef.ObjectID);

	if (AbilityState == none)
	{
		`TRACE_IF("AbilityState == none");
		`TRACE_EXIT("");
		return;
	}

	AbilityName = AbilityState.GetMyFriendlyName();
	`TRACE("AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));

	AbilityTemplate = AbilityState.GetMyTemplate();
	EIPreview = EI_DamagePreviewTemplateAPI(AbilityTemplate);
	if (EIPreview!=none)
	{
		`TRACE_IF("EIPreview != none. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
		if (EIPreview.EIDamagePreviewFn(EI_DamagePreviewHelperAPI(class'XComEngine'.static.GetClassDefaultObject(default.class)), AbilityState, TargetRef, NormalDamage, CritDamage, AllowsShield))
		{
			`TRACE_EXIT("Used EIPreview. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
			return;
		}
	}
	if (AbilityTemplate.DamagePreviewFn != none)
	{
		`TRACE_IF("AbilityTemplate.DamagePreviewFn != none. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
		if (DamagePreviewFnHandler(AbilityState, AbilityTemplate, TargetRef, NormalDamage, CritDamage, AllowsShield))
		{
			`TRACE_EXIT("Used Template Fn. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
			return;
		}
	}
	NormalAbilityDamagePreview(AbilityState, TargetRef, NormalDamage, CritDamage, AllowsShield);
	`DEBUG("AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
	`TRACE_EXIT("AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
}

/**
 * Handles template-based damage preview function.
 */
static function bool DamagePreviewFnHandler(XComGameState_Ability AbilityState, X2AbilityTemplate AbilityTemplate, StateObjectReference TargetRef, out DamageBreakdown NormalDamage, out DamageBreakdown CritDamage, out int AllowsShield)
{
	local WeaponDamageValue	MinDamagePreview, MaxDamagePreview;
	local int i;
	local bool ReturnVal;
	local DamageModifierInfo DamageModInfo;
	local DamageInfo DamageItem, BalanceItem;
	local string AbilityName;

	`TRACE_ENTRY("TargetRef.ObjectID:" @ TargetRef.ObjectID );
	AbilityName = AbilityState.GetMyFriendlyName();
	`TRACE("Before AbilityTemplate.DamagePreviewFn. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));

	ReturnVal = AbilityTemplate.DamagePreviewFn(AbilityState, TargetRef, MinDamagePreview, MaxDamagePreview, AllowsShield);

	`TRACE("After AbilityTemplate.DamagePreviewFn. ReturnVal:" @ ReturnVal $ ", AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));

	BalanceItem.Label = AbilityName;
	BalanceItem.Min = MinDamagePreview.Damage;
	BalanceItem.Max = MaxDamagePreview.Damage;

	`TRACE("AbilityState.GetMyFriendlyName():" @ AbilityName $ ", BalanceItem:" @ DamageInfoToString(BalanceItem));

	foreach MinDamagePreview.BonusDamageInfo(DamageModInfo)
	{
		DamageItem.Min = DamageModInfo.Value;
		BalanceItem.Min -= DamageItem.Min;
		DamageItem.Label = `LABELFROMMOD(DamageModInfo);
		`ADDDAMITEM(Normal);
		`TRACE("Added Damage Item. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", BalanceItem:" @ DamageInfoToString(BalanceItem));
	}

	DamageItem.Min=0;
	foreach MaxDamagePreview.BonusDamageInfo(DamageModInfo)
	{
		DamageItem.Max=DamageModInfo.Value;
		BalanceItem.Max-=DamageItem.Max;
		DamageItem.Label=`LABELFROMMOD(DamageModInfo);
		`ADDDAMITEM(Normal);
		`TRACE("Added Damage Item. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", BalanceItem:" @ DamageInfoToString(BalanceItem));
	}

	DamageItem=BalanceItem;
	`INSERTDAMITEM(Normal, true);
	
	DamageItem.Min = MinDamagePreview.Crit;
	DamageItem.Max = MaxDamagePreview.Crit;
	`ADDDAMITEM(Crit, true);
	
	`TRACE_EXIT("ReturnVal:" @ ReturnVal $ ", AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
	return ReturnVal;
}

/**
 * Default fallback damage preview logic.
 */
static function NormalAbilityDamagePreview(XComGameState_Ability AbilityState, StateObjectReference TargetRef, out DamageBreakdown NormalDamage, out DamageBreakdown CritDamage, out int AllowsShield)
{
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityMultiTarget_BurstFire BurstFire;
	local WeaponDamageValue	MinDamagePreview, MaxDamagePreview, EmptyDamagePreview;
	local array<X2Effect> TargetEffects;
	local XComGameState_BaseObject TargetObj;
	local Damageable DamageableTarget;
	local int i, Rupture;
	local bool bAsPrimaryTarget;
	local DamageModifierInfo DamageModInfo;
	local X2Effect Effect;
	local DamageInfo DamageItem, BalanceItem;
	local string AbilityName;

	`TRACE_ENTRY("TargetRef.ObjectID:" @ TargetRef.ObjectID );

	if (AbilityState==none)
	{
		`TRACE_IF("AbilityState == none");
		`TRACE_EXIT("");
		return;
	}
	AbilityName = AbilityState.GetMyFriendlyName();
	`TRACE("AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));

	AbilityTemplate = AbilityState.GetMyTemplate();
	BalanceItem.Label = AbilityName;

	if (TargetRef.ObjectID > 0)
	{
		`TRACE_IF("TargetRef.ObjectID > 0");
		TargetEffects = AbilityTemplate.AbilityTargetEffects;
		TargetObj = `XCOMHISTORY.GetGameStateForObjectID(TargetRef.ObjectID);
		if (TargetObj != none)
		{
			`TRACE_IF("TargetObj != none");
			//DestructibleState = XComGameState_Destructible(TargetObj);
			DamageableTarget = Damageable(TargetObj);
			if (DamageableTarget != none)
			{
				`TRACE_IF("DamageableTarget != none");
				Rupture = DamageableTarget.GetRupturedValue();
			}
		}
		bAsPrimaryTarget = true;
	}
	else if (AbilityTemplate.bUseLaunchedGrenadeEffects)
	{
		`TRACE_IF("AbilityTemplate.bUseLaunchedGrenadeEffects");
		TargetEffects = X2GrenadeTemplate(AbilityState.GetSourceWeapon().GetLoadedAmmoTemplate(AbilityState)).LaunchedGrenadeEffects;
	}
	else if (AbilityTemplate.bUseThrownGrenadeEffects)
	{
		`TRACE_IF("AbilityTemplate.bUseThrownGrenadeEffects");
		TargetEffects = X2GrenadeTemplate(ABilityState.GetSourceWeapon().GetMyTemplate()).ThrownGrenadeEffects;
	}
	else
	{
		TargetEffects = AbilityTemplate.AbilityMultiTargetEffects;
	}

	foreach TargetEffects(Effect)
	{
		if (!X2Effect_ApplyWeaponDamage(Effect).bApplyOnHit)
		{
			`TRACE_IF("!X2Effect_ApplyWeaponDamage(Effect).bApplyOnHit");
			MinDamagePreview=EmptyDamagePreview;
			MaxDamagePreview=EmptyDamagePreview;
			Effect.GetDamagePreview(TargetRef, AbilityState, bAsPrimaryTarget, MinDamagePreview , MaxDamagePreview, AllowsShield);

			BalanceItem.Min=MinDamagePreview.Damage;
			BalanceItem.Max=MaxDamagePreview.Damage;

			DamageItem.Max=0;
			foreach MinDamagePreview.BonusDamageInfo(DamageModInfo)
			{
				DamageItem.Min = DamageModInfo.Value;
				BalanceItem.Min -= DamageItem.Min;
				DamageItem.Label = `LABELFROMMOD(DamageModInfo);
				`ADDDAMITEM(Normal);
				`TRACE("Added Damage Item. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", BalanceItem:" @ DamageInfoToString(BalanceItem));
			}

			DamageItem.Min=0;
			foreach MaxDamagePreview.BonusDamageInfo(DamageModInfo)
			{
				DamageItem.Max=DamageModInfo.Value;
				BalanceItem.Max-=DamageItem.Max;
				DamageItem.Label=`LABELFROMMOD(DamageModInfo);
				`ADDDAMITEM(Normal);
				`TRACE("Added Damage Item. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", BalanceItem:" @ DamageInfoToString(BalanceItem));
			}

			DamageItem=BalanceItem;
			`ADDDAMITEM(Normal, true);
	
			DamageItem.Min = MinDamagePreview.Crit;
			DamageItem.Max = MaxDamagePreview.Crit;
			//DamageItem.Label=AbilityName;
			`ADDDAMITEM(Crit, true);
		}
		else
			GetWeaponDamagePreview(X2Effect_ApplyWeaponDamage(Effect), TargetRef, AbilityState, bAsPrimaryTarget, NormalDamage, CritDamage, AllowsShield);
	}

	`TRACE("After foreach TargetEffects(Effect). AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));

	if (AbilityTemplate.AbilityMultiTargetStyle != none)
	{
		`TRACE_IF("AbilityTemplate.AbilityMultiTargetStyle != none");
		BurstFire = X2AbilityMultiTarget_BurstFire(AbilityTemplate.AbilityMultiTargetStyle);
		if (BurstFire != none)
		{
			`TRACE_IF("BurstFire != none");
			NormalDamage.Min += NormalDamage.Min * BurstFire.NumExtraShots;
			NormalDamage.Max += NormalDamage.Max * BurstFire.NumExtraShots;
			CritDamage.Min += CritDamage.Min * BurstFire.NumExtraShots;
			CritDamage.Max += CritDamage.Max * BurstFire.NumExtraShots;
			`TRACE("Adjusted damage based on BurstFire. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", DamageItem:" @ DamageInfoToString(DamageItem));
		}
	}
	if (Rupture > 0)
	{
		`TRACE_IF("Rupture > 0");
		DamageItem.Min = Rupture;
		DamageItem.Max = Rupture;
		DamageItem.Label = class'X2StatusEffects'.default.RupturedFriendlyName;
		`ADDDAMITEM(Normal);
		`TRACE("Added Damage Item. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", DamageItem:" @ DamageInfoToString(DamageItem));
	}
	`TRACE_EXIT("AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
}

/**
 * Core weapon damage calculation logic.
 */
static function GetWeaponDamagePreview(X2Effect_ApplyWeaponDamage WepDamEffect, StateObjectReference TargetRef, XComGameState_Ability AbilityState, bool bAsPrimaryTarget, out DamageBreakdown NormalDamage, out DamageBreakdown CritDamage, out int AllowsShield)
{
	local XComGameStateHistory History;
	local XComGameState_Unit TargetUnit, SourceUnit;
	local XComGameState_Item SourceWeapon, LoadedAmmo;
	local WeaponDamageValue BaseDamageValue, ExtraDamageValue, AmmoDamageValue, BonusEffectDamageValue, UpgradeDamageValue;
	local X2Condition ConditionIter;
	local name AvailableCode;
	local X2AmmoTemplate AmmoTemplate;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent EffectTemplate;
	local int i;
	local EffectAppliedData TestEffectParams;
	local name DamageType;
	local array<X2WeaponUpgradeTemplate> WeaponUpgradeTemplates;
	local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
	local array<Name> AppliedDamageTypes;
	local bool bDoesDamageIgnoreShields;

	local DamageInfo DamageItem, DamageItemCrit;
	//local DamageModifierInfo DamageModInfo;
	local string AbilityName;

	// Begin CHL Issue #1540 - variables for cover DR	
	local int OriginalMitigation, OriginalPierce;
	// End CHL Issue #1540

	local int IgnoreArmor, IgnoreShields; // CHL Issue #1542

	`TRACE_ENTRY("TargetRef.ObjectID:" @ TargetRef.ObjectID $ ", bAsPrimaryTarget:" @ bAsPrimaryTarget);

	bDoesDamageIgnoreShields = WepDamEffect.bBypassShields;

	History=`XCOMHistory;

	if (AbilityState.SourceAmmo.ObjectID > 0)
		SourceWeapon = AbilityState.GetSourceAmmo();
	else
		SourceWeapon = AbilityState.GetSourceWeapon();

	AbilityName=AbilityState.GetMyFriendlyName();

	`TRACE("AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
	
	TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(TargetRef.ObjectID));
	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));

	`TRACE("HasTargetUnit:" @ (TargetUnit != none) $ ", HasSourceUnit:" @ (SourceUnit != none));

	if (TargetUnit != None)
	{
		`TRACE_IF("TargetUnit != none");
		foreach WepDamEffect.TargetConditions(ConditionIter)
		{
			AvailableCode = ConditionIter.AbilityMeetsCondition(AbilityState, TargetUnit);
			if (AvailableCode != 'AA_Success')
			{
				`TRACE_EXIT("AvailableCode != 'AA_Success'");
				return;
			}
			AvailableCode = ConditionIter.MeetsCondition(TargetUnit);
			if (AvailableCode != 'AA_Success')
			{
				`TRACE_EXIT("AvailableCode != 'AA_Success'");
				return;
			}
			AvailableCode = ConditionIter.MeetsConditionWithSource(TargetUnit, SourceUnit);
			if (AvailableCode != 'AA_Success')
			{
				`TRACE_EXIT("AvailableCode != 'AA_Success'");
				return;
			}
		}
		foreach WepDamEffect.DamageTypes(DamageType)
		{
			if (TargetUnit.IsImmuneToDamage(DamageType))
			{
				`TRACE_EXIT("TargetUnit.IsImmuneToDamage(DamageType)");
				return;
			}
		}
	}

	if (WepDamEffect.bAlwaysKillsCivilians && TargetUnit != None && TargetUnit.GetTeam() == eTeam_Neutral)
	{
		`TRACE_IF("WepDamEffect.bAlwaysKillsCivilians && TargetUnit != None && TargetUnit.GetTeam() == eTeam_Neutral");
		DamageItem.Label=AbilityName;
		DamageItem.Min=TargetUnit.GetCurrentStat(eStat_HP) + TargetUnit.GetCurrentStat(eStat_ShieldHP) - NormalDamage.Min;
		DamageItem.Max=TargetUnit.GetCurrentStat(eStat_HP) + TargetUnit.GetCurrentStat(eStat_ShieldHP) - NormalDamage.Max;
		`ADDDAMITEM(Normal);
		`TRACE("Added Damage Item. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", DamageItem:" @ DamageInfoToString(DamageItem));
		`TRACE_EXIT("AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
		return;
	}

	BonusEffectDamageValue = WepDamEffect.GetBonusEffectDamageValue(AbilityState, SourceUnit, SourceWeapon, TargetRef);
	WepDamEffect.ModifyDamageValue(BonusEffectDamageValue, TargetUnit, AppliedDamageTypes);
	DamageItem.Label=AbilityName;
	`INSERTTOBOTH(BonusEffectDamageValue);
	`TRACE("Added BonusEffectDamageValue. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));

	if (SourceWeapon != None)
	{
		`TRACE_IF("SourceWeapon != None");
		if (WepDamEffect.bAllowWeaponUpgrade)
		{
			`TRACE_IF("WepDamEffect.bAllowWeaponUpgrade");
			WeaponUpgradeTemplates = SourceWeapon.GetMyWeaponUpgradeTemplates();
			foreach WeaponUpgradeTemplates(WeaponUpgradeTemplate)
			{
				if (WeaponUpgradeTemplate.BonusDamage.Tag == WepDamEffect.DamageTag)
				{
					`TRACE_IF("WeaponUpgradeTemplate.BonusDamage.Tag == WepDamEffect.DamageTag");
					UpgradeDamageValue = WeaponUpgradeTemplate.BonusDamage;

					WepDamEffect.ModifyDamageValue(UpgradeDamageValue, TargetUnit, AppliedDamageTypes);

					UpgradeDamageValue.PlusOne=0;
					DamageItem.Label=WeaponUpgradeTemplate.GetItemFriendlyName();
					`INSERTTOBOTH(UpgradeDamageValue);
					`TRACE("Added UpgradeDamageValue. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
				}
			}
		}

		// Treat new CH upgrade damage as base damage unless a tag is specified
		if (!WepDamEffect.bAllowWeaponUpgrade)
		{
			`TRACE_IF("!WepDamEffect.bAllowWeaponUpgrade");
			WeaponUpgradeTemplates = SourceWeapon.GetMyWeaponUpgradeTemplates();
		}
		foreach WeaponUpgradeTemplates(WeaponUpgradeTemplate)
		{
			if ((!WepDamEffect.bIgnoreBaseDamage && WepDamEffect.DamageTag == '') || WeaponUpgradeTemplate.CHBonusDamage.Tag == WepDamEffect.DamageTag)
			{
				`TRACE_IF("(!WepDamEffect.bIgnoreBaseDamage && WepDamEffect.DamageTag == '') || WeaponUpgradeTemplate.CHBonusDamage.Tag == WepDamEffect.DamageTag");
				UpgradeDamageValue = WeaponUpgradeTemplate.CHBonusDamage;

				WepDamEffect.ModifyDamageValue(UpgradeDamageValue, TargetUnit, AppliedDamageTypes);

				UpgradeDamageValue.PlusOne=0;
				DamageItem.Label=WeaponUpgradeTemplate.GetItemFriendlyName();
				`INSERTTOBOTH(UpgradeDamageValue);
				`TRACE("Added UpgradeDamageValue. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
			}
		}

		if (SourceWeapon.HasLoadedAmmo() && !WepDamEffect.bIgnoreBaseDamage)
		{
			`TRACE_IF("SourceWeapon.HasLoadedAmmo() && !WepDamEffect.bIgnoreBaseDamage");
			LoadedAmmo = XComGameState_Item(History.GetGameStateForObjectID(SourceWeapon.LoadedAmmo.ObjectID));
			AmmoTemplate = X2AmmoTemplate(LoadedAmmo.GetMyTemplate()); 
			if (AmmoTemplate != None)
			{
				`TRACE_IF("AmmoTemplate != None");
				AmmoTemplate.GetTotalDamageModifier(LoadedAmmo, SourceUnit, TargetUnit, AmmoDamageValue);
				bDoesDamageIgnoreShields = AmmoTemplate.bBypassShields || bDoesDamageIgnoreShields;
			}
			else
			{
				`TRACE_IF("AmmoTemplate == None");
				LoadedAmmo.GetBaseWeaponDamageValue(TargetUnit, AmmoDamageValue);
			}
			WepDamEffect.ModifyDamageValue(AmmoDamageValue, TargetUnit, AppliedDamageTypes);
			DamageItem.Label=LoadedAmmo.GetMyTemplate().GetItemFriendlyName(LoadedAmmo.ObjectID);
			`INSERTTOBOTH(AmmoDamageValue);
			`TRACE("Added AmmoDamageValue. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
		}

		if (!WepDamEffect.bIgnoreBaseDamage)
		{
			`TRACE_IF("!WepDamEffect.bIgnoreBaseDamage");
			SourceWeapon.GetBaseWeaponDamageValue(TargetUnit, BaseDamageValue);
			WepDamEffect.ModifyDamageValue(BaseDamageValue, TargetUnit, AppliedDamageTypes);
			DamageItem.Label=SourceWeapon.GetMyTemplate().GetItemFriendlyName(SourceWeapon.ObjectID);
			`INSERTTOBOTH(BaseDamageValue);
			`TRACE("Added BaseDamageValue. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
		}
		if (WepDamEffect.DamageTag != '')
		{
			`TRACE_IF("WepDamEffect.DamageTag != ''");
			SourceWeapon.GetWeaponDamageValue(TargetUnit, WepDamEffect.DamageTag, ExtraDamageValue);
			WepDamEffect.ModifyDamageValue(ExtraDamageValue, TargetUnit, AppliedDamageTypes);
			DamageItem.Label=SourceWeapon.GetMyTemplate().GetItemFriendlyName(SourceWeapon.ObjectID);
			`INSERTTOBOTH(ExtraDamageValue);
			`TRACE("Added ExtraDamageValue. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
		}
	}

	TestEffectParams.AbilityInputContext.AbilityRef = AbilityState.GetReference();
	TestEffectParams.AbilityInputContext.AbilityTemplateName = AbilityState.GetMyTemplateName();
	TestEffectParams.ItemStateObjectRef = AbilityState.SourceWeapon;
	TestEffectParams.AbilityStateObjectRef = AbilityState.GetReference();
	TestEffectParams.SourceStateObjectRef = SourceUnit.GetReference();
	TestEffectParams.PlayerStateObjectRef = SourceUnit.ControllingPlayer;
	TestEffectParams.TargetStateObjectRef = TargetRef;
	if (bAsPrimaryTarget)
	{
		`TRACE_IF("bAsPrimaryTarget");
		TestEffectParams.AbilityInputContext.PrimaryTarget = TargetRef;
	}

	// Tigrik: Add missing damage modifiers. Account for CHL #923
	ApplyPreDefaultDamageModifierEffects(History, SourceUnit, TargetUnit, AbilityState, TestEffectParams, DamageItem, DamageItemCrit, NormalDamage, CritDamage, WepDamEffect);

	if (TargetUnit != none)
	{
		`TRACE_IF("TargetUnit != none");
		foreach TargetUnit.AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			EffectTemplate = EffectState.GetX2Effect();
			DamageItem.Label=EffectTemplate.GetSpecialDamageMessageName();
			DamageItemCrit.Label=DamageItem.Label;

			TestEffectParams.AbilityResultContext.HitResult = eHit_Success;
			DamageItem.Min = EffectTemplate.GetBaseDefendingDamageModifier(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TestEffectParams, NormalDamage.Min, WepDamEffect);
			DamageItem.Max = EffectTemplate.GetBaseDefendingDamageModifier(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TestEffectParams, NormalDamage.Max, WepDamEffect);
			
			DamageItemCrit.Min=-DamageItem.Min;
			DamageItemCrit.Max=-DamageItem.Max;
			TestEffectParams.AbilityResultContext.HitResult = eHit_Crit;
			DamageItemCrit.Min += EffectTemplate.GetBaseDefendingDamageModifier(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TestEffectParams, NormalDamage.Min+CritDamage.Min, WepDamEffect);
			DamageItemCrit.Max += EffectTemplate.GetBaseDefendingDamageModifier(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TestEffectParams, NormalDamage.Max+CritDamage.Max, WepDamEffect);
			`ADDDAMITEM(Normal);
			DamageItem=DamageItemCrit;
			`ADDDAMITEM(Crit);
			`TRACE("Adjusted for TargetUnit.AffectedByEffects. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
		}
	}

	foreach SourceUnit.AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		EffectTemplate = EffectState.GetX2Effect();

		DamageItem.Label=EffectTemplate.GetSpecialDamageMessageName();
		DamageItemCrit.Label=DamageItem.Label;

		TestEffectParams.AbilityResultContext.HitResult = eHit_Success;
		DamageItem.Min = EffectTemplate.GetAttackingDamageModifier_CH(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TestEffectParams, NormalDamage.Min, WepDamEffect);
		DamageItem.Max = EffectTemplate.GetAttackingDamageModifier_CH(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TestEffectParams, NormalDamage.Max, WepDamEffect);
			
		DamageItemCrit.Min=-DamageItem.Min;
		DamageItemCrit.Max=-DamageItem.Max;
		TestEffectParams.AbilityResultContext.HitResult = eHit_Crit;
		DamageItemCrit.Min += EffectTemplate.GetAttackingDamageModifier_CH(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TestEffectParams, NormalDamage.Min+CritDamage.Min, WepDamEffect);
		DamageItemCrit.Max += EffectTemplate.GetAttackingDamageModifier_CH(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TestEffectParams, NormalDamage.Max+CritDamage.Max, WepDamEffect);
		`ADDDAMITEM(Normal);
		DamageItem=DamageItemCrit;
		`ADDDAMITEM(Crit);
		`TRACE("Adjusted for SourceUnit.AffectedByEffects. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
	}

	if (TargetUnit != none)
	{
		`TRACE_IF("TargetUnit != none");
		foreach TargetUnit.AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			EffectTemplate = EffectState.GetX2Effect();
			DamageItem.Label=EffectTemplate.GetSpecialDamageMessageName();
			DamageItemCrit.Label=DamageItem.Label;

			TestEffectParams.AbilityResultContext.HitResult = eHit_Success;

			DamageItem.Min = EffectTemplate.GetDefendingDamageModifier(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TestEffectParams, NormalDamage.Min, WepDamEffect);
			DamageItem.Max = EffectTemplate.GetDefendingDamageModifier(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TestEffectParams, NormalDamage.Max, WepDamEffect);
			
			DamageItemCrit.Min=-DamageItem.Min;
			DamageItemCrit.Max=-DamageItem.Max;
			TestEffectParams.AbilityResultContext.HitResult = eHit_Crit;
			DamageItemCrit.Min += EffectTemplate.GetDefendingDamageModifier(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TestEffectParams, NormalDamage.Min+CritDamage.Min, WepDamEffect);
			DamageItemCrit.Max += EffectTemplate.GetDefendingDamageModifier(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TestEffectParams, NormalDamage.Max+CritDamage.Max, WepDamEffect);
			`ADDDAMITEM(Normal);
			DamageItem=DamageItemCrit;
			`ADDDAMITEM(Crit);
			`TRACE("Adjusted for TargetUnit.AffectedByEffects. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
		}
	}

	// Tigrik: Add missing damage modifiers. Account for CHL #923
	ApplyPostDefaultDamageModifierEffects(History, SourceUnit, TargetUnit, AbilityState, TestEffectParams, DamageItem, DamageItemCrit, NormalDamage, CritDamage, WepDamEffect);

	// Dalo: Start CHL Issue #1542
	IgnoreArmor = bIgnoreArmor ? 1 : 0;
	IgnoreShields = bDoesDamageIgnoreShields ? 1 : 0;
	class'CHHelpers'.static.GetCDO().TriggerOverrideDefenseBypass(AppliedDamageTypes, IgnoreArmor, IgnoreShields, TestEffectParams, self);
	`TRACE("Invoked TriggerOverrideDefenseBypass. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", Original Armor/Shield Ignores:" @ bIgnoreArmor $ "/" $ bDoesDamageIgnoreShields $ ", Overridden Ignores:" @ IgnoreArmor > 0 $ "/" $ IgnoreShields > 0);
	bDoesDamageIgnoreShields = IgnoreShields > 0;
	// End CHL Issue #1542
	
	if (!bDoesDamageIgnoreShields)
	{
		`TRACE_IF("!bDoesDamageIgnoreShields");
		AllowsShield += NormalDamage.Max;
	}

	// Dalo: Begin CHL Issue #1540 - preview armor DR
	// TODO: Only run this code if the appropriate MCM option is enabled!
	if (TargetUnit != none && IgnoreArmor == 0 && NormalDamage.Min > 0)
	{
		`TRACE_IF("TargetUnit != none && !bIgnoreArmor && NormalDamage.Min > 0");
		// Dalo: The original mitigation (and original minimum mitigation, i.e. 0)
		// are shared across both damage values, so can be initialized here.
		OriginalMitigation = TargetUnit.GetArmorMitigationForUnitFlag();
		AppliedMandatoryMitigationMin = 0;
		AppliedMandatoryMitigationMax = 0;
		DamageItem.Label = class'XGLocalizedData'.default.ArmorMitigation;
		DamageItemCrit.Label = DamageItem.Label;

		DamageItem.Min = NormalDamage.Min;
		DamageItem.Max = NormalDamage.Max;
		CalculateArmorMitigation(
			OriginalMitigation, 
			OriginalPierce, 
			TestEffectParams, 
			WepDamEffect, 
			AppliedMandatoryMitigationMin,
			AppliedMandatoryMitigationMax,
			DamageItem
		);
		`INSERTDAMITEM(Normal);

		DamageItemCrit.Min = CritDamage.Min;
		DamageItemCrit.Max = CritDamage.Max;
		CalculateArmorMitigation(
			OriginalMitigation,
			OriginalPierce,
			TestEffectParams,
			WepDamEffect,
			AppliedMandatoryMitigationMin,
			AppliedMandatoryMitigationMax,
			DamageItemCrit
		);
		// Dalo: Only factor *extra* mitigation (if any) into crit damage!
		// Theoretically, I suppose a mod could cause this to overflow.
		// I do not know how, but if they do, that's probably fair play?
		DamageItemCrit.Min -= DamageItem.Min;
		DamageItemCrit.Max -= DamageItem.Max;
		DamageItem = DamageItemCrit;
		`INSERTDAMITEM(Crit);	
		`TRACE("Invoked AdjustArmorMitigation. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
	}
	// End CHL Issue #1540
	
	`TRACE_EXIT("AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
}

/**
 * Dalo: Helper function to handle CHL #1540. 
 *
 * A port of the #1540 armor preview pipeline to EIR. Results should be
 * identical to the code I wrote for the Highlander's {@code X2Effect_ApplyWeaponDamage::GetDamagePreview},
 * but this has been optimized for EIR's codebase... to some extent.
 * 
 * The function operates on only one hit context (normal or critical) in order to minimize code reuse.
 * Handling the resulting mitigation item for that context is left to the caller.
 *
 * Notes:
 * - At call time, {@code DamageItem} should contain the final unmitigated damage values for its context,
 *   to more accurately calculate mitigation (e.g. if resisting a percentage of incoming damage).
 * - Upon completion, {@code DamageItem} will contain the final mitigation values for its context,
 *   after piercing and minimum mitigation have been applied.
 *
 * @param OriginalMitigation			How much unmodified armor the unit had before we started calculating.
 * @param OriginalPierce				How much piercing the attack had before we started calculating.
 * @param AllowsShield					How much shield damage the attack is allowed to deal, required by the CHL helper for issue #743
 * @param TestEffectParams				Effect application context, including hit result state.
 * @param WepDamEffect					Weapon damage effect context (passed to CHL callback; may be unused).
 * @param AppliedMandatoryMitigationMin	How much mandatory mitigation has been applied to minimum damage by a previous context (to prevent double-dipping).
 * @param AppliedMandatoryMitigationMax As above, but for maximum damage.
 * @param DamageItem					Damage breakdown item 
 */
static function CalculateArmorMitigation(
	int OriginalMitigation, 
	int OriginalPierce, 
	int AllowsShield,
	EffectAppliedData TestEffectParams, 
	X2Effect_ApplyWeaponDamage WepDamEffect,
	out int AppliedMandatoryMitigationMin, 
	out int AppliedMandatoryMitigationMax,
	out DamageInfo DamageItem
) { 
	// My CH helper expects mitigation data to come in a WDV.
	local WeaponDamageValue MinDamagePreview, MaxDamagePreview;

	// It seems that passing struct values as out parameters to a function
	// prevents them from being edited by the function,
	// so we need a few extra variables to store the data...
	local int MinPierce, MaxPierce;
	local int MinMandatoryMitigation, MaxMandatoryMitigation;
	local int NetMitigationMin, NetMitigationMax;

	// Unused in this context, but the helper expects to write to them.
	local int _MinDamage, _MaxDamage; 

	// Init the WDVs for the helper.
	MinDamagePreview.Damage = DamageItem.Min;
	MaxDamagePreview.Damage = DamageItem.Max;

	// Get adjusted mitigation, piercing, and minimum mitigation
	// for the attack's minimum damage.
	MinMitigation = OriginalMitigation;
	MinPierce = OriginalPierce;
	MinMandatoryMitigation = 0;
	class'CHHelpers'.static.GetCDO().TriggerAdjustArmorMitigation(
		MinDamagePreview.Damage,
		MinMitigation,
		MinPierce,
		MinMandatoryMitigation, // Starts at 0
		TestEffectParams,
		WepDamEffect,
		// Tells the event handlers that this is a minimum damage preview.
		// (The absence of a game state tells them it's *a* damage preview.)
		true
	);
	MinDamagePreview.Spread = MinMitigation;
	MinDamagePreview.Pierce = MinPierce;
	MinDamagePreview.PlusOne = MinMandatoryMitigation - AppliedMandatoryMitigationMin;
	
	// Now do the same for the attack's maximum damage.
	MaxMitigation = OriginalMitigation;
	MaxPierce = OriginalPierce;
	MaxMandatoryMitigation = 0;
	class'CHHelpers'.static.GetCDO().TriggerAdjustArmorMitigation(
		MaxDamagePreview.Damage,
		MaxMitigation,
		MaxPierce,
		MaxMandatoryMitigation, // Starts at 0
		TestEffectParams,
		WepDamEffect
	);
	MaxDamagePreview.Spread = MaxMitigation;
	MaxDamagePreview.Pierce = MaxPierce;
	MaxDamagePreview.PlusOne = MaxMandatoryMitigation - AppliedMandatoryMitigationMax;	

	// Now that we're done adjusting the raw values, let's crunch them into real-(game)-world outcomes!
	class'CHHelpers'.static.CalculateMitigatedDamagePreview(
		TestEffectParams.TargetStateObjectRef,
		MinDamagePreview,
		MaxDamagePreview,
		AllowsShield,
		_MinDamage,
		_MaxDamage,
		NetMitigationMin,
		NetMitigationMax,
	);

	// ... And prepare our output data!
	AppliedMandatoryMitigationMin += min(MinMandatoryMitigation, NetMitigationMin);
	AppliedMandatoryMitigationMax += min(MaxMandatoryMitigation, NetMitigationMax);
	DamageItem.Min = NetMitigationMin;
	DamageItem.Max = NetMitigationMax;
}

/**
 * Tigrik: Add missing damage modifiers. Account for CHL #923
 * 
 * Applies pre-default (Highlander) damage modifier effects to both attacking and defending units,
 * updating the provided damage breakdown structures for normal and critical damage.
 *
 * This function mirrors the behavior of the Community Highlander damage pipeline by executing
 * {@code GetPreDefaultAttackingDamageModifier_CH} and
 * {@code GetPreDefaultDefendingDamageModifier_CH} for all active effects on the source and target.
 * It accumulates incremental damage changes, tracks per-effect contributions, and updates the
 * {@code DamageBreakdown} structures accordingly.
 *
 * The function operates on both normal and critical hit contexts by temporarily modifying
 * {@code ApplyEffectParameters.AbilityResultContext.HitResult}. It computes delta-based changes
 * using running ("current") damage values to ensure correct stacking behavior, then truncates
 * the final differences to match XCOM 2�s integer damage handling.
 *
 * Damage contributions are recorded into {@code NormalDamage} and {@code CritDamage} via macros
 * (e.g. {@code ADDDAMITEM}), which merge or insert labeled {@code DamageInfo} entries.
 *
 * Notes:
 * - Uses truncation (not rounding) when finalizing damage differences for consistency with base game logic.
 * - May produce per-effect sums that do not exactly match total damage due to truncation.
 * - Relies on Highlander-specific CH functions; effects not implementing them will contribute 0.
 * - Modifies {@code DamageItem} and {@code DamageItemCrit} as working buffers during iteration.
 *
 * @param History                Game state history used to resolve effect states.
 * @param SourceUnit             The attacking unit whose effects may modify outgoing damage.
 * @param Target                 The damageable target (may or may not be a unit).
 * @param AbilityState           The ability being evaluated for damage preview.
 * @param ApplyEffectParameters  Effect application context, including hit result state (modified during execution).
 * @param DamageItem             Working structure for normal damage contributions (modified in-place).
 * @param DamageItemCrit         Working structure for critical damage contributions (modified in-place).
 * @param NormalDamage           Accumulated breakdown of normal damage (updated in-place).
 * @param CritDamage             Accumulated breakdown of critical damage (updated in-place).
 * @param WepDamEffect           Weapon damage effect context (passed to CH modifier functions; may be unused).
 * @param NewGameState           Optional game state for simulation context (may be none).
 */
static function ApplyPreDefaultDamageModifierEffects(
	XComGameStateHistory History,
	XComGameState_Unit SourceUnit,
	Damageable Target,
	XComGameState_Ability AbilityState,
	out EffectAppliedData ApplyEffectParameters,
	out DamageInfo DamageItem,
	out DamageInfo DamageItemCrit,
	out DamageBreakdown NormalDamage, 
	out DamageBreakdown CritDamage,
	X2Effect_ApplyWeaponDamage WepDamEffect,
	optional XComGameState NewGameState)
{
	local XComGameState_Unit TargetUnit;
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent EffectTemplate;
	local StateObjectReference EffectRef;
	local float CurDamageMin, CurDamageMax, CurDamageCritMin, CurDamageCritMax;
	local float NormalModMin, NormalModMax;
	local float CritModMin, CritModMax;
	local int InitDamageMin, InitDamageMax, InitDamageCritMin, InitDamageCritMax;
	local int Difference;
	local string AbilityName;
	local int i;

	AbilityName = AbilityState.GetMyFriendlyName();

	`TRACE_ENTRY("AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));

	InitDamageMin = DamageItem.Min;
	InitDamageMax = DamageItem.Max;
	InitDamageCritMin = DamageItemCrit.Min;
	InitDamageCritMax = DamageItemCrit.Max;

	CurDamageMin = DamageItem.Min;
	CurDamageMax = DamageItem.Max;
	CurDamageCritMin = DamageItemCrit.Min;
	CurDamageCritMax = DamageItemCrit.Max;


	if (SourceUnit != none)
	{
		foreach SourceUnit.AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			EffectTemplate = EffectState.GetX2Effect();

			DamageItem.Label=EffectTemplate.GetSpecialDamageMessageName();
			DamageItemCrit.Label=DamageItem.Label;

			ApplyEffectParameters.AbilityResultContext.HitResult = eHit_Success;

			NormalModMin = EffectTemplate.GetPreDefaultAttackingDamageModifier_CH(
				EffectState, SourceUnit, Target, AbilityState,
				ApplyEffectParameters, NormalDamage.Min, WepDamEffect, NewGameState);

			NormalModMax = EffectTemplate.GetPreDefaultAttackingDamageModifier_CH(
				EffectState, SourceUnit, Target, AbilityState,
				ApplyEffectParameters, NormalDamage.Max, WepDamEffect, NewGameState);

			CurDamageMin += NormalModMin;
			CurDamageMax += NormalModMax;

			DamageItem.Min = int(NormalModMin);
			DamageItem.Max = int(NormalModMax);

			ApplyEffectParameters.AbilityResultContext.HitResult = eHit_Crit;

			CritModMin = EffectTemplate.GetPreDefaultAttackingDamageModifier_CH(
				EffectState, SourceUnit, Target, AbilityState,
				ApplyEffectParameters, NormalDamage.Min + CritDamage.Min, WepDamEffect, NewGameState);

			CritModMax = EffectTemplate.GetPreDefaultAttackingDamageModifier_CH(
				EffectState, SourceUnit, Target, AbilityState,
				ApplyEffectParameters, NormalDamage.Max + CritDamage.Max, WepDamEffect, NewGameState);

			DamageItemCrit.Min = int(CritModMin - NormalModMin);
			DamageItemCrit.Max = int(CritModMax - NormalModMax);

			CurDamageCritMin += CritModMin;
			CurDamageCritMax += CritModMax;
			
			`ADDDAMITEM(Normal);
			DamageItem=DamageItemCrit;
			`ADDDAMITEM(Crit);
			`TRACE("Adjusted for SourceUnit.AffectedByEffects. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
		}
	}

	TargetUnit = XComGameState_Unit(Target);
	if (TargetUnit != none)
	{
		foreach TargetUnit.AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			EffectTemplate = EffectState.GetX2Effect();
			DamageItem.Label=EffectTemplate.GetSpecialDamageMessageName();
			DamageItemCrit.Label=DamageItem.Label;
			
			ApplyEffectParameters.AbilityResultContext.HitResult = eHit_Success;

			NormalModMin = EffectTemplate.GetPreDefaultDefendingDamageModifier_CH(
				EffectState, SourceUnit, TargetUnit, AbilityState,
				ApplyEffectParameters, NormalDamage.Min, WepDamEffect, NewGameState);

			NormalModMax = EffectTemplate.GetPreDefaultDefendingDamageModifier_CH(
				EffectState, SourceUnit, TargetUnit, AbilityState,
				ApplyEffectParameters, NormalDamage.Max, WepDamEffect, NewGameState);

			CurDamageMin += NormalModMin;
			CurDamageMax += NormalModMax;

			DamageItem.Min = int(NormalModMin);
			DamageItem.Max = int(NormalModMax);

			ApplyEffectParameters.AbilityResultContext.HitResult = eHit_Crit;

			CritModMin = EffectTemplate.GetPreDefaultDefendingDamageModifier_CH(
				EffectState, SourceUnit, TargetUnit, AbilityState,
				ApplyEffectParameters, NormalDamage.Min + CritDamage.Min, WepDamEffect, NewGameState);

			CritModMax = EffectTemplate.GetPreDefaultDefendingDamageModifier_CH(
				EffectState, SourceUnit, TargetUnit, AbilityState,
				ApplyEffectParameters, NormalDamage.Max + CritDamage.Max, WepDamEffect, NewGameState);

			DamageItemCrit.Min = int(CritModMin - NormalModMin);
			DamageItemCrit.Max = int(CritModMax - NormalModMax);

			CurDamageCritMin += CritModMin;
			CurDamageCritMax += CritModMax;

			`ADDDAMITEM(Normal);
			DamageItem=DamageItemCrit;
			`ADDDAMITEM(Crit);
			`TRACE("Adjusted for TargetUnit.AffectedByEffects. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
		}
	}

	// Truncate rather than use `Round()` for consistency with how XCOM 2
	// handles float -> int conversion in most cases. Note that this may
	// result in the sum of the shot modifiers not adding up to the overall
	// damage modifier, but damage is generally shown as a range anyway.
			
	// Issue #1099
	// Truncate the change in damage rather than the final damage itself.

	Difference = CurDamageMin - InitDamageMin;
	DamageItem.Min = InitDamageMin + Difference;

	Difference = CurDamageMax - InitDamageMax;
	DamageItem.Max = InitDamageMax + Difference;

	Difference = CurDamageCritMin - InitDamageCritMin;
	DamageItemCrit.Min = InitDamageCritMin + Difference;

	Difference = CurDamageCritMax - InitDamageCritMax;
	DamageItemCrit.Max = InitDamageCritMax + Difference;

	`TRACE("After truncating damage. DamageItem:" @ DamageInfoToString(DamageItem) $ ", DamageItemCrit:" @ DamageInfoToString(DamageItemCrit));
	`TRACE_EXIT("AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
}

/**
 * Tigrik: Add missing damage modifiers. Account for CHL #923
 * 
 * Applies post-default (Highlander) damage modifier effects to both attacking and defending units,
 * updating the provided damage breakdown structures for normal and critical damage.
 *
 * This function mirrors the behavior of the Community Highlander damage pipeline by executing
 * {@code GetPreDefaultAttackingDamageModifier_CH} and
 * {@code GetPreDefaultDefendingDamageModifier_CH} for all active effects on the source and target.
 * It accumulates incremental damage changes, tracks per-effect contributions, and updates the
 * {@code DamageBreakdown} structures accordingly.
 *
 * The function operates on both normal and critical hit contexts by temporarily modifying
 * {@code ApplyEffectParameters.AbilityResultContext.HitResult}. It computes delta-based changes
 * using running ("current") damage values to ensure correct stacking behavior, then truncates
 * the final differences to match XCOM 2�s integer damage handling.
 *
 * Damage contributions are recorded into {@code NormalDamage} and {@code CritDamage} via macros
 * (e.g. {@code ADDDAMITEM}), which merge or insert labeled {@code DamageInfo} entries.
 *
 * Notes:
 * - Uses truncation (not rounding) when finalizing damage differences for consistency with base game logic.
 * - May produce per-effect sums that do not exactly match total damage due to truncation.
 * - Relies on Highlander-specific CH functions; effects not implementing them will contribute 0.
 * - Modifies {@code DamageItem} and {@code DamageItemCrit} as working buffers during iteration.
 *
 * @param History                Game state history used to resolve effect states.
 * @param SourceUnit             The attacking unit whose effects may modify outgoing damage.
 * @param Target                 The damageable target (may or may not be a unit).
 * @param AbilityState           The ability being evaluated for damage preview.
 * @param ApplyEffectParameters  Effect application context, including hit result state (modified during execution).
 * @param DamageItem             Working structure for normal damage contributions (modified in-place).
 * @param DamageItemCrit         Working structure for critical damage contributions (modified in-place).
 * @param NormalDamage           Accumulated breakdown of normal damage (updated in-place).
 * @param CritDamage             Accumulated breakdown of critical damage (updated in-place).
 * @param WepDamEffect           Weapon damage effect context (passed to CH modifier functions; may be unused).
 * @param NewGameState           Optional game state for simulation context (may be none).
 */
static function ApplyPostDefaultDamageModifierEffects(
	XComGameStateHistory History,
	XComGameState_Unit SourceUnit,
	Damageable Target,
	XComGameState_Ability AbilityState,
	out EffectAppliedData ApplyEffectParameters,
	out DamageInfo DamageItem,
	out DamageInfo DamageItemCrit,
	out DamageBreakdown NormalDamage, 
	out DamageBreakdown CritDamage,
	X2Effect_ApplyWeaponDamage WepDamEffect,
	optional XComGameState NewGameState)
{
	local XComGameState_Unit TargetUnit;
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent EffectTemplate;
	local StateObjectReference EffectRef;
	local float CurDamageMin, CurDamageMax, CurDamageCritMin, CurDamageCritMax;
	local float NormalModMin, NormalModMax;
	local float CritModMin, CritModMax;
	local int InitDamageMin, InitDamageMax, InitDamageCritMin, InitDamageCritMax;
	local int Difference;
	local string AbilityName;
	local int i;

	AbilityName = AbilityState.GetMyFriendlyName();

	`TRACE_ENTRY("AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));

	InitDamageMin = DamageItem.Min;
	InitDamageMax = DamageItem.Max;
	InitDamageCritMin = DamageItemCrit.Min;
	InitDamageCritMax = DamageItemCrit.Max;

	CurDamageMin = DamageItem.Min;
	CurDamageMax = DamageItem.Max;
	CurDamageCritMin = DamageItemCrit.Min;
	CurDamageCritMax = DamageItemCrit.Max;


	if (SourceUnit != none)
	{
		foreach SourceUnit.AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			EffectTemplate = EffectState.GetX2Effect();

			DamageItem.Label=EffectTemplate.GetSpecialDamageMessageName();
			DamageItemCrit.Label=DamageItem.Label;

			ApplyEffectParameters.AbilityResultContext.HitResult = eHit_Success;

			NormalModMin = EffectTemplate.GetPostDefaultAttackingDamageModifier_CH(
				EffectState, SourceUnit, Target, AbilityState,
				ApplyEffectParameters, NormalDamage.Min, WepDamEffect, NewGameState);

			NormalModMax = EffectTemplate.GetPostDefaultAttackingDamageModifier_CH(
				EffectState, SourceUnit, Target, AbilityState,
				ApplyEffectParameters, NormalDamage.Max, WepDamEffect, NewGameState);

			CurDamageMin += NormalModMin;
			CurDamageMax += NormalModMax;

			DamageItem.Min = int(NormalModMin);
			DamageItem.Max = int(NormalModMax);

			ApplyEffectParameters.AbilityResultContext.HitResult = eHit_Crit;

			CritModMin = EffectTemplate.GetPostDefaultAttackingDamageModifier_CH(
				EffectState, SourceUnit, Target, AbilityState,
				ApplyEffectParameters, NormalDamage.Min + CritDamage.Min, WepDamEffect, NewGameState);

			CritModMax = EffectTemplate.GetPostDefaultAttackingDamageModifier_CH(
				EffectState, SourceUnit, Target, AbilityState,
				ApplyEffectParameters, NormalDamage.Max + CritDamage.Max, WepDamEffect, NewGameState);

			DamageItemCrit.Min = int(CritModMin - NormalModMin);
			DamageItemCrit.Max = int(CritModMax - NormalModMax);

			CurDamageCritMin += CritModMin;
			CurDamageCritMax += CritModMax;
			
			`ADDDAMITEM(Normal);
			DamageItem=DamageItemCrit;
			`ADDDAMITEM(Crit);
			`TRACE("Adjusted for SourceUnit.AffectedByEffects. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
		}
	}

	TargetUnit = XComGameState_Unit(Target);
	if (TargetUnit != none)
	{
		foreach TargetUnit.AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			EffectTemplate = EffectState.GetX2Effect();
			DamageItem.Label=EffectTemplate.GetSpecialDamageMessageName();
			DamageItemCrit.Label=DamageItem.Label;
			
			ApplyEffectParameters.AbilityResultContext.HitResult = eHit_Success;

			NormalModMin = EffectTemplate.GetPostDefaultDefendingDamageModifier_CH(
				EffectState, SourceUnit, TargetUnit, AbilityState,
				ApplyEffectParameters, NormalDamage.Min, WepDamEffect, NewGameState);

			NormalModMax = EffectTemplate.GetPostDefaultDefendingDamageModifier_CH(
				EffectState, SourceUnit, TargetUnit, AbilityState,
				ApplyEffectParameters, NormalDamage.Max, WepDamEffect, NewGameState);

			CurDamageMin += NormalModMin;
			CurDamageMax += NormalModMax;

			DamageItem.Min = int(NormalModMin);
			DamageItem.Max = int(NormalModMax);

			ApplyEffectParameters.AbilityResultContext.HitResult = eHit_Crit;

			CritModMin = EffectTemplate.GetPostDefaultDefendingDamageModifier_CH(
				EffectState, SourceUnit, TargetUnit, AbilityState,
				ApplyEffectParameters, NormalDamage.Min + CritDamage.Min, WepDamEffect, NewGameState);

			CritModMax = EffectTemplate.GetPostDefaultDefendingDamageModifier_CH(
				EffectState, SourceUnit, TargetUnit, AbilityState,
				ApplyEffectParameters, NormalDamage.Max + CritDamage.Max, WepDamEffect, NewGameState);

			DamageItemCrit.Min = int(CritModMin - NormalModMin);
			DamageItemCrit.Max = int(CritModMax - NormalModMax);

			CurDamageCritMin += CritModMin;
			CurDamageCritMax += CritModMax;

			`ADDDAMITEM(Normal);
			DamageItem=DamageItemCrit;
			`ADDDAMITEM(Crit);
			`TRACE("Adjusted for TargetUnit.AffectedByEffects. AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
		}
	}

	// Truncate rather than use `Round()` for consistency with how XCOM 2
	// handles float -> int conversion in most cases. Note that this may
	// result in the sum of the shot modifiers not adding up to the overall
	// damage modifier, but damage is generally shown as a range anyway.
			
	// Issue #1099
	// Truncate the change in damage rather than the final damage itself.

	Difference = CurDamageMin - InitDamageMin;
	DamageItem.Min = InitDamageMin + Difference;

	Difference = CurDamageMax - InitDamageMax;
	DamageItem.Max = InitDamageMax + Difference;

	Difference = CurDamageCritMin - InitDamageCritMin;
	DamageItemCrit.Min = InitDamageCritMin + Difference;

	Difference = CurDamageCritMax - InitDamageCritMax;
	DamageItemCrit.Max = InitDamageCritMax + Difference;

	`TRACE("After truncating damage. DamageItem:" @ DamageInfoToString(DamageItem) $ ", DamageItemCrit:" @ DamageInfoToString(DamageItemCrit));
	`TRACE_EXIT("AbilityState.GetMyFriendlyName():" @ AbilityName $ ", NormalDamage:" @ DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ DamageBreakdownToString(CritDamage));
}

/**
 * Converts a DamageBreakdown struct into a human-readable string representation.
 *
 * This function manually serializes all fields of the DamageBreakdown, including
 * nested DamageInfo entries within the InfoList array. The output format is
 * similar to Java's toString(), making it useful for debugging and logging.
 *
 * Example output:
 * DamageBreakdown{Min=2, Max=5, Bonus=1, InfoList=[{Label="Base", Min=2, Max=4}, {Label="Modifier", Min=3, Max=5}]}
 *
 * @param DB The DamageBreakdown instance to convert.
 * @return A string containing all values from the struct, including nested array elements.
 */
static function string DamageBreakdownToString(DamageBreakdown DB)
{
	local string Result;
	local int i;

	Result = "DamageBreakdown{";

	// Top-level fields
	Result $= "Min=" $ string(DB.Min) $ ", ";
	Result $= "Max=" $ string(DB.Max) $ ", ";
	Result $= "Bonus=" $ string(DB.Bonus) $ ", ";

	// InfoList
	Result $= "InfoList=[";

	for (i = 0; i < DB.InfoList.Length; i++)
	{
		Result $= DamageInfoToString(DB.InfoList[i]);

		if (i < DB.InfoList.Length - 1)
		{
			Result $= ", ";
		}
	}

	Result $= "]";

	Result $= "}";

	return Result;
}

/**
 * Converts a DamageInfo struct into a human-readable string representation.
 *
 * Serializes all fields of the DamageInfo struct, including Label, Min, and Max.
 * The output format is compact and intended for debugging or logging purposes.
 *
 * Example output:
 * {Label="Base", Min=2, Max=4}
 *
 * @param Info The DamageInfo instance to convert.
 * @return A string containing all values from the struct.
 */
static function string DamageInfoToString(DamageInfo Info)
{
	return "{Label=\"" $ Info.Label $ "\", Min=" $ string(Info.Min) $ ", Max=" $ string(Info.Max) $ "}";
}