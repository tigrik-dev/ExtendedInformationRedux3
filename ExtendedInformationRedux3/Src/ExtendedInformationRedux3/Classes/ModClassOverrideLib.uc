/**
 * ModClassOverrideLib
 *
 * Utility class responsible for resolving the final class name
 * after applying all Mod Class Overrides (MCOs).
 *
 * Responsibilities:
 * - Traverse the ModClassOverrides chain in Engine
 * - Resolve the final overridden class for a given base class
 * - Provide compatibility with mods that replace core classes (e.g. TacticalGameRuleset)
 *
 * This is required because some mods override base game classes,
 * and directly accessing the original class would bypass those overrides.
 *
 * @author Tigrik
 */
class ModClassOverrideLib extends Object;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

/**
 * Resolves the final class name after applying all Mod Class Overrides (MCOs)
 *
 * Iteratively walks through Engine.ModClassOverrides to find the last
 * override in the chain for the provided base class name.
 *
 * @param BaseClassName   Name of the base class to resolve
 *
 * @return name           Final resolved class name after all overrides
 */
static function name ResolveFinalClassName(name BaseClassName)
{
    local Engine LocalEngine;
    local ModClassOverrideEntry MCO;
    local name CurrentName;
    local int Idx;

    `TRACE_ENTRY("");

    LocalEngine = class'Engine'.static.GetEngine();
    CurrentName = BaseClassName;

    while (true)
    {
        Idx = LocalEngine.ModClassOverrides.Find('BaseGameClass', CurrentName);

        if (Idx == INDEX_NONE)
            break;

        MCO = LocalEngine.ModClassOverrides[Idx];

        `DEBUG("MCO chain:" @ CurrentName @ "->" @ MCO.ModClass);

        CurrentName = MCO.ModClass;
    }

    `TRACE_EXIT("Return:" @ CurrentName);
    return CurrentName;
}