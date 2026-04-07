/**
 * AimAssistLib
 *
 * Utility class responsible for managing Aim Assist behavior and safety logic.
 *
 * Responsibilities:
 * - Determine whether Aim Assist should be disabled based on environment conditions
 * - Enforce safe defaults when unsafe Aim Assist is detected
 * - Integrate with MCM settings to reflect and control Aim Assist state
 *
 * Behavior:
 * - Automatically disables Aim Assist if it is considered unsafe and not explicitly allowed
 * - Considers Aim Assist unsafe when:
 *     - Highlander disables it (bDisableAimAssist), OR
 *     - Long War of the Chosen (LWOTC) is active
 *
 * @author Tigrik
 */
class AimAssistLib extends Object;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)
`include(ExtendedInformationRedux3\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

/**
 * Initializes Aim Assist state based on safety checks.
 *
 * Behavior:
 * - If Aim Assist is unsafe AND currently enabled:
 *     - Disables Aim Assist in both runtime and default config
 *     - Logs the reason for disabling
 *
 * Notes:
 * - Should be called during initialization phase
 * - Ensures consistency between UI (MCM) and actual behavior
 */
static final function Init()
{
	`TRACE_ENTRY("");
	if (ShouldDisableAimAssist() && getTH_AIM_ASSIST())
	{
		class'ExtendedInformationRedux3_MCMScreen'.default.TH_AIM_ASSIST = false;
		class'MCM_Defaults'.default.TH_AIM_ASSIST = false;
		`INFO("Aim Assist was disabled due to Highlander's bDisableAimAssist being true or due to detected Long War of the Chosen");
	}
	`TRACE_EXIT("");
}

/**
 * Determines whether Aim Assist should be disabled.
 *
 * @return bool   True if Aim Assist must be disabled, false otherwise
 *
 * Logic:
 * - Aim Assist is disabled if:
 *     - User has NOT enabled "Unsafe Aim Assist", AND
 *     - Aim Assist is considered unsafe (see IsAimAssistUnsafe)
 */
static final function bool ShouldDisableAimAssist()
{
	local bool Result;
	
	`TRACE_ENTRY("");

	Result = (!class'ExtendedInformationRedux3_MCMScreen'.default.TH_UNSAFE_AIM_ASSIST) && IsAimAssistUnsafe();

	`DEBUG("TH_UNSAFE_AIM_ASSIST:" @ getTH_UNSAFE_AIM_ASSIST() $
	", Highlander's bDisableAimAssist:" @ class'CHHelpers'.default.bDisableAimAssist $
	", is Long War of the Chosen loaded:" @ class'ModSupportLib'.default.bLwotcActive $
	", Should Aim Assist be disabled:" @ Result);
	`TRACE_EXIT("Return:" @ Result);
	return Result;
}

/**
 * Checks whether Aim Assist is unsafe in the current environment.
 *
 * @return bool   True if Aim Assist is unsafe, false otherwise
 *
 * Unsafe Conditions:
 * - Highlander explicitly disables Aim Assist (bDisableAimAssist), OR
 * - Long War of the Chosen (LWOTC) is active
 */
static final function bool IsAimAssistUnsafe()
{
	return (class'CHHelpers'.default.bDisableAimAssist || class'ModSupportLib'.default.bLwotcActive);
}

`MCM_CH_StaticVersionChecker(class'MCM_Defaults'.default.VERSION, class'ExtendedInformationRedux3_MCMScreen'.default.CONFIG_VERSION)

simulated static function bool getTH_AIM_ASSIST()
{	
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.TH_AIM_ASSIST, class'ExtendedInformationRedux3_MCMScreen'.default.TH_AIM_ASSIST);
}

simulated static function bool getTH_UNSAFE_AIM_ASSIST()
{	
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.TH_UNSAFE_AIM_ASSIST, class'ExtendedInformationRedux3_MCMScreen'.default.TH_UNSAFE_AIM_ASSIST);
}
