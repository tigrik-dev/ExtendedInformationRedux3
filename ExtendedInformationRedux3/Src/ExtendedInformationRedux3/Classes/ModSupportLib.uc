/**
 * ModSupportLib
 *
 * Utility class responsible for detecting presence of other mods
 * and exposing compatibility flags.
 *
 * Responsibilities:
 * - Detect whether specific mods are active (e.g., LWOTC)
 * - Store mod presence flags in config for global access
 *
 * Behavior:
 * - On initialization, checks for known mods and caches results
 * - Currently supports detection of:
 *     - Long War of the Chosen (LWOTC)
 *
 * @author Tigrik
 */
class ModSupportLib extends Object config(ExtendedInformationRedux3);

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

var config bool bLwotcActive;

/**
 * Initializes mod detection flags.
 *
 * Behavior:
 * - Checks whether Long War of the Chosen is active
 * - Stores result in bLwotcActive config variable
 */
static final function Init()
{
	`TRACE_ENTRY("");
	default.bLwotcActive = IsModActive('LongWarOfTheChosen');
	`TRACE_EXIT("bLwotcActive:" @ default.bLwotcActive);
}

/**
 * Checks whether a specific mod/DLC is active.
 *
 * @param ModName   Name of the mod to check (e.g., 'LongWarOfTheChosen')
 *
 * @return bool     True if the mod is active, false otherwise
 */
static final function bool IsModActive(name ModName)
{
    local XComOnlineEventMgr    EventManager;
    local int                   Index;

	`TRACE_ENTRY("");
    EventManager = `ONLINEEVENTMGR;

    for (Index = EventManager.GetNumDLC() - 1; Index >= 0; Index--) 
    {
        if (EventManager.GetDLCNames(Index) == ModName) 
        {
			`TRACE_EXIT("Return: true");
            return true;
        }
    }
	`TRACE_EXIT("Return: false");
    return false;
}