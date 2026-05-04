/**
 * DamageLib
 *
 * Utility class responsible for formatting damage-related UI strings
 * for Shot HUD display in XCOM 2.
 *
 * Responsibilities:
 * - Format critical damage strings based on configuration settings
 * - Support multiple display modes (bonus vs total crit damage)
 * - Ensure consistent string formatting using range macros
 *
 * The behavior is controlled via MCM setting C_DMG_MODE.
 *
 * @author Tigrik
 */
class DamageLib extends Object;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)
`include(ExtendedInformationRedux3\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)
`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_UtilityMacros.uci)

/**
 * Returns a formatted critical damage string based on configuration.
 *
 * Modes:
 * 0 - Always show crit bonus (e.g. "+4-6")
 * 1 - Always show total crit damage (e.g. "5-7")
 * 2 - Show total damage only when crit damage is a range (Min != Max)
 * 3 - Show total damage only when crit range is "inverted"
 *     (Max Crit Bonus < Min Crit Bonus)
 *
 * @param NormalDamage    Breakdown containing minimum and maximum non-crit damage
 * @param CritDamage      Breakdown containing minimum and maximum crit bonus damage
 *
 * @return string         Formatted crit damage string for UI display
 */
static function string GetCritDamageString(DamageBreakdown NormalDamage, DamageBreakdown CritDamage)
{
	local string Result;
	local int Mode;
	local bool bUseTotal;

	`TRACE_ENTRY("NormalDamage:" @ class'DamagePreviewLib'.static.DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ class'DamagePreviewLib'.static.DamageBreakdownToString(CritDamage));

	Mode = Get_C_DMG_MODE();
	bUseTotal = false;

	switch (Mode)
	{
		case 0: // Always Show Crit Bonus
			bUseTotal = false;
			break;

		case 1: // Always Show Total Damage
			bUseTotal = true;
			break;

		case 2: // Only Show Total Damage on Crit Ranges
			bUseTotal = (CritDamage.Min != CritDamage.Max);
			break;

		case 3: // Only Show Total Damage when Max Crit Bonus < Min Crit Bonus
			bUseTotal = (CritDamage.Max < CritDamage.Min);
			break;
	}

	Result = bUseTotal ? `RANGESTRING(NormalDamage.Min + CritDamage.Min, NormalDamage.Max + CritDamage.Max) : ("+" $ `RANGESTRING(CritDamage.Min, CritDamage.Max));

	`TRACE_EXIT("Return:" @ Result);
	return Result;
}

`MCM_CH_StaticVersionChecker(class'MCM_Defaults'.default.VERSION, class'ExtendedInformationRedux3_MCMScreen'.default.CONFIG_VERSION)

static function int Get_C_DMG_MODE()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.C_DMG_MODE, class'ExtendedInformationRedux3_MCMScreen'.default.C_DMG_MODE);
}