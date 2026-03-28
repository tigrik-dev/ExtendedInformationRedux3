/**
 * HitChanceBuildVisualization
 *
 * Handles injection and customization of hit chance flyover messages
 * in the tactical HUD visualization system.
 *
 * Responsibilities:
 * - Wrap original ability visualization logic
 * - Retrieve precomputed hit chance values from BreakdownObserver
 * - Modify flyover text dynamically based on configuration
 * - Support verbose and miss chance display modes
 *
 * Designed for compatibility with existing visualization delegates.
 *
 * @author Mr.Nice / Sebkulu
 */
class HitChanceBuildVisualization extends Object;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)
`include(ExtendedInformationRedux3\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

/**
 * Macro that determines the label text used in the flyover message.
 *
 * Selects between:
 * - Hit vs Miss label (depending on DISPLAY_MISS_CHANCE)
 * - Verbose vs short text (depending on VERBOSE_TEXT)
 *
 * This replaces duplicated conditional logic with a single reusable macro.
 */
`define GETHITTEXT ( getDISPLAY_MISS_CHANCE() ? (getVERBOSE_TEXT() ? Caps(class'X2TacticalGameRulesetDataStructures'.default.m_aAbilityHitResultStrings[eHit_Miss]) : class'X2Action_ApplyWeaponDamageToUnit_HITCHANCE'.default.SHORT_MISS_CHANCE) \\
	: (getVERBOSE_TEXT() ? class'UITacticalHUD_ShotHUD'.default.m_sShotChanceLabel : class'X2Action_ApplyWeaponDamageToUnit_HITCHANCE'.default.SHORT_HIT_CHANCE) )

// Localized Array(s) required
var bool		DISPLAY_MISS_CHANCE;
var bool		HIT_CHANCE_ENABLED;
var bool		VERBOSE_TEXT;

/**
 * Stores the original BuildVisualization function.
 *
 * Allows this class to wrap or replace the default visualization logic
 * without hardcoding a specific implementation.
 *
 * Enables compatibility with abilities that override visualization.
 */
var delegate<X2AbilityTemplate.BuildVisualizationDelegate> OrigBuildVisualizationFn;

//var localized string HIT_CHANCE_LABEL;

var array<string> FlyoverMessages;

/**
 * Factory method to create a HitChanceBuildVisualization instance.
 *
 * If no original visualization function is provided, defaults to
 * X2Ability.TypicalAbility_BuildVisualization.
 *
 * This allows injecting this visualization logic while preserving
 * the original behavior.
 */
static function HitChanceBuildVisualization CreateFlyoverVisualization(optional delegate<X2AbilityTemplate.BuildVisualizationDelegate> _OrigBuildVisualizationFn)
{
	local HitChanceBuildVisualization NewVis;

	`TRACE_ENTRY("");
	NewVis=new default.Class;
	if (_OrigBuildVisualizationFn==none)
		NewVis.OrigBuildVisualizationFn=class'x2ability'.static.TypicalAbility_BuildVisualization;
	else
		NewVis.OrigBuildVisualizationFn=_OrigBuildVisualizationFn;

	`TRACE_EXIT("");
	return NewVis;
}

function BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateVisualizationMgr VisMgr;
	local X2Action						Action;
	local Array<X2Action>				arrActions;

	local XComGameStateContext_Ability	Context;

	/**
	 * Observer used to access stored hit chance breakdowns.
	 *
	 * X2GameRulesetEventObserverInterface provides access to systems
	 * that listen to and store gameplay events.
	 *
	 * BreakdownObserver specifically tracks shot breakdown data at
	 * the time it is calculated.
	 */
	local X2TacticalGameRuleset_BreakdownObserver BreakdownObserver;
	local X2GameRulesetEventObserverInterface Observer;

	local int							hitChance;
	
	local string						hittext;

	`TRACE_ENTRY("");
	
	/**
	 * Calls the original visualization function through a delegate.
	 *
	 * Ensures compatibility with abilities that override visualization,
	 * instead of always forcing TypicalAbility_BuildVisualization.
	 */
	OrigBuildVisualizationFn(VisualizeGameState);

	// Here we're gonna lookup into a struct array to see if flyover message matches one of our already defined Message for targeted Ability
	if(getHIT_CHANCE_ENABLED())
	{
		//Fill in those context/state variables
		Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
		
		/**
		 * Retrieves the BreakdownObserver from the game ruleset.
		 *
		 * This observer contains stored hit chance calculations captured
		 * at the moment abilities were executed.
		 *
		 * Replaces historical reconstruction of hit chance.
		 */
		Observer = `GAMERULES.GetEventObserverOfType(class'X2TacticalGameRuleset_BreakdownObserver');
		BreakdownObserver = X2TacticalGameRuleset_BreakdownObserver(Observer);

		VisMgr = `XCOMVISUALIZATIONMGR;
		VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action_PlaySoundAndFlyOver', arrActions);

		// Uses macro to determine flyover label text.
		hittext = `GETHITTEXT;

		//look through those actions for the expected flyoverstrings;
		foreach arrActions(action)
		{
			if (FlyoverMessages.Find(X2Action_PlaySoundAndFlyOver(Action).FlyOverMessage) != INDEX_NONE)
			{
				/**
				 * Retrieves hit chance from BreakdownObserver instead of recomputing it.
				 *
				 * Old behavior:
				 * - Reconstructed shot context from history
				 * - Recomputed hit chance via HitCalcLib
				 * - Could produce inaccurate values due to desync or state changes
				 *
				 * New behavior:
				 * - Uses stored hit chance captured at execution time
				 * - Guarantees consistency with actual game logic
				 *
				 * Returns -1 if no breakdown is found.
				 */
				HitChance = BreakdownObserver.FindBreakdown(Context, Action.Metadata.StateObject_OldState);

				// Ensures a valid breakdown was found before using it
				if (HitChance != -1)
				{
					if(getDISPLAY_MISS_CHANCE())
					{
						HitChance = 100 - HitChance;
					}
					X2Action_PlaySoundAndFlyOver(Action).FlyOverMessage @= "-" @ HitText $ ":" @ HitChance $ "%";
				}
			}
		}
	}
	`TRACE_EXIT("");
}

`MCM_CH_VersionChecker(class'MCM_Defaults'.default.VERSION, class'ExtendedInformationRedux3_MCMScreen'.default.CONFIG_VERSION)

simulated function bool getHIT_CHANCE_ENABLED()
{	
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.HIT_CHANCE_ENABLED, class'ExtendedInformationRedux3_MCMScreen'.default.HIT_CHANCE_ENABLED);
}

simulated function bool getDISPLAY_MISS_CHANCE()
{	
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.DISPLAY_MISS_CHANCE, class'ExtendedInformationRedux3_MCMScreen'.default.DISPLAY_MISS_CHANCE);
}

simulated function bool getVERBOSE_TEXT()
{	
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.VERBOSE_TEXT, class'ExtendedInformationRedux3_MCMScreen'.default.VERBOSE_TEXT);
}


