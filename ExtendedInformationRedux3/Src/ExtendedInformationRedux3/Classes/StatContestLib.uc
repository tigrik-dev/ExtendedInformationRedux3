class StatContestLib extends Object config(ExtendedInformationRedux3_EffectLib);

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

struct StatContestEffectInfo
{
    var string Label;
    var float Chance;
};

struct RelevantEffectOverride
{
    var string PackageName;   // e.g. "ExtendedInformationRedux3"
    var string ClassName;     // e.g. "X2Effect_MyPoison"
    var name AbilityName;     // optional; if empty ? wildcard
};

var config array<RelevantEffectOverride> RelevantEffects;

/**
 * Returns formatted stat contest effect chances string for abilities like Insanity
 *
 * @param AbilityState   Ability being used
 * @param TargetRef      Target unit reference
 *
 * @return string        Colored formatted chances string (or empty if not applicable)
 */
static function string GetStatContestEffectChancesString(
    XComGameState_Ability AbilityState,
    StateObjectReference TargetRef
)
{
    local X2AbilityTemplate Template;
    local array<X2Effect> Effects;
    local X2AbilityToHitCalc_StatCheck StatCalc;

    local int AttackVal, DefendVal, MaxTier, Idx;
    local int MiddleTier;

    local array<float> TierValues;
    local float TierValue, LowTierValue, HighTierValue, TierValueSum;

    local array<StatContestEffectInfo> EffectInfos;
	local string Result;

    `TRACE_ENTRY("Ability:" @ AbilityState.GetMyTemplateName());

    if (AbilityState == none || TargetRef.ObjectID == 0)
        return "";

    Template = AbilityState.GetMyTemplate();
    if (Template == none)
        return "";

    Effects = Template.AbilityTargetEffects;

    // Detect if this ability even uses stat contest tiers
    MaxTier = GetHighestTierPossibleFromEffects(Effects);
    if (MaxTier <= 0)
        return "";

    StatCalc = X2AbilityToHitCalc_StatCheck(Template.AbilityToHitCalc);
    if (StatCalc == none)
        return "";

    AttackVal = StatCalc.GetAttackValue(AbilityState, TargetRef);
    DefendVal = StatCalc.GetDefendValue(AbilityState, TargetRef);

    `DEBUG("AttackVal:" @ AttackVal);
    `DEBUG("DefendVal:" @ DefendVal);
    `DEBUG("MaxTier:" @ MaxTier);

    // === Tier distribution ===
    MiddleTier = MaxTier / 2 + MaxTier % 2;

    TierValue = 100.0f / float(MaxTier);
    LowTierValue = TierValue * (float(DefendVal) / float(AttackVal));
    HighTierValue = TierValue * (float(AttackVal) / float(DefendVal));

    for (Idx = 1; Idx <= MaxTier; ++Idx)
    {
        if (Idx < MiddleTier)
            TierValues.AddItem(LowTierValue);
        else if (Idx == MiddleTier)
            TierValues.AddItem(TierValue);
        else
            TierValues.AddItem(HighTierValue);

        TierValueSum += TierValues[TierValues.Length - 1];

        `DEBUG("Raw Tier[" $ Idx $ "]:" @ TierValues[TierValues.Length - 1]);
    }

    // Normalize
    for (Idx = 0; Idx < TierValues.Length; ++Idx)
    {
        TierValues[Idx] /= TierValueSum;
        `DEBUG("Normalized Tier[" $ (Idx+1) $ "]:" @ TierValues[Idx]);
    }

    // === Build effect groups ===
    BuildEffectInfos(Effects, MaxTier, TierValues, AbilityState, EffectInfos);

	// === Format ===
	Result = FormatEffectInfos(EffectInfos);

	`TRACE_EXIT("Ability:" @ AbilityState.GetMyTemplateName() $ ", Return:" @ Result);
    return Result;
}

static function BuildEffectInfos(
    array<X2Effect> Effects,
    int MaxTier,
    array<float> TierValues,
    XComGameState_Ability AbilityState,
    out array<StatContestEffectInfo> OutInfos
)
{
    local int ExistingIdx, Tier;
    local X2Effect Effect;
    local StatContestEffectInfo Info;
    local X2Effect_Persistent PersistentEffect;
    local bool bFound;
    local string Label;

    `TRACE_ENTRY("Ability:" @ AbilityState.GetMyTemplateName());

    foreach Effects(Effect)
    {
        // 1. Relevance filter (now includes config overrides)
        if (!IsRelevant(Effect, AbilityState.GetMyTemplateName()))
            continue;

        // 2. Must participate in stat contest
        if (Effect.MinStatContestResult == 0 && Effect.MaxStatContestResult == 0)
            continue;

        // 3. Resolve label
        PersistentEffect = X2Effect_Persistent(Effect);

        if (PersistentEffect != none && PersistentEffect.FriendlyName != "")
        {
            Label = PersistentEffect.FriendlyName;
            `DEBUG("Using FriendlyName for" @ string(Effect.Class.Name) @ ":" @ Label);
        }
        else
        {
            Label = class'EffectLib'.static.GetFallbackEffectLabel(Effect);
            `DEBUG("Using fallback label for" @ string(Effect.Class.Name) @ ":" @ Label);
        }

        Info.Label = Label;
        Info.Chance = 0;

        // 4. Compute probability
        for (Tier = 1; Tier <= MaxTier; ++Tier)
        {
            if ((Effect.MinStatContestResult == 0 || Tier >= Effect.MinStatContestResult) &&
                (Effect.MaxStatContestResult == 0 || Tier <= Effect.MaxStatContestResult))
            {
                Info.Chance += TierValues[Tier - 1];
            }
        }

        Info.Chance *= 100.0f;

        `DEBUG("ADDING Effect:" @ Info.Label @ "RawChance:" @ Info.Chance);

        // 5. Merge duplicate labels (e.g. multiple Disorients)
        bFound = false;

        for (ExistingIdx = 0; ExistingIdx < OutInfos.Length; ++ExistingIdx)
        {
            if (OutInfos[ExistingIdx].Label == Info.Label)
            {
                OutInfos[ExistingIdx].Chance += Info.Chance;
                bFound = true;

                `DEBUG("MERGED Effect:" @ Info.Label @ "NewTotal:" @ OutInfos[ExistingIdx].Chance);
                break;
            }
        }

        if (!bFound)
        {
            OutInfos.AddItem(Info);
            `DEBUG("ADDED NEW Effect:" @ Info.Label @ "Chance:" @ Info.Chance);
        }
    }

    // 6. Final summary debug
    for (ExistingIdx = 0; ExistingIdx < OutInfos.Length; ++ExistingIdx)
    {
        `DEBUG("FINAL Effect:" @ OutInfos[ExistingIdx].Label @ "TotalChance:" @ OutInfos[ExistingIdx].Chance);
    }

    `TRACE_EXIT("");
}

static function bool IsRelevant(X2Effect Effect, optional name AbilityName)
{
    local X2Effect_Persistent PersistentEffect;
    local RelevantEffectOverride Override;
    local string EffectPackage, EffectClass;

	`TRACE_ENTRY("EffectPackage:" @ Effect.Class.Outer.Name $ ", EffectClass:" @ Effect.Class.Name $ ", AbilityName:" @ AbilityName);

    EffectPackage = string(Effect.Class.Outer.Name);
    EffectClass   = string(Effect.Class.Name);

    // === 1. Config overrides ===
    foreach default.RelevantEffects(Override)
    {
		`TRACE("Override.PackageName:" @ Override.PackageName $ ", Override.ClassName:" @ Override.ClassName $ ", Override.AbilityName:" @ Override.AbilityName);
        if (Override.PackageName == EffectPackage &&
            Override.ClassName == EffectClass)
        {
            // AbilityName match OR wildcard (empty)
            if (Override.AbilityName == '' || Override.AbilityName == AbilityName)
            {
                `DEBUG("IsRelevant: OVERRIDE matched for" @ EffectClass @ "Ability:" @ AbilityName);
                return true;
            }
        }
    }

    // === 2. Default logic ===
    PersistentEffect = X2Effect_Persistent(Effect);
    if (PersistentEffect == none)
        return false;

    // TRUE only for subclasses, FALSE for base class itself
    return PersistentEffect.Class != class'X2Effect_Persistent';
}

static function EUIState GetColorForIndex(int Index, int Total)
{
    local int GoodCount, WarningCount;

    if (Total == 1)
        return eUIState_Good;

    if (Total == 2)
        return (Index == 0) ? eUIState_Good : eUIState_Psyonic;

    // Distribute
    GoodCount = (Total + 2) / 3;
    WarningCount = (Total + 1) / 3;

    if (Index < GoodCount)
        return eUIState_Good;

    if (Index < GoodCount + WarningCount)
        return eUIState_Warning;

    return eUIState_Psyonic;
}

static function string FormatEffectInfos(array<StatContestEffectInfo> Infos)
{
    local int Idx;
    local string Result;
    local int RoundedChance;

    for (Idx = 0; Idx < Infos.Length; ++Idx)
    {
        if (Idx > 0)
            Result $= " | ";

        // Proper rounding instead of truncation
        RoundedChance = int(Infos[Idx].Chance + 0.5f);

        Result $= class'UIUtilities_Text'.static.GetColoredText(
            Infos[Idx].Label $ ": " $ RoundedChance $ "%",
            GetColorForIndex(Idx, Infos.Length)
        );
    }

    return Result;
}

static function int GetHighestTierPossibleFromEffects(array<X2Effect> Effects)
{
    local int Highest, Idx;

    Highest = -1;

    for (Idx = 0; Idx < Effects.Length; ++Idx)
    {
        if (Effects[Idx].MinStatContestResult > 0 && Effects[Idx].MinStatContestResult > Highest)
            Highest = Effects[Idx].MinStatContestResult;

        if (Effects[Idx].MaxStatContestResult > 0 && Effects[Idx].MaxStatContestResult > Highest)
            Highest = Effects[Idx].MaxStatContestResult;
    }

    return Highest;
}