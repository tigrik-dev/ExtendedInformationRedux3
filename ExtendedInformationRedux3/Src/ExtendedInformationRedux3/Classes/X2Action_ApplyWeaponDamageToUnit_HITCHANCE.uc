/**
 * X2Action_ApplyWeaponDamageToUnit_HITCHANCE
 * Used by the visualizer system to control a Visualization Actor
 *
 * Extends X2Action_ApplyWeaponDamageToUnit to integrate hit chance visualization.
 * Used by the visualizer system to display detailed HUD flyovers for weapon attacks,
 * including hit, miss, crit, guaranteed hit, dodge, counterattack, and Templar messages.
 *
 * @author Mr.Nice / Sebkulu
 */
class X2Action_ApplyWeaponDamageToUnit_HITCHANCE extends X2Action_ApplyWeaponDamageToUnit;

`include(ExtendedInformationRedux3\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)
`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\LangFallBack.uci)
`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

var bool SHOW_TEMPLAR_MSG;

var localized string GUARANTEED_HIT;
var localized string FAILED_TEXT;

// Short versions
var localized string SHORT_GUARANTEED_HIT;
var localized string SHORT_HIT_CHANCE;
var localized string SHORT_MISS_CHANCE;
var localized string SHORT_CRIT_CHANCE;
var localized string SHORT_DODGE_CHANCE;
var localized string SHORT_COUNTER_CHANCE;

/**
 * Initializes the action and ensures UnitState is correctly set for interrupted abilities.
 */
function Init()
{
	`TRACE_ENTRY("");
	Super.Init();
	if(UnitState==none)
	{
		`TRACE_IF("UnitState==none");
		UnitState = XComGameState_Unit(AbilityContext.GetLastStateInInterruptChain().GetGameStateForObjectID(Metadata.StateObject_NewState.ObjectID));
		if (UnitState == None) //This can occur for abilities which were interrupted but never resumed, e.g. because the shooter was killed.
			`TRACE_IF("UnitState==none. This can occur for abilities which were interrupted but never resumed, e.g. because the shooter was killed.");
			UnitState = XComGameState_Unit(Metadata.StateObject_NewState); //Will typically be the same as the OldState in this case.
	}
	`TRACE_EXIT("");
}

simulated function bool getHIT_CHANCE_ENABLED()
{	
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.HIT_CHANCE_ENABLED, class'ExtendedInformationRedux3_MCMScreen'.default.HIT_CHANCE_ENABLED);
}

simulated function bool getVERBOSE_TEXT()
{	
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.VERBOSE_TEXT, class'ExtendedInformationRedux3_MCMScreen'.default.VERBOSE_TEXT);
}

simulated function bool getDISPLAY_MISS_CHANCE()
{	
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.DISPLAY_MISS_CHANCE, class'ExtendedInformationRedux3_MCMScreen'.default.DISPLAY_MISS_CHANCE);
}

simulated function bool getSHOW_TEMPLAR_MSG()
{	
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOW_TEMPLAR_MSG, class'ExtendedInformationRedux3_MCMScreen'.default.SHOW_TEMPLAR_MSG);
}

simulated function bool getSHOW_GUARANTEED_HIT()
{	
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOW_GUARANTEED_HIT, class'ExtendedInformationRedux3_MCMScreen'.default.SHOW_GUARANTEED_HIT);
}

`MCM_CH_VersionChecker(class'MCM_Defaults'.default.VERSION, class'ExtendedInformationRedux3_MCMScreen'.default.CONFIG_VERSION)

simulated state Executing
{
	/**
	 * Displays the standard attack messages for the unit.
	 * Overrides the base class method to provide custom tracing.
	 */
	simulated function ShowAttackMessages()
	{
		`TRACE_ENTRY("");
		Super.ShowAttackMessages();
		`TRACE_EXIT("");
		return;
	}
	
	/**
	 * Displays a damage message with optional critical hit text.
	 *
	 * @param UIMessage The primary message to display in the UI.
	 * @param CritMessage Optional message for critical hits.
	 * @param DisplayColor Optional color of the message (default is eColor_Bad).
	 */
	simulated function ShowHPDamageMessage(string UIMessage, optional string CritMessage, optional EWidgetColor DisplayColor = eColor_Bad)
	{
		local string HitIcon;
		local XComPresentationLayerBase kPres;

		`TRACE_ENTRY("UIMessage:" @ UIMessage $ ", CritMessage:" @ CritMessage);
		// This is done to re-create a Crit-Like flyover message to be displayed just under the Crit Flyover containing damages, and the Crit Label
		
		kPres = XComPlayerController(class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController()).Pres;
		UIMessage $= GetChanceString();
		if (CritMessage != "")
		{
			`TRACE_IF("CritMessage != ''; CritMessage =" @ CritMessage);
			HitIcon = "img:///UILibrary_ExtendedInformationRedux3.HitIcon32";
			// Soooo Grimy's right, had to do Shenanigans until Firaxis fixes their shit on the damn Flash Component that handles Crit Flyovers behavior.
			// Right now the Flash makes it so when Crit Flyover appears, then Crit Label stays for 1.3s before disappearing (with its panel beneath it)
			// but then another panel beneath text may not appear properly although text is being displayed...
			class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), CritMessage, UnitPawn.m_eTeamVisibilityFlags, , m_iDamage, 0, CritMessage, DamageTypeName == 'Psi'? eWDT_Psi : -1, eColor_Yellow);
			kPres.GetWorldMessenger().Message(UIMessage, m_vHitLocation, Unit.GetVisualizedStateReference(), eColor_Yellow, , class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_ID, UnitPawn.m_eTeamVisibilityFlags, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_USE_SCREEN_LOC_PARAM, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_SCREEN_LOC, , , HitIcon, , , , , DamageTypeName == 'Psi'? eWDT_Psi : -1);
		}
		else
		{
			`TRACE_IF("CritMessage == ''");
			class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), UIMessage, UnitPawn.m_eTeamVisibilityFlags, , m_iDamage, 0, CritMessage, DamageTypeName == 'Psi'? eWDT_Psi : -1, DisplayColor);
		}
		`TRACE_EXIT("UIMessage:" @ UIMessage $ ", CritMessage:" @ CritMessage);
	}

	/**
	 * Displays a message indicating the unit's shielded status.
	 *
	 * @param DisplayColor Color to use for the message.
	 */
	simulated function ShowShieldedMessage(EWidgetColor DisplayColor)
	{
		`TRACE_ENTRY("m_iDamage:" @ m_iDamage);
		if (m_iDamage > 0)
		{
			`TRACE_IF("m_iDamage > 0");
			Super.ShowShieldedMessage(DisplayColor);
		}
		else
		{
			`TRACE_IF("m_iDamage <= 0");
			class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), class'XGLocalizedData'.default.ShieldedMessage $ GetChanceString(), UnitPawn.m_eTeamVisibilityFlags, , m_iShielded,,,, DisplayColor);
		}
		`TRACE_EXIT("m_iDamage:" @ m_iDamage);
	}

	/**
	 * Displays a message indicating a missed attack.
	 *
	 * @param DisplayColor Color to use for the message.
	 */
	simulated function ShowMissMessage(EWidgetColor DisplayColor)
	{	
		local String MissedMessage;

		`TRACE_ENTRY("m_iDamage:" @ m_iDamage);
		MissedMessage = OriginatingEffect.OverrideMissMessage;
		if( MissedMessage == "" )
		{
			`TRACE_IF("MissedMessage == ''");
			MissedMessage = class'XLocalizedData'.default.MissedMessage;
		}
		`DEBUG("MissedMessage:" @ MissedMessage);

		if (m_iDamage > 0)
			class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), (MissedMessage $ GetChanceString()), UnitPawn.m_eTeamVisibilityFlags, , m_iDamage,,,, DisplayColor);
		else if (!OriginatingEffect.IsA('X2Effect_Persistent')) //Persistent effects that are failing to cause damage are not noteworthy.
			class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), (MissedMessage $ GetChanceString()),,,,,,, DisplayColor);
		`TRACE_EXIT("m_iDamage:" @ m_iDamage);
	}
	
	/**
	 * Displays a counterattack message.
	 *
	 * @param DisplayColor Color to use for the message.
	 */
	simulated function ShowCounterattackMessage(EWidgetColor DisplayColor)
	{
		`TRACE_ENTRY("");
		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), class'XLocalizedData'.default.CounterattackMessage $ GetChanceString(),,,,,,, DisplayColor);
		`TRACE_EXIT("");
	}

	/**
	 * Displays a Lightning Reflexes message depending on whether the Dark Event is active.
	 *
	 * @param DisplayColor Color to use for the message.
	 */
	simulated function ShowLightningReflexesMessage(EWidgetColor DisplayColor)
	{
		local XComGameState_HeadquartersXCom XComHQ;
		local XComGameStateHistory History;
		local string DisplayMessageString;

		`TRACE_ENTRY("");
		History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if( XComHQ.TacticalGameplayTags.Find('DarkEvent_LightningReflexes') != INDEX_NONE )
		{
			DisplayMessageString = class'XLocalizedData'.default.DarkEvent_LightningReflexesMessage;
		}
		else
		{
			DisplayMessageString = class'XLocalizedData'.default.LightningReflexesMessage;
		}
		if (getSHOW_TEMPLAR_MSG()) { DisplayMessageString = DisplayMessageString $ GetChanceString(); }
		`DEBUG("DisplayMessageString:" @ DisplayMessageString);
		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), DisplayMessageString,,,,,,, DisplayColor);
		`TRACE_EXIT("");
	}

	/**
	 * Displays a message indicating the unit is untouchable.
	 *
	 * @param DisplayColor Color to use for the message.
	 */
	simulated function ShowUntouchableMessage(EWidgetColor DisplayColor)
	{
		local string DisplayMessageString;
		`TRACE_ENTRY("");
		DisplayMessageString=class'XLocalizedData'.default.UntouchableMessage;
		if (getSHOW_TEMPLAR_MSG()) { DisplayMessageString = DisplayMessageString $ GetChanceString(); }
		`DEBUG("DisplayMessageString:" @ DisplayMessageString);
		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), DisplayMessageString,,,,,,, DisplayColor);
		`TRACE_EXIT("");
	}

	/**
	 * Displays a parry message.
	 *
	 * @param DisplayColor Color to use for the message.
	 */
	simulated function ShowParryMessage(EWidgetColor DisplayColor)
	{
		local string ParryMessage;
		`TRACE_ENTRY("");
		ParryMessage = class'XLocalizedData'.default.ParryMessage;
		if (getSHOW_TEMPLAR_MSG()) { ParryMessage = ParryMessage $ GetChanceString(); }
		`DEBUG("ParryMessage:" @ ParryMessage);
		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), ParryMessage,,,,,,, DisplayColor);
		`TRACE_EXIT("");
	}

	/**
	 * Displays a deflect message.
	 *
	 * @param DisplayColor Color to use for the message.
	 */
	simulated function ShowDeflectMessage(EWidgetColor DisplayColor)
	{
		local string DeflectMessage;
		`TRACE_ENTRY("");

		DeflectMessage = class'XLocalizedData'.default.DeflectMessage;
		if (getSHOW_TEMPLAR_MSG()) { DeflectMessage = DeflectMessage $ GetChanceString(); }
		`DEBUG("DeflectMessage:" @ DeflectMessage);
		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), DeflectMessage,,,,,,, DisplayColor);
		`TRACE_EXIT("");
	}

	/**
	 * Displays a reflect message.
	 *
	 * @param DisplayColor Color to use for the message.
	 */
	simulated function ShowReflectMessage(EWidgetColor DisplayColor)
	{
		local string ReflectMessage;
		`TRACE_ENTRY("");

		ReflectMessage = class'XLocalizedData'.default.ReflectMessage;
		if (getSHOW_TEMPLAR_MSG()) { ReflectMessage = ReflectMessage $ GetChanceString(); }
		`DEBUG("ReflectMessage:" @ ReflectMessage);
		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), ReflectMessage,,,,,,, DisplayColor);
		`TRACE_EXIT("");
	}

	/**
	 * Displays a free kill message for a given ability.
	 *
	 * @param AbilityName Name of the ability causing the free kill.
	 * @param DisplayColor Color to use for the message.
	 */
	simulated function ShowFreeKillMessage(name AbilityName, EWidgetColor DisplayColor)
	{
		local X2AbilityTemplate Template;
		local string KillMessage;

		`TRACE_ENTRY("AbilityName:" @AbilityName);
		KillMessage = class'XLocalizedData'.default.FreeKillMessage;

		if (AbilityName != '')
		{
			Template = class'XComGameState_Ability'.static.GetMyTemplateManager( ).FindAbilityTemplate( AbilityName );
			if ((Template != none) && (Template.LocFlyOverText != ""))
			{
				KillMessage = Template.LocFlyOverText;
			}
		}

		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), (KillMessage $ GetChanceString()), , , , , , eWDT_Repeater, DisplayColor);
		`TRACE_EXIT("AbilityName:" @ AbilityName $ ", KillMessage:" @ KillMessage);
	}

	/**
	 * Returns a formatted string showing hit chance, crit chance, graze chance, and counterattack chance for a given attack.
	 *
	 * @return A string representing the calculated hit breakdown for display purposes.
	 */
	function string GetChanceString()
	{
		local array<string> Elements;
		local string outString, sgHit, sHit, sMiss, sCrit, sGraze, sCounter;

		local XComGameState_Ability AbilityState;
		local AvailableTarget kTarget;
		local int hitChance, critChance, grazeChance;
		local ShotBreakdown TargetBreakdown;
		local X2AbilityToHitCalc_StandardAim StandardHitCalc;
		local XComGameState_Unit TargetUnitState;
		local UnitValue CounterattackCheck;
		local X2GameRulesetEventObserverInterface Observer;

		`TRACE_ENTRY("");

		if (!getHIT_CHANCE_ENABLED() || IsPersistent())
		{
			`TRACE_IF("!getHIT_CHANCE_ENABLED() || IsPersistent()");
			`TRACE_EXIT("Return: ''");
			return "";
		}

		Observer = `GAMERULES.GetEventObserverOfType(class'X2TacticalGameRuleset_BreakdownObserver');
		if (X2TacticalGameRuleset_BreakdownObserver(Observer).FindBreakdown(AbilityContext, Metadata.StateObject_OldState, TargetBreakdown) == -1)
		{
			`TRACE_IF("X2TacticalGameRuleset_BreakdownObserver(Observer).FindBreakdown(AbilityContext, Metadata.StateObject_OldState, TargetBreakdown) == -1");
			`TRACE_EXIT("Return: ''");
			return "";
		}

		if (getVERBOSE_TEXT())
		{
			`TRACE_IF("getVERBOSE_TEXT() = TRUE");
			sgHit=GUARANTEED_HIT;
			sHit=class'UITacticalHUD_ShotHUD'.default.m_sShotChanceLabel;
			sMiss=Caps(class'X2TacticalGameRulesetDataStructures'.default.m_aAbilityHitResultStrings[eHit_Miss]);
			sCrit=class'UITacticalHUD_ShotHUD'.default.m_sCritChanceLabel;
			sGraze=Caps(class'X2TacticalGameRulesetDataStructures'.default.m_aAbilityHitResultStrings[eHit_Graze]);
			sCounter=`LOCFALLBACK(ShortCounterAttack, Caps(class'X2TacticalGameRulesetDataStructures'.default.m_aAbilityHitResultStrings[eHit_CounterAttack]));
		}
		else
		{
			`TRACE_IF("getVERBOSE_TEXT() = FALSE");
			sgHit=SHORT_GUARANTEED_HIT;
			sHit=SHORT_HIT_CHANCE;
			sMiss=SHORT_MISS_CHANCE;
			sCrit=SHORT_CRIT_CHANCE;
			sGraze=SHORT_DODGE_CHANCE;
			sCounter=SHORT_COUNTER_CHANCE;
		}

		hitChance = Clamp(TargetBreakdown.FinalHitChance, 0, 100);// 500);
		critChance =  Clamp(TargetBreakdown.ResultTable[eHit_Crit], 0, 100);// 500);
		grazeChance = Clamp(TargetBreakdown.ResultTable[eHit_Graze], 0, 100);// 500);

		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
		StandardHitCalc=X2AbilityToHitCalc_StandardAim(AbilityState.GetMyTemplate().AbilityToHitCalc);
		if (StandardHitCalc!=none && StandardHitCalc.bMeleeAttack)
		{
			TargetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kTarget.PrimaryTarget.ObjectID));
			if (TargetUnitState!=none && !TargetUnitState.IsImpaired()
				&& TargetUnitState.GetUnitValue(class'X2Ability'.default.CounterattackDodgeEffectName, CounterattackCheck)
				&& CounterattackCheck.fValue == class'X2Ability'.default.CounterattackDodgeUnitValue)
			{
				if (StandardHitCalc.bGuaranteedHit)
					grazeChance+=max(0,(hitChance-grazeChance))*class'X2Ability_Muton'.default.COUNTERATTACK_DODGE_AMOUNT/100;
				grazeChance+=100-hitChance;
				sGraze=sCounter;
			}
		}

		//Elements.AddItem("Context: " $ XComGameStateContext_Ability(StateChangeContext).ResultContext.CalculatedHitChance $ "%");
		if (IsGuaranteedHit())
		{
			if (getSHOW_GUARANTEED_HIT()) Elements.AddItem(sgHit);
		}
		else if (getDISPLAY_MISS_CHANCE()) Elements.AddItem(sMiss $ ": " $ (100-hitChance)$ "%");
		else Elements.AddItem(sHit $ ": " $ hitChance $ "%");

		if (critChance>0) Elements.AddItem(sCrit $ ": " $ critChance $ "%");
		if (grazeChance>0) Elements.AddItem(sGraze $ ": " $ GrazeChance $ "%");
		
		//foreach Elements(sHit) `log(sHit);

		JoinArray(Elements, OutString, " - ");
		if(OutString!="") OutString= " - " $ OutString;
		`TRACE_EXIT("OutString:" @ OutString);
		return OutString;
	}

	/**
	 * Determines if the current damage effect or its origin/ancestor is persistent.
	 *
	 * @return true if the effect is persistent; false otherwise.
	 */
	simulated function bool IsPersistent()
	{
		`TRACE_ENTRY("");
		if (X2Effect_Persistent(DamageEffect) != none)
			return true;

		if (X2Effect_Persistent(OriginatingEffect) != None)
			return true;

		if (X2Effect_Persistent(AncestorEffect) != None)
			return true;

		`TRACE_EXIT("Returns: FALSE");
		return false;
	}

	/**
	 * Determines if the current attack is guaranteed to hit.
	 *
	 * @return true if the attack is guaranteed to hit; false otherwise.
	 */
	simulated function bool IsGuaranteedHit()
	{
		`TRACE_ENTRY("");
		if ( X2AbilityToHitCalc_DeadEye(AbilityTemplate.AbilityToHitCalc) != None)	return true;
		if ( X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc).bGuaranteedHit) return true;		
		if ( X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc).bIndirectFire) return true;		
		if (FallingContext != none) return true;
		if (AreaDamageContext != None) return true;
		`TRACE_EXIT("Returns: FALSE");
		return false;
	}
}