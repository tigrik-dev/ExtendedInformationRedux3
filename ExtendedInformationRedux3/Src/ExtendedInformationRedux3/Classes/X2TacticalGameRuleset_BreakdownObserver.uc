/**
 * Captures hit chance breakdowns at the moment abilities are processed.
 *
 * Hooks into PreBuildGameStateFromContext, which runs BEFORE RNG is resolved.
 *
 * Stores:
 * - Primary target breakdown
 * - Multi-target breakdowns
 *
 * This guarantees that later UI (flyovers, damage previews) uses
 * the exact hit chance that the game used internally.
 *
 * @author Mr.Nice
 */
class X2TacticalGameRuleset_BreakdownObserver extends Object implements(X2GameRulesetEventObserverInterface);;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

/// <summary>
/// Called immediately prior to the creation of a new game state via SubmitGameStateContext. New game states can be submitted
/// prior to a game state being created with this context
/// </summary>
/// <param name="NewGameState">The state to examine</param>
struct BreakdownHistory
{
	var int HistoryIndex;
	var ShotBreakdown PrimaryBreakdown;
	var array<ShotBreakdown> MultiTargetBreakdown;
};

var array<BreakdownHistory> Breakdowns;

/**
 * Called immediately prior to the creation of a new game state via SubmitGameStateContext.
 *
 * @param NewGameStateContext  The state context being examined
 */
event PreBuildGameStateFromContext(XComGameStateContext NewGameStateContext)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Ability AbilityState;
	local X2AbilityToHitCalc HitCalc;
	local AvailableTarget kTarget;
	local BreakdownHistory BreakdownEntry;
	local ShotBreakdown kBreakdown;
	local int i;

	`TRACE_ENTRY("");
	AbilityContext = XComGameStateContext_Ability(NewGameStateContext);
	if (AbilityContext == none) return;

	History = `XCOMHISTORY;
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	HitCalc = AbilityState.GetMyTemplate().AbilityToHitCalc;
	if(HitCalc == none || X2AbilityToHitCalc_DeadEye(HitCalc) != none) return;

	BreakdownEntry.HistoryIndex = History.GetCurrentHistoryIndex();

	kTarget.PrimaryTarget = AbilityContext.InputContext.PrimaryTarget;
	class'HitCalcLib'.static.GetShotBreakdownDiffAdjust(AbilityState, kTarget, BreakdownEntry.PrimaryBreakdown);
	for (i = 0; i < AbilityContext.InputContext.MultiTargets.Length; i++)
	{
		kTarget.PrimaryTarget = AbilityContext.InputContext.MultiTargets[i];
		class'HitCalcLib'.static.GetShotBreakdownDiffAdjust(AbilityState, kTarget, kBreakdown);
		BreakdownEntry.MultiTargetBreakdown.AddItem(kBreakdown);
	}
	Breakdowns.AddItem(BreakdownEntry);
	`log(`showvar(Breakdowns.Length));
	`TRACE_EXIT("");
}

/// <summary>
/// This event is issued from within the context method ContextBuildGameState
/// </summary>
/// <param name="NewGameState">The state to examine</param>
event InterruptGameState(XComGameState NewGameState);

/// <summary>
/// Called immediately after the creation of a new game state via SubmitGameStateContext. 
/// Note that at this point, the state has already been committed to the history
/// </summary>
/// <param name="NewGameState">The state to examine</param>
event PostBuildGameState(XComGameState NewGameState);

/// <summary>
/// Allows the observer class to set up any internal state it needs to when it is created
/// </summary>
event Initialize();

/// <summary>
/// Event observers may use this to cache information about the state objects they need to operate on
/// </summary>
event CacheGameStateInformation();

/**
 * Finds the hit chance breakdown for a target within an ability context
 *
 * @param Context      The ability context
 * @param TargetState  The unit to query
 * @param Breakdown    Optional output for the full breakdown
 *
 * @return int         Final hit chance for the target, or -1 if not found
 */
function int FindBreakdown(XComGameStateContext_Ability Context, XComGameState_BaseObject TargetState,  optional out ShotBreakdown Breakdown)
{
	local int BreakdownIndex, MultiIndex;

	`TRACE_ENTRY("");
	BreakdownIndex = Breakdowns.Find('HistoryIndex', Context.GetFirstStateInInterruptChain().HistoryIndex - 1);
	if (BreakdownIndex == INDEX_NONE) return -1;

	if (Context.InputContext.PrimaryTarget.ObjectID == TargetState.ObjectID)
	{
		Breakdown = Breakdowns[BreakdownIndex].PrimaryBreakdown;
	}
	else 
	{
		MultiIndex = Context.InputContext.MultiTargets.Find('ObjectID', TargetState.ObjectID);
		if (MultiIndex == INDEX_NONE) return -1;
		Breakdown = Breakdowns[BreakdownIndex].MultiTargetBreakdown[MultiIndex];
	}
	`TRACE_EXIT("");
	return Breakdown.FinalHitChance;
}
