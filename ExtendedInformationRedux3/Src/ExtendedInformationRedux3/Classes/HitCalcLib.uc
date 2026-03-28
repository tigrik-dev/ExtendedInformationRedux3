/**
 * HitCalcLib
 *
 * Utility class responsible for calculating hit chance adjustments
 * based on difficulty modifiers, aim assist, and gameplay conditions.
 *
 * Responsibilities:
 * - Compute shot breakdown with optional difficulty adjustment
 * - Apply aim assist logic for XCOM and AI units
 * - Replicate and extend vanilla hit chance modification logic
 *
 * @author Mr. Nice
 */
class HitCalcLib extends Object;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

var localized string LOWER_DIFFICULTY_MSG;
var localized string MISS_STREAK_MSG;
var localized string SOLDIER_LOST_BONUS;

/**
 * Calculates shot hit chance with optional difficulty adjustment applied.
 *
 * @param kAbility     Ability used for the shot
 * @param kTarget      Target information for the shot
 * @param kBreakdown   (out) Detailed shot breakdown information
 * @param DiffAdjust   (out) Calculated difficulty adjustment applied to hit chance
 *
 * @return int         Final hit chance after adjustments
 */
static function int GetShotBreakdownDiffAdjust(XComGameState_Ability kAbility, AvailableTarget kTarget, optional out ShotBreakdown kBreakdown, optional out int DiffAdjust)
{
	local int HitChance;
	local X2AbilityToHitCalc_StandardAim HitCalcStandard;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState, TargetState;

	`TRACE_ENTRY("");

	HitChance = kAbility.GetShotBreakdown(kTarget, kBreakdown);
	
	HitCalcStandard=X2AbilityToHitCalc_StandardAim(kAbility.GetMyTemplate().AbilityToHitCalc);
	History=`XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));

	if( HitCalcStandard != none &&
		getTH_AIM_ASSIST() &&
		//  reaction  fire shots and guaranteed hits do not get adjusted for difficulty
		UnitState != None &&
		!HitCalcStandard.bReactionFire &&
		!HitCalcStandard.bGuaranteedHit && 
		kBreakdown.SpecialGuaranteedHit == '')
	{
		TargetState = XComGameState_Unit(History.GetGameStateForObjectID(kTarget.PrimaryTarget.ObjectID));
		DiffAdjust = GetModifiedHitChance(HitCalcStandard, Unitstate, TargetState, kBreakdown.FinalHitChance, kBreakdown.Modifiers);
		kBreakdown.FinalHitChance+= DiffAdjust;
		HitChance = kBreakdown.FinalHitChance;
	}
	`TRACE_EXIT("HitChance:" @ HitChance $ ", DiffAdjust:" @ DiffAdjust);
	return HitChance;
}

/**
 * Computes modified hit chance based on difficulty, aim assist,
 * miss streaks, and squad status.
 *
 * Mirrors and extends vanilla XCOM logic for hit chance adjustment.
 *
 * Mr. Nice: Basicly same function as GetModifiedHitChanceForCurrentDifficulty() from X2AbilityToHitCalc_StandardAim
 *
 * @param HitCalc        Hit calculation template
 * @param UnitState      Attacking unit
 * @param TargetState    Target unit
 * @param BaseHitChance  Base hit chance before adjustments
 * @param Modifiers      (out) List of applied modifiers for UI breakdown
 *
 * @return int           Total difficulty adjustment applied
 */
static function int GetModifiedHitChance(X2AbilityToHitCalc_StandardAim HitCalc, XComGameState_Unit UnitState, XComGameState_Unit TargetState, int BaseHitChance, optional out array<ShotModifierInfo> Modifiers)
{
	local int  DiffAdjust, CurrentLivingSoldiers, SoldiersLost, AssistHeadRoom;
	local ShotModifierInfo Modifier;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local ETeam TargetTeam;

	local XComGameState_Player Instigator;

	`TRACE_ENTRY("BaseHitChance:" @ BaseHitChance);

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if( Unit.GetTeam() == eTeam_XCom && !Unit.bRemovedFromPlay && Unit.IsAlive() && !Unit.GetMyTemplate().bIsCosmetic )
		{
			++CurrentLivingSoldiers;
		}
	}
	SoldiersLost = Max(0, HitCalc.NormalSquadSize - CurrentLivingSoldiers);

	if (TargetState != none)
	{
		TargetTeam = Unit.GetTeam( );
	}

	Instigator = XComGameState_Player(History.GetGameStateForObjectID(UnitState.GetAssociatedPlayerID()));

	// XCom gets 20% bonus to hit for each consecutive miss made already this turn
	if(Instigator.TeamFlag == eTeam_XCom )
	{
		AssistHeadRoom=HitCalc.MaxAimAssistScore-BaseHitChance;
		if (AssistHeadRoom<=0) return 0;

		//Difficulty multiplier
		Modifier.Value = BaseHitChance * `ScaleTacticalArrayFloat(HitCalc.BaseXComHitChanceModifier) - BaseHitChance; // 1.2
		Modifier.Value = Clamp(Modifier.Value, 0, AssistHeadRoom);

		// DifficultyBonus
		// Fixing name issue later with localization
		if (Modifier.Value > 0)
		{
			// Add to Stats (ProcessBreakDown)
			Modifier.Reason =default.LOWER_DIFFICULTY_MSG;
			Modifiers.AddItem(Modifier);
			DiffAdjust+=Modifier.Value;
			AssistHeadRoom-=Modifier.Value;
		}

		if(BaseHitChance >= HitCalc.ReasonableShotMinimumToEnableAimAssist) // 50
		{ 
			Modifier.Value = Min(AssistHeadRoom, Instigator.MissStreak * `ScaleTacticalArrayInt(HitCalc.MissStreakChanceAdjustment)); // 20
			//Miss Bonus!
			// Fixing name issue later with localization
			if (Modifier.Value > 0)
			{
				// Add to Stats (ProcessBreakDown)
				Modifier.Reason = default.MISS_STREAK_MSG;
				Modifiers.AddItem(Modifier);
				DiffAdjust+=Modifier.Value;
				AssistHeadRoom-=Modifier.Value;
			}

			Modifier.Value = Min(AssistHeadRoom, SoldiersLost * `ScaleTacticalArrayInt(HitCalc.SoldiersLostXComHitChanceAdjustment));
			// Squady lost bonus
			// Fixing name issue later with localization
			if (Modifier.Value > 0)
			{
				// Add to Stats (ProcessBreakDown)
				Modifier.Reason = default.SOLDIER_LOST_BONUS;
				Modifiers.AddItem(Modifier);
				DiffAdjust+=Modifier.Value;
				AssistHeadRoom-=Modifier.Value;
			}
		}
	}
	// Aliens get -10% chance to hit for each consecutive hit made already this turn; this only applies if the XCom currently has less than 5 units alive
	else if( Instigator.TeamFlag == eTeam_Alien || Instigator.TeamFlag == eTeam_TheLost )
	{
		if( CurrentLivingSoldiers <= HitCalc.NormalSquadSize ) // 4
		{
			DiffAdjust =
				Instigator.HitStreak * `ScaleTacticalArrayInt(HitCalc.HitStreakChanceAdjustment) + // -10
				SoldiersLost * `ScaleTacticalArrayInt(HitCalc.SoldiersLostAlienHitChanceAdjustment); // -25
		}

		if( Instigator.TeamFlag == eTeam_Alien && TargetTeam == eTeam_TheLost )
		{
			DiffAdjust += `ScaleTacticalArrayFloat(HitCalc.AlienVsTheLostHitChanceAdjustment);
		}
		else if( Instigator.TeamFlag == eTeam_TheLost && TargetTeam == eTeam_Alien )
		{
			DiffAdjust += `ScaleTacticalArrayFloat(HitCalc.TheLostVsAlienHitChanceAdjustment);
		}
		DiffAdjust=Min(DiffAdjust, HitCalc.MaxAimAssistScore - BaseHitChance);
		Modifier.Value= DiffAdjust;
		if (Modifier.Value < 0) //Remember, aliens only get negative adjustments!
		{
			// Add to Stats (ProcessBreakDown)
			Modifier.Reason = default.LOWER_DIFFICULTY_MSG;
			Modifiers.AddItem(Modifier);
		}
	}
	`TRACE_EXIT("DiffAdjust:" @ DiffAdjust);
	return DiffAdjust;
}

`include(ExtendedInformationRedux3\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

/**
 * Retrieves configuration value for aim assist feature toggle.
 *
 * @return bool     True if aim assist is enabled, false otherwise
 */
simulated static function bool getTH_AIM_ASSIST()
{	
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.TH_AIM_ASSIST, class'ExtendedInformationRedux3_MCMScreen'.default.TH_AIM_ASSIST);
}



`MCM_CH_StaticVersionChecker(class'MCM_Defaults'.default.VERSION, class'ExtendedInformationRedux3_MCMScreen'.default.CONFIG_VERSION)