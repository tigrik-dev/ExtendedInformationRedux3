/**
 * ColorLib
 *
 * Utility class responsible for mapping configurable integer indices
 * to corresponding EUIState values used in XCOM 2 UI rendering.
 *
 * Responsibilities:
 * - Convert numeric color indices (e.g. from MCM config) into EUIState enums
 * - Provide a centralized mapping between config values and UI color states
 * - Handle invalid indices safely with logging and fallback behavior
 *
 * This allows UI elements (such as Shot HUD text) to dynamically use
 * different color styles based on user configuration.
 *
 * @author Tigrik
 */
class ColorLib extends Object;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)
`include(ExtendedInformationRedux3\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

/**
 * Converts a numeric color index into its corresponding EUIState value.
 *
 * Supported mappings:
 * - 0 ? eUIState_Good
 * - 1 ? eUIState_Bad
 * - 2 ? eUIState_Warning
 * - 3 ? eUIState_Warning2
 * - 4 ? eUIState_Psyonic
 * - 5 ? eUIState_Normal
 * - 6 ? eUIState_Cash
 * - 7 ? eUIState_Header
 * - 8 ? eUIState_Faded
 * - 9 ? eUIState_Disabled
 *
 * If an invalid index is provided, the function logs an error and
 * returns eUIState_Normal as a safe fallback.
 *
 * @param colorIndex   Integer index representing a UI color state (expected range: 0–9)
 *
 * @return EUIState    Corresponding UI state enum used for text styling
 */
static function EUIState IndexToEUIState(int colorIndex)
{
	`TRACE_ENTRY("colorIndex:" @ colorIndex);

	switch (colorIndex)
    {
        case 0: return eUIState_Good;
        case 1: return eUIState_Bad;
        case 2: return eUIState_Warning;
        case 3: return eUIState_Warning2;
		case 4: return eUIState_Psyonic;
        case 5: return eUIState_Normal;
        case 6: return eUIState_Cash;
        case 7: return eUIState_Header;
		case 8: return eUIState_Faded;
        case 9: return eUIState_Disabled;
    }

	`ERROR("Invalid color index - defaulting to eUIState_Normal. Expected: 0-9, Actual:" @ colorIndex);
	return eUIState_Normal;
}