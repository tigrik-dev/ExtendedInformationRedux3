/**
 * Listener class for the Extended Information Redux 3 mod's MCM screens.
 * Handles screen initialization and ensures the custom MCMScreen is initialized
 * when the MCM_API is available for the given UIScreen.
 *
 * @author Mr.Nice / Sebkulu
 */
class ExtendedInformationRedux3_MCMScreenListener extends UIScreenListener;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

/**
 * Event called when a UIScreen is initialized.
 *
 * @param Screen The UIScreen instance that was just initialized.
 */
event OnInit(UIScreen Screen)
{
	local ExtendedInformationRedux3_MCMScreen DisplayHitChanceMCMScreen;
	
	`TRACE_ENTRY("");
	// Everything out here runs on every UIScreen. Not great but necessary.
	if (MCM_API(Screen) == none) return;

	if (ScreenClass==none) ScreenClass=Screen.Class;

	DisplayHitChanceMCMScreen = new class'ExtendedInformationRedux3_MCMScreen';
	DisplayHitChanceMCMScreen.OnInit(Screen);
	`TRACE_EXIT("");
}

defaultproperties
{
    ScreenClass = none;
}