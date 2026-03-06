//-----------------------------------------------------------
//	Class:	ExtendedInformationRedux3_MCMScreen
//	Author: Mr.Nice / Sebkulu
//	
//-----------------------------------------------------------

class ExtendedInformationRedux3_MCMScreenListener extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local ExtendedInformationRedux3_MCMScreen DisplayHitChanceMCMScreen;
	
	// Everything out here runs on every UIScreen. Not great but necessary.
	if (MCM_API(Screen) != none)
	{
		DisplayHitChanceMCMScreen = new class'ExtendedInformationRedux3_MCMScreen';
		DisplayHitChanceMCMScreen.OnInit(Screen);
	}
}

defaultproperties
{
    ScreenClass = class'MCM_API';
}