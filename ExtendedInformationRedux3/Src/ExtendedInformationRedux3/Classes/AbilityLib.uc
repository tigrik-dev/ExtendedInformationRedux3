class AbilityLib extends Object config(EffectChancePreview);

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

var config array<string> AbilityChancePreviewBlacklist;

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