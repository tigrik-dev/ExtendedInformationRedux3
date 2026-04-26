/**
 * AbilityLib
 *
 * Utility class responsible for:
 * - Managing ability-level configuration for effect chance previews
 * - Providing helper functions related to abilities (e.g. blacklist checks, shot count)
 *
 * This class acts as a bridge between config-driven behavior and runtime logic.
 *
 * Responsibilities:
 * - Determine whether an ability should be excluded from chance preview systems
 * - Resolve number of shots an ability performs (including multi-shot abilities)
 *
 * Config:
 * - AbilityChancePreviewBlacklist:
 *     List of abilities excluded from ApplyChance preview logic
 *
 * @author Tigrik
 */
class AbilityLib extends Object config(EffectChancePreview);

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

var config array<string> AbilityChancePreviewBlacklist;

/**
 * Checks whether an ability is blacklisted from chance preview.
 *
 * The ability is identified using a fully-qualified key:
 * "<PackageName>.<AbilityTemplateName>"
 *
 * Example:
 * "XComGame.Insanity"
 * "MyMod.CustomAbility"
 *
 * @param AbilityState    Ability instance to check
 *
 * @return bool           True if ability is in blacklist
 */
static function bool IsAbilityBlacklisted(XComGameState_Ability AbilityState)
{
    local string FullKey;

	`TRACE_ENTRY("");
    if (AbilityState == none)
        return false;

    FullKey = string(AbilityState.Class.Outer.Name) $ "." $ string(AbilityState.GetMyTemplateName());

    `TRACE("Checking blacklist for:" @ FullKey);

    if (default.AbilityChancePreviewBlacklist.Find(FullKey) != INDEX_NONE)
    {
        `DEBUG("Ability is BLACKLISTED:" @ FullKey);
        return true;
    }

	`TRACE_EXIT("Ability is not blacklisted:" @ FullKey);
    return false;
}

/**
 * Returns the total number of shots an ability performs.
 *
 * Default behavior:
 * - Returns 1 for standard abilities
 *
 * Special handling:
 * - If ability uses X2AbilityMultiTarget_BurstFire,
 *   total shots = 1 + NumExtraShots
 *
 * This is used for calculating cumulative probabilities of effects
 * applied multiple times within a single ability execution.
 *
 * @param Template    Ability template
 *
 * @return int        Total number of shots
 */
static function int GetNumShots(X2AbilityTemplate Template)
{
    local X2AbilityMultiTarget_BurstFire Burst;
	local int Result;

	`TRACE_ENTRY("");
	Result = 1;

	if (Template == none)
	{
		`DEBUG("Template == none. Return: 1");
		return Result;
	}

    Burst = X2AbilityMultiTarget_BurstFire(Template.AbilityMultiTargetStyle);

    if (Burst != none)
    {
		Result += Burst.NumExtraShots;
		`DEBUG("X2AbilityMultiTarget_BurstFire detected. NumExtraShots:" @ Burst.NumExtraShots);
		`TRACE_EXIT("Return:" @ Result);
        return Result;
    }

	`TRACE_EXIT("Return: 1");
    return Result;
}