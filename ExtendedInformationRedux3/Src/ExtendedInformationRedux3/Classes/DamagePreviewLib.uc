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

	`TRACE_ENTRY("TargetRef.ObjectID:" @ TargetRef.ObjectID);

	if (AbilityState == none)
	{
		`TRACE_IF("AbilityState == none");
		`TRACE_EXIT("");
		return;
	}

	AbilityTemplate = AbilityState.GetMyTemplate();
	EIPreview = EI_DamagePreviewTemplateAPI(AbilityTemplate);
	if (EIPreview!=none)
	{
		`TRACE_IF("EIPreview != none");
		if (EIPreview.EIDamagePreviewFn(EI_DamagePreviewHelperAPI(class'XComEngine'.static.GetClassDefaultObject(default.class)), AbilityState, TargetRef, NormalDamage, CritDamage, AllowsShield))
		{
			`TRACE_EXIT("Used EIPreview");
			return;
		}
	}
	if (AbilityTemplate.DamagePreviewFn != none)
	{
		`TRACE_IF("AbilityTemplate.DamagePreviewFn != none");
		if (DamagePreviewFnHandler(AbilityState, AbilityTemplate, TargetRef, NormalDamage, CritDamage, AllowsShield))
		{
			`TRACE_EXIT("Used Template Fn");
			return;
		}
	}
	NormalAbilityDamagePreview(AbilityState, TargetRef, NormalDamage, CritDamage, AllowsShield);
	`TRACE_EXIT("Fallback Used");
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

	`TRACE_ENTRY("TargetRef.ObjectID:" @ TargetRef.ObjectID);

	ReturnVal=AbilityTemplate.DamagePreviewFn(AbilityState, TargetRef, MinDamagePreview, MaxDamagePreview, AllowsShield);

	BalanceItem.Label=AbilityState.GetMyFriendlyName();
	BalanceItem.Min=MinDamagePreview.Damage;
	BalanceItem.Max=MaxDamagePreview.Damage;

	`TRACE("BaseMin:" @ BalanceItem.Min $ ", BaseMax:" @ BalanceItem.Max);

	foreach MinDamagePreview.BonusDamageInfo(DamageModInfo)
	{
		DamageItem.Min = DamageModInfo.Value;
		BalanceItem.Min -= DamageItem.Min;
		DamageItem.Label = `LABELFROMMOD(DamageModInfo);
		`TRACE("MinBonus:" @ DamageItem.Min);
		`ADDDAMITEM(Normal);
	}

	DamageItem.Min=0;
	foreach MaxDamagePreview.BonusDamageInfo(DamageModInfo)
	{
		DamageItem.Max=DamageModInfo.Value;
		BalanceItem.Max-=DamageItem.Max;
		DamageItem.Label=`LABELFROMMOD(DamageModInfo);
		`TRACE("MaxBonus:" @ DamageItem.Max);
		`ADDDAMITEM(Normal);
	}

	DamageItem=BalanceItem;
	`INSERTDAMITEM(Normal, true);
	
	DamageItem.Min = MinDamagePreview.Crit;
	DamageItem.Max = MaxDamagePreview.Crit;
	`TRACE("CritMin:" @ DamageItem.Min $ ", CritMax:" @ DamageItem.Max);
	`ADDDAMITEM(Crit, true);
	
	`TRACE_EXIT("ReturnVal:" @ ReturnVal);
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

	`TRACE_ENTRY("TargetRef.ObjectID:" @ TargetRef.ObjectID);

	if (AbilityState==none)
	{
		`TRACE_IF("AbilityState == none");
		`TRACE_EXIT("");
		return;
	}
	AbilityTemplate = AbilityState.GetMyTemplate();
	BalanceItem.Label=AbilityState.GetMyFriendlyName();

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
			}

			DamageItem.Min=0;
			foreach MaxDamagePreview.BonusDamageInfo(DamageModInfo)
			{
				DamageItem.Max=DamageModInfo.Value;
				BalanceItem.Max-=DamageItem.Max;
				DamageItem.Label=`LABELFROMMOD(DamageModInfo);
				`ADDDAMITEM(Normal);
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
		}
	}
	if (Rupture > 0)
	{
		`TRACE_IF("Rupture > 0");
		DamageItem.Min = Rupture;
		DamageItem.Max = Rupture;
		DamageItem.Label = class'X2StatusEffects'.default.RupturedFriendlyName;
		`ADDDAMITEM(Normal);
	}	
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
	local XComOnlineEventMgr EventManager;

	`TRACE_ENTRY("TargetRef.ObjectID:" @ TargetRef.ObjectID $ ", bAsPrimaryTarget:" @ bAsPrimaryTarget);

	bDoesDamageIgnoreShields = WepDamEffect.bBypassShields;

	History=`XCOMHistory;

	if (AbilityState.SourceAmmo.ObjectID > 0)
		SourceWeapon = AbilityState.GetSourceAmmo();
	else
		SourceWeapon = AbilityState.GetSourceWeapon();

	
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

	AbilityName=AbilityState.GetMyFriendlyName();

	if (WepDamEffect.bAlwaysKillsCivilians && TargetUnit != None && TargetUnit.GetTeam() == eTeam_Neutral)
	{
		`TRACE_IF("WepDamEffect.bAlwaysKillsCivilians && TargetUnit != None && TargetUnit.GetTeam() == eTeam_Neutral");
		DamageItem.Label=AbilityName;
		DamageItem.Min=TargetUnit.GetCurrentStat(eStat_HP) + TargetUnit.GetCurrentStat(eStat_ShieldHP) - NormalDamage.Min;
		DamageItem.Max=TargetUnit.GetCurrentStat(eStat_HP) + TargetUnit.GetCurrentStat(eStat_ShieldHP) - NormalDamage.Max;
		`ADDDAMITEM(Normal);
		return;
	}

	BonusEffectDamageValue = WepDamEffect.GetBonusEffectDamageValue(AbilityState, SourceUnit, SourceWeapon, TargetRef);
	WepDamEffect.ModifyDamageValue(BonusEffectDamageValue, TargetUnit, AppliedDamageTypes);
	DamageItem.Label=AbilityName;
	`INSERTTOBOTH(BonusEffectDamageValue);

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
				}
			}
		}
		EventManager = `ONLINEEVENTMGR;
		for(i = EventManager.GetNumDLC() - 1; i >= 0; i--)
		{
			if(EventManager.GetDLCNames(i)=='X2WOTCCommunityHighlander')
			{
				`TRACE_IF("EventManager.GetDLCNames(i)=='X2WOTCCommunityHighlander'");
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
					}
				}
				break;
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
		}

		if (!WepDamEffect.bIgnoreBaseDamage)
		{
			`TRACE_IF("!WepDamEffect.bIgnoreBaseDamage");
			SourceWeapon.GetBaseWeaponDamageValue(TargetUnit, BaseDamageValue);
			WepDamEffect.ModifyDamageValue(BaseDamageValue, TargetUnit, AppliedDamageTypes);
			DamageItem.Label=SourceWeapon.GetMyTemplate().GetItemFriendlyName(SourceWeapon.ObjectID);
			`INSERTTOBOTH(BaseDamageValue);
		}
		if (WepDamEffect.DamageTag != '')
		{
			`TRACE_IF("WepDamEffect.DamageTag != ''");
			SourceWeapon.GetWeaponDamageValue(TargetUnit, WepDamEffect.DamageTag, ExtraDamageValue);
			WepDamEffect.ModifyDamageValue(ExtraDamageValue, TargetUnit, AppliedDamageTypes);
			DamageItem.Label=SourceWeapon.GetMyTemplate().GetItemFriendlyName(SourceWeapon.ObjectID);
			`INSERTTOBOTH(ExtraDamageValue);
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
		}
	}

	foreach SourceUnit.AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		EffectTemplate = EffectState.GetX2Effect();

		DamageItem.Label=EffectTemplate.GetSpecialDamageMessageName();
		DamageItemCrit.Label=DamageItem.Label;

		TestEffectParams.AbilityResultContext.HitResult = eHit_Success;
		DamageItem.Min = EffectTemplate.GetAttackingDamageModifier(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TestEffectParams, NormalDamage.Min);
		DamageItem.Max = EffectTemplate.GetAttackingDamageModifier(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TestEffectParams, NormalDamage.Max);
			
		DamageItemCrit.Min=-DamageItem.Min;
		DamageItemCrit.Max=-DamageItem.Max;
		TestEffectParams.AbilityResultContext.HitResult = eHit_Crit;
		DamageItemCrit.Min += EffectTemplate.GetAttackingDamageModifier(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TestEffectParams, NormalDamage.Min+CritDamage.Min);
		DamageItemCrit.Max += EffectTemplate.GetAttackingDamageModifier(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TestEffectParams, NormalDamage.Max+CritDamage.Max);
		`ADDDAMITEM(Normal);
		DamageItem=DamageItemCrit;
		`ADDDAMITEM(Crit);
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
		}
	}
	if (!bDoesDamageIgnoreShields)
	{
		`TRACE_IF("!bDoesDamageIgnoreShields");
		AllowsShield += NormalDamage.Max;
	}
}