/**
 * HUD extension for enemy units that adds hit chance visualization.
 *
 * Enhances the default enemy HUD by:
 * - Calculating hit chance dynamically based on current or hovered ability
 * - Supporting aim assist adjustments
 * - Optionally displaying miss chance instead of hit chance
 *
 * @author tjnome / Mr.Nice / Sebkulu
 */
class UITacticalHUD_Enemies_HitChance extends UITacticalHUD_Enemies;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)
`include(ExtendedInformationRedux3\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

var bool TH_AIM_ASSIST;
var bool DISPLAY_MISS_CHANCE;

/**
 * Calculates the hit chance for a given target reference.
 *
 * Determines:
 * - Active targeting ability (hovered or selected)
 * - Shot breakdown using HitCalcLib
 * - Final hit or miss chance based on configuration
 *
 * Handles:
 * - Multishot abilities
 * - Hidden shot breakdowns
 * - Default targeting fallback if no ability is selected
 *
 * @param TargetRef Reference to the target object
 * @return Hit (or miss) chance in range [0,100], or -1 if unavailable
 */
simulated function int GetHitChanceForObjectRef(StateObjectReference TargetRef)
{
	local AvailableAction Action;
	local AvailableTarget			kTarget;
	local ShotBreakdown Breakdown;
	local X2TargetingMethod TargetingMethod;
	local XComGameState_Ability AbilityState;
	local int HitChance;
	local int clamped;

	`TRACE_ENTRY("");
	//If a targeting action is active and we're hoving over the enemy that matches this action, then use action percentage for the hover  
	TargetingMethod = XComPresentationLayer(screen.Owner).GetTacticalHUD().GetTargetingMethod();

	if(TargetingMethod != none && TargetingMethod.GetTargetedObjectID() == TargetRef.ObjectID)
	{
		AbilityState = TargetingMethod.Ability;
	}
	else
	{			
		AbilityState = XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kAbilityHUD.GetCurrentSelectedAbility();

		if(AbilityState == None) {
			XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kAbilityHUD.GetDefaultTargetingAbility(TargetRef.ObjectID, Action, true);
			AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Action.AbilityObjectRef.ObjectID));
		}
	}

	if(AbilityState != none)
	{
		kTarget.PrimaryTarget=TargetRef;
		class'HitCalcLib'.static.GetShotBreakdownDiffAdjust(AbilityState, kTarget, Breakdown);
		
		if(!Breakdown.HideShotBreakdown)
		{
			HitChance = Breakdown.bIsMultishot ? Breakdown.MultiShotHitChance : Breakdown.FinalHitChance;

			if (getDISPLAY_MISS_CHANCE())
				HitChance = 100 - HitChance;
			
			clamped = Clamp(HitChance, 0, 100);
			`TRACE_EXIT("Return:" @ clamped);
			return clamped;
	    }
	}
	`TRACE_EXIT("Return: -1");
	return -1;
}

`MCM_CH_VersionChecker(class'MCM_Defaults'.default.VERSION, class'ExtendedInformationRedux3_MCMScreen'.default.CONFIG_VERSION)

function bool GetDISPLAY_MISS_CHANCE() {
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.DISPLAY_MISS_CHANCE, class'ExtendedInformationRedux3_MCMScreen'.default.DISPLAY_MISS_CHANCE);
}
