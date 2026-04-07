/**
 *X2DownloadableContentInfo_ExtendedInformationRedux3
 *
 * Handles hit chance visualization overrides for abilities,
 * including Mind Control, Skirmisher Vengeance, and Dazed effects.
 *
 * Responsibilities:
 * - Modify flyover messages for specific abilities
 * - Provide custom visualization functions
 * - Integrate with MCM configuration for hit/miss display
 *
 * @author Mr.Nice / Sebkulu
 */
class X2DownloadableContentInfo_ExtendedInformationRedux3 extends X2DownloadableContentInfo;

`include(ExtendedInformationRedux3\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)
`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\LangFallBack.uci)
`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

`define GETAB(ABNAME) abilities.FindAbilityTemplate('`ABNAME')
`define IFGETAB(ABNAME) ability=`GETAB(`ABNAME); if (ability!=none)

`define GETHITTEXT ( getDISPLAY_MISS_CHANCE() ? (getVERBOSE_TEXT() ? Caps(class'X2TacticalGameRulesetDataStructures'.default.m_aAbilityHitResultStrings[eHit_Miss]) : class'X2Action_ApplyWeaponDamageToUnit_HITCHANCE'.default.SHORT_MISS_CHANCE) \\
	: (getVERBOSE_TEXT() ? class'UITacticalHUD_ShotHUD'.default.m_sShotChanceLabel : class'X2Action_ApplyWeaponDamageToUnit_HITCHANCE'.default.SHORT_HIT_CHANCE) )


/**
 * Triggered after all ability templates are created; sets up visualization overrides and observers.
 */
static event OnPostTemplatesCreated()
{
	local X2AbilityTemplateManager Abilities;
	local X2AbilityTemplate Ability;
	local HitChanceBuildVisualization NewVis, StandardMCVis;
	local int i;
	local X2Effect_Dazed DazedEffect;
	local X2Effect_MindControl MCEffect;
	local bool bSetMiss;

	`TRACE_ENTRY("");
	`INFO(class'EIR_Version'.static.GetDisplayString());

	// Tigrik: Patch templates
	class'TemplatePatchLib'.static.PatchTemplates();

	// Registers BreakdownObserver with the tactical ruleset.
	X2TacticalGameRuleset(class'XComEngine'.static.GetClassDefaultObject(class'X2TacticalGameRuleset')).EventObserverClasses.AddItem(class'X2TacticalGameRuleset_BreakdownObserver');

	Abilities = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	StandardMCVis=class'HitChanceBuildVisualization'.static.CreateFlyoverVisualization();
	StandardMCVis.FlyoverMessages.additem(class'X2StatusEffects'.default.ResistedMindControlText);//Miss
	StandardMCVis.FlyoverMessages.additem(class'X2StatusEffects'.default.MindControlFriendlyName);//Hit

	// Tigrik: This code block displays the "Grabbed!" flyover on the Viper tongue pull ability
	// that causes a visual bug - cinematic of a tongue grab gets skipped together with the subsequent bind animation
	// making the binded person appear not wrapped by Viper 
	/*`IFGETAB(GetOverHere)
	{
		NewVis=class'HitChanceBuildVisualization'.static.CreateFlyoverVisualization();
		Ability.BuildVisualizationFn = NewVis.BuildVisualization;
		Ability.LocHitMessage=`LOCFALLBACK(TongueGrabHit, Ability.LocFlyOverText);
		NewVis.FlyoverMessages.additem(Ability.LocHitMessage);
		NewVis.FlyoverMessages.additem(Ability.LocMissMessage);
	}*/

	`IFGETAB(Justice)
	{
		NewVis=class'HitChanceBuildVisualization'.static.CreateFlyoverVisualization(Ability.BuildVisualizationFn);
		Ability.LocHitMessage=`LOCFALLBACK(Grappled, Localize("SkirmisherGrapple X2AbilityTemplate", "LocFriendlyName", "XComGame"));
		Ability.LocMissMessage=class'XLocalizedData'.default.MissedMessage;
		NewVis.FlyoverMessages.additem(Ability.LocHitMessage);
		NewVis.FlyoverMessages.additem(Ability.LocMissMessage);
	}

	`IFGETAB(MindSpin)
	{
		/**
		 * Uses factory method instead of direct instantiation.
		 *
		 * Benefits:
		 * - Preserves original BuildVisualization function via delegate
		 * - Prevents breaking abilities that override visualization
		 * - Ensures compatibility with modded/custom abilities
		 */
		NewVis=class'HitChanceBuildVisualization'.static.CreateFlyoverVisualization();
		Ability.BuildVisualizationFn = NewVis.BuildVisualization;
		Abilities.FindAbilityTemplate('MindSpin').LocHitMessage=Ability.LocFriendlyName;
		Abilities.FindAbilityTemplate('MindSpin').LocMissMessage=Ability.LocFriendlyName @ class'X2Action_ApplyWeaponDamageToUnit_HITCHANCE'.default.FAILED_TEXT;
		NewVis.FlyoverMessages.additem(Ability.LocHitMessage);
		NewVis.FlyoverMessages.additem(Ability.LocMissMessage);
		//MrNice: Just want to avoid the specific "Mind control failed" flyover, it's redundant & confusing for Mind Spin
		for (i=0; i < Ability.AbilityTargetEffects.length; i++)
		{
			MCEffect=X2Effect_MindControl(Ability.AbilityTargetEffects[i]);
			if (MCEffect!=none)
			{
				MCEffect.VisualizationFn=static.MindSpinControlVisualization;
				break;
			}
		}
	}

	`IFGETAB(Domination)
	{
		// Reuses a single visualization instance for multiple mind control abilities.
		Ability.BuildVisualizationFn = StandardMCVis.BuildVisualization;
	}

	`IFGETAB(PsiMindControl)
	{
		// Reuses a single visualization instance for multiple mind control abilities.
		Ability.BuildVisualizationFn = StandardMCVis.BuildVisualization;
	}

	//Added in DEV by Mr.Nice
	`IFGETAB(PriestPsiMindControl)
	{
		Ability.BuildVisualizationFn = StandardMCVis.BuildVisualization;
	}
	
	//Added in DEV by Mr.Nice
	`IFGETAB(SkirmisherVengeance)
	{
		Ability.BuildVisualizationFn = static.Vengeance_BuildVisualization;
		Ability.LocHitMessage=Localize("SkirmisherGrapple X2AbilityTemplate", "LocFriendlyName", "XComGame");
		Ability.LocMissMessage=class'XLocalizedData'.default.MissedMessage;
	}

	`IFGETAB(MindScorch)
	{
		NewVis=new class'HitChanceBuildVisualization';
		Ability.BuildVisualizationFn = NewVis.BuildVisualization;
		Abilities.FindAbilityTemplate('MindScorch').LocHitMessage=Ability.LocFriendlyName;
		NewVis.FlyoverMessages.additem(Ability.LocHitMessage);
		NewVis.FlyoverMessages.additem(Ability.LocMissMessage); //Mr. Nice: I'm assuming MindScorch can fail!
	}

	//Added in DEV by Mr.Nice
	`IFGETAB(HarborWave)
	{
		for (i=0; i < Ability.AbilityMultiTargetEffects.length; i++)
		{
			DazedEffect=X2Effect_Dazed(Ability.AbilityMultiTargetEffects[i]);
			if (DazedEffect!=none)
			{
				DazedEffect.VisualizationFn = static.DazedVisualizationShowMiss;
				break;
			}
		}
	}

	//Added in DEV by Mr.Nice
	`IFGETAB(LethalDose)
	{
		bSetMiss=true;
		for (i=0; i < Ability.AbilityTargetEffects.length; i++)
		{
			DazedEffect=X2Effect_Dazed(Ability.AbilityTargetEffects[i]);
			if (DazedEffect==none) continue;
			if (bSetMiss)
			{
				DazedEffect.VisualizationFn = static.DazedVisualizationShowMiss;
				bSetMiss=false;
			}
			else
			{
				DazedEffect.VisualizationFn = static.DazedVisualization;
				break;
			}
		}
	}

	`DEBUG("class'MCM_Defaults'.default.TH_UNSAFE_AIM_ASSIST:" @ class'MCM_Defaults'.default.TH_UNSAFE_AIM_ASSIST);
	`DEBUG("class'ExtendedInformationRedux3_MCMScreen'.default.TH_UNSAFE_AIM_ASSIST:" @ class'ExtendedInformationRedux3_MCMScreen'.default.TH_UNSAFE_AIM_ASSIST);

	// Tigrik: Check if certain mods are active and cache the result in config variables
	class'ModSupportLib'.static.Init();

	// Tigrik: Disable Aim Assist if needed
	class'AimAssistLib'.static.Init();

	// Tigrik: Run all unit tests
	class'EIR_TestRunner'.static.RunAllTests();

	`TRACE_EXIT("");
}	

//	DazedEffectHitChance.VisualizationFn = DazedVisualization;

//Mr. Nice: Function only copied here because it is private, so can't access it directly in X2StatusEffects_Xpack

static function string GetDazedFlyoverText(XComGameState_Unit TargetState, bool FirstApplication)
{
	local XComGameState_Effect EffectState;
	local X2AbilityTag AbilityTag;
	local string ExpandedString; // bsg-dforrest (7.27.17): need to clear out ParseObject

	`TRACE_ENTRY("");
	EffectState = TargetState.GetUnitAffectedByEffectState(class'X2AbilityTemplateManager'.default.DazedName);
	if (FirstApplication || (EffectState != none && EffectState.GetX2Effect().IsTickEveryAction(TargetState)))
	{
		AbilityTag = X2AbilityTag(`XEXPANDCONTEXT.FindTag("Ability"));
		AbilityTag.ParseObj = TargetState;
		// bsg-dforrest (7.27.17): need to clear out ParseObject
		ExpandedString = `XEXPAND.ExpandString(class'X2StatusEffects_XPack'.default.DazedPerActionFriendlyName);
		AbilityTag.ParseObj = none;
		`TRACE_EXIT("");
		return ExpandedString;
		// bsg-dforrest (7.27.17): end
	}
	else
	{
		`TRACE_EXIT("");
		return class'X2StatusEffects_XPack'.default.DazedFriendlyName;
	}
}


static function DazedVisualizationShowMiss(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{	
	local XComGameStateContext_Ability	Context;
	local X2TacticalGameRuleset_BreakdownObserver BreakdownObserver;
	local X2GameRulesetEventObserverInterface Observer;

	local int HitChance;
	local string hittext;

	`TRACE_ENTRY("");
	if (EffectApplyResult == 'AA_Success')
	{	
		DazedVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
		return;
	}

	if(!getHIT_CHANCE_ENABLED())
	{
		//class'X2StatusEffects_XPack'.static.DazedVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
		return;
	}
	//Just because this effect isn't a Success, don't mean the ability "missed" this target
	//Since can have multiple "tiers" of dazed effects, this just happens to be the one asked
	//to show the miss, if appropriate;
	//Code basically nicked from x2action_applyweapondamage

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	if (Context == none) return;

	Observer = `GAMERULES.GetEventObserverOfType(class'X2TacticalGameRuleset_BreakdownObserver');
	BreakdownObserver = X2TacticalGameRuleset_BreakdownObserver(Observer);
	HitChance = BreakdownObserver.FindBreakdown(Context, ActionMetadata.StateObject_OldState);
	if (HitChance != -1)
	{
		if(getDISPLAY_MISS_CHANCE()) HitChance = 100 - HitChance;

		HitText = class'XComGameStateContext_WillRoll'.default.ResistedText @ "-" @ HitText $ ":" @ HitChance $ "%";
		class'X2StatusEffects'.static.AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), HitText, '', eColor_Good, class'UIUtilities_Image'.const.UnitStatus_Stunned);
	}
	`TRACE_EXIT("");
}

static function DazedVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit TargetState;

	local XComGameStateContext_Ability	Context;

	local X2TacticalGameRuleset_BreakdownObserver BreakdownObserver;
	local X2GameRulesetEventObserverInterface Observer;

	local int HitChance;
	local string hittext;

	`TRACE_ENTRY("");
	if(!getHIT_CHANCE_ENABLED())
	{
		class'X2StatusEffects_XPack'.static.DazedVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
		return;
	}

	if (EffectApplyResult != 'AA_Success')
	{	
		return;
	}

	TargetState = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(ActionMetadata.StateObject_NewState.ObjectID));
	if (TargetState == none)
		return;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	Observer = `GAMERULES.GetEventObserverOfType(class'X2TacticalGameRuleset_BreakdownObserver');
	BreakdownObserver = X2TacticalGameRuleset_BreakdownObserver(Observer);
	HitChance = BreakdownObserver.FindBreakdown(Context, ActionMetadata.StateObject_OldState);
	if (HitChance != -1)
	{
		if(getDISPLAY_MISS_CHANCE()) HitChance = 100 - HitChance;

		HitText = " -" @ `GETHITTEXT $ ":" @ HitChance $ "%";
	}


	class'X2StatusEffects'.static.AddEffectSoundAndFlyOverToTrack(ActionMetadata, Context, GetDazedFlyoverText(TargetState, true) $ HitText, '', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Stunned);
	class'X2StatusEffects'.static.AddEffectMessageToTrack(ActionMetadata,
														  class'X2StatusEffects_XPack'.default.DazedEffectAcquiredString,
														  Context,
														  class'UIEventNoticesTactical'.default.DazedTitle,
														  class'UIUtilities_Image'.const.UnitStatus_Stunned,
														  eUIState_Bad);
	class'X2StatusEffects'.static.UpdateUnitFlag(ActionMetadata, Context);
	`TRACE_EXIT("");
}

static function MindSpinControlVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	`TRACE_ENTRY("");
	//MrNice: Just want to avoid the specific "Mind control failed" flyover, it's redundant & confusing for Mind Spin
	if (EffectApplyResult == 'AA_Success')
		class'X2StatusEffects'.static.MindControlVisualization(VisualizeGameState, ActionMetaData, EffectApplyResult);
	`TRACE_EXIT("");
}

static function Vengeance_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local StateObjectReference MovingUnitRef;
	local VisualizationActionMetadata ActionMetadata;
	local VisualizationActionMetadata EmptyTrack;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_EnvironmentDamage EnvironmentDamage;
	local X2Action_PlaySoundAndFlyOver CharSpeechAction;
	local X2Action_Grapple GrappleAction;
	local X2Action_ExitCover ExitCoverAction;
	local X2Action_Fire FireMissAction;
	
	local X2TacticalGameRuleset_BreakdownObserver BreakdownObserver;
	local X2GameRulesetEventObserverInterface Observer;

	local int HitChance;
	local string hittext;

	`TRACE_ENTRY("");
	History = `XCOMHISTORY;
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	MovingUnitRef = AbilityContext.InputContext.SourceObject;

	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(MovingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(MovingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(MovingUnitRef.ObjectID);

	ExitCoverAction = X2Action_ExitCover(class'X2Action_ExitCover'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	ExitCoverAction.bUsePreviousGameState = true;

	Observer = `GAMERULES.GetEventObserverOfType(class'X2TacticalGameRuleset_BreakdownObserver');
	BreakdownObserver = X2TacticalGameRuleset_BreakdownObserver(Observer);
	HitChance = BreakdownObserver.FindBreakdown(AbilityContext, ActionMetadata.StateObject_OldState);
	if (HitChance != -1)
	{
		if(getDISPLAY_MISS_CHANCE()) HitChance = 100 - HitChance;

		HitText = " -" @ `GETHITTEXT $ ":" @ HitChance $ "%";
	}


	if (!AbilityContext.IsResultContextMiss())
	{
		CharSpeechAction = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
		CharSpeechAction.SetSoundAndFlyOverParameters(None, `LOCFALLBACK(Grappled, Localize("SkirmisherGrapple X2AbilityTemplate", "LocFriendlyName", "XComGame")) $ HitText, 'GrapplingHook', eColor_Good);

		GrappleAction = X2Action_Grapple(class'X2Action_Grapple'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
		GrappleAction.DesiredLocation = `XWORLD.GetPositionFromTileCoordinates(XComGameState_Unit(ActionMetadata.StateObject_NewState).TileLocation);

		// destroy any windows we flew through
		foreach VisualizeGameState.IterateByClassType(class'XComGameState_EnvironmentDamage', EnvironmentDamage)
		{
			ActionMetadata = EmptyTrack;

			//Don't necessarily have a previous state, so just use the one we know about
			ActionMetadata.StateObject_OldState = EnvironmentDamage;
			ActionMetadata.StateObject_NewState = EnvironmentDamage;
			ActionMetadata.VisualizeActor = History.GetVisualizer(EnvironmentDamage.ObjectID);

			class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);
			class'X2Action_ApplyWeaponDamageToTerrain'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext());
		}
	}
	else
	{
		CharSpeechAction = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
		CharSpeechAction.SetSoundAndFlyOverParameters(None, class'XLocalizedData'.default.MissedMessage $ HitText, '', eColor_Bad);
		FireMissAction = X2Action_Fire(class'X2Action_Fire'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, ExitCoverAction));
		class'X2Action_EnterCover'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, FireMissAction);
	}
	`TRACE_EXIT("");
}

`MCM_CH_STATICVersionChecker(class'MCM_Defaults'.default.VERSION, class'ExtendedInformationRedux3_MCMScreen'.default.CONFIG_VERSION)

simulated static function bool getHIT_CHANCE_ENABLED()
{	
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.HIT_CHANCE_ENABLED, class'ExtendedInformationRedux3_MCMScreen'.default.HIT_CHANCE_ENABLED);
}

simulated static function bool getDISPLAY_MISS_CHANCE()
{	
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.DISPLAY_MISS_CHANCE, class'ExtendedInformationRedux3_MCMScreen'.default.DISPLAY_MISS_CHANCE);
}

simulated static function bool getVERBOSE_TEXT()
{	
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.VERBOSE_TEXT, class'ExtendedInformationRedux3_MCMScreen'.default.VERBOSE_TEXT);
}