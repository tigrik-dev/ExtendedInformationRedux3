class ApplyChanceLib extends Object dependson(_EffectLib) config(EffectChancePreview);

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)
`include(ExtendedInformationRedux3\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

var config array<string> EffectChancePreviewBlacklist;

static function string GetApplyChancesString(
    XComGameState_Ability AbilityState,
    StateObjectReference TargetRef,
    AvailableTarget kTarget
)
{
    local X2AbilityTemplate Template;
    local array<X2Effect> Effects;
    local X2Effect Effect;

    local XComGameState_Unit TargetUnit, SourceUnit;

    local ShotBreakdown kBreakdown;
    local int HitChance, MissChance;

    local array<EffectInfo> Infos;
    local EffectInfo Info;

    local int i, Idx;
    local string Result, Label, MissLabel;

    local bool bHasTarget;

    `TRACE_ENTRY("");

    if (AbilityState == none)
        return "";

    Template = AbilityState.GetMyTemplate();
    if (Template == none)
        return "";

	`TRACE("Ability:" @ AbilityState.GetMyTemplateName());

	if (class'AbilityLib'.static.IsAbilityBlacklisted(AbilityState))
	{
		`DEBUG("Skipping ability due to blacklist:" @ AbilityState.GetMyTemplateName());
		return "";
	}

    // === Target presence ===
    bHasTarget = (TargetRef.ObjectID != 0);
	`DEBUG("bHasTarget:" @ bHasTarget);

	Effects = bHasTarget ? Template.AbilityTargetEffects : Template.AbilityMultiTargetEffects;
    if (Effects.Length == 0)
        return "";

    // === Resolve units (ONLY if target exists) ===
    if (bHasTarget)
    {
        TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetRef.ObjectID));
        SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));

        if (TargetUnit == none)
            return "";
    }

    // === HIT / MISS ===
    if (bHasTarget)
    {
        AbilityState.GetShotBreakdown(kTarget, kBreakdown);

        HitChance = Clamp((kBreakdown.bIsMultishot ? kBreakdown.MultiShotHitChance : kBreakdown.FinalHitChance), 0, 100);

        MissChance = 100 - HitChance;
    }
    else
    {
        HitChance = 100;
        MissChance = 0;
    }

    `DEBUG("HitChance:" @ HitChance);
    `DEBUG("MissChance:" @ MissChance);

	if (HitChance <= 0) return "";

    // === Build effect list ===
    for (i = 0; i < Effects.Length; i++)
    {
        Effect = Effects[i];

		// Skip blacklisted effects
		if (IsEffectBlacklisted(Effect))
		{
			`DEBUG("SKIPPING EFFECT: Effect is blacklisted.");
			continue;
		}

        // Skip dynamic chance functions
        if (Effect.ApplyChanceFn != none)
		{
			`DEBUG("SKIPPING EFFECT: Effect.ApplyChanceFn != none.");
            continue;
		}

        // Skip zero chance
        if (Effect.ApplyChance <= 0) {
			`DEBUG("SKIPPING EFFECT: Effect.ApplyChance <= 0. Effect.ApplyChance:" @ Effect.ApplyChance);
            continue;
		}

		// Skip 100% chance unless it's enabled in MCM
        if (!GetSHOW_APPLY_CHANCE_GUARANTEED() && Effect.ApplyChance >= 100) {
			`DEBUG("SKIPPING EFFECT: Effect.ApplyChance >= 100. Effect.ApplyChance:" @ Effect.ApplyChance);
            continue;
		}

        // Conditions (ONLY if we have a target)
        if (bHasTarget)
        {
            if (!class'_EffectLib'.static.DoesEffectPassConditionsStrict(Effect, AbilityState, TargetUnit, SourceUnit))
                continue;
        }

        // Label
        Label = ResolveApplyChanceLabel(Effect);

        Info.Label = Label;
        Info.Chance = float(Effect.ApplyChance) * float(HitChance) / 100.0f;

        Idx = class'_EffectLib'.static.FindEffectInfoByLabel(Infos, Label);

		if (Idx == INDEX_NONE)
		{
			// No existing effects with the same name - add it.
			Infos.AddItem(Info);
		}
		else
		{
			// In case there are multiple effects with the same name (e.g. for LWFlamethrower) - take the bigger value of the two
			Infos[Idx].Chance = Max(Infos[Idx].Chance, Info.Chance);
			`DEBUG("Merged duplicate label:" @ Label @ "NewChance:" @ Infos[Idx].Chance);
		}

        `DEBUG("Effect:" @ Label @ "RawApply:" @ Effect.ApplyChance @ "Final:" @ Info.Chance);
    }

    if (Infos.Length == 0)
        return "";

    // === Rounding (independent) ===
    class'_EffectLib'.static.ApplyIndependentRounding(Infos);

    // === FORMAT ===
    Result = class'_EffectLib'.static.FormatEffectInfos(Infos);

	// === MISS ===
    if (GetSHOW_APPLY_CHANCE_MISS() && MissChance > 0)
    {
        MissLabel = class'X2TacticalGameRulesetDataStructures'.default.m_aAbilityHitResultStrings[eHit_Miss];

        Result $= " | " $
            class'UIUtilities_Text'.static.GetColoredText(
                MissLabel $ ": " $ MissChance $ "%",
                eUIState_Bad
            );
    }

    `TRACE_EXIT("Return:" @ Result);
    return Result;
}

static function string ResolveApplyChanceLabel(X2Effect Effect)
{
    local X2Effect_TriggerEvent TriggerEffect;
	local X2Effect_SetUnitValue SetUnitValueEffect;

	`TRACE_ENTRY("Effect.Class.Name:" @ Effect.Class.Name);

    // If it's X2Effect_TriggerEvent -> Get it's TriggerEventName
    TriggerEffect = X2Effect_TriggerEvent(Effect);
    if (TriggerEffect != none && TriggerEffect.TriggerEventName != '')
    {
		`DEBUG("TriggerEffect.TriggerEventName found:" @ TriggerEffect.TriggerEventName);
		return class'_EffectLib'.static.ResolveEffectLabel(Effect, TriggerEffect.TriggerEventName);
    }

	// If it's X2Effect_SetUnitValue -> Get it's UnitName
    SetUnitValueEffect = X2Effect_SetUnitValue(Effect);
    if (SetUnitValueEffect != none && SetUnitValueEffect.UnitName != '')
    {
		`DEBUG("SetUnitValueEffect.UnitName found:" @ SetUnitValueEffect.UnitName);
		return class'_EffectLib'.static.ResolveEffectLabel(Effect,, SetUnitValueEffect.UnitName);
    }

	`DEBUG("SetUnitValueEffect.UnitName or SetUnitValueEffect.UnitName isn't found.");
    return class'_EffectLib'.static.ResolveEffectLabel(Effect);
}

static function bool IsEffectBlacklisted(X2Effect Effect)
{
    local string FullKey;

	`TRACE_ENTRY("");
	if (Effect == none) return false;

    FullKey = string(Effect.Class.Outer.Name) $ "." $ string(Effect.Class.Name);

    `TRACE("Checking blacklist for:" @ FullKey);

    if (default.EffectChancePreviewBlacklist.Find(FullKey) != INDEX_NONE)
    {
        `DEBUG("Effect is BLACKLISTED:" @ FullKey);
        return true;
    }

	`TRACE_EXIT("Effect is not blacklisted:" @ FullKey);
    return false;
}

`MCM_CH_StaticVersionChecker(class'MCM_Defaults'.default.VERSION, class'ExtendedInformationRedux3_MCMScreen'.default.CONFIG_VERSION)

static function bool GetSHOW_APPLY_CHANCE_MISS()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOW_APPLY_CHANCE_MISS, class'ExtendedInformationRedux3_MCMScreen'.default.SHOW_APPLY_CHANCE_MISS);
}

static function bool GetSHOW_APPLY_CHANCE_GUARANTEED()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOW_APPLY_CHANCE_GUARANTEED, class'ExtendedInformationRedux3_MCMScreen'.default.SHOW_APPLY_CHANCE_GUARANTEED);
}

