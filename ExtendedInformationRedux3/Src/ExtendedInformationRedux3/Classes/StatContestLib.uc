class StatContestLib extends Object config(ExtendedInformationRedux3_EffectLib);

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

struct StatContestEffectInfo
{
    var string Label;
    var float Chance;
	var int RoundedChance;
};

struct RelevantEffectOverride
{
    var string PackageName;   // e.g. "ExtendedInformationRedux3"
    var string ClassName;     // e.g. "X2Effect_Dazed"
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
    StateObjectReference TargetRef,
    AvailableTarget kTarget
)
{
    local X2AbilityTemplate Template;
    local array<X2Effect> Effects;
    local X2AbilityToHitCalc_StatCheck StatCalc;

    local int AttackVal, DefendVal, MaxTier, Idx;
    local int MiddleTier, HitChance, MissChance;

    local array<float> TierValues;
    local float TierValue, LowTierValue, HighTierValue, TierValueSum;

    local array<StatContestEffectInfo> EffectInfos;
    local string Result, MissLabel;
    local ShotBreakdown kBreakdown;

    `TRACE_ENTRY("Ability:" @ AbilityState.GetMyTemplateName());

    if (AbilityState == none || TargetRef.ObjectID == 0)
        return "";

    Template = AbilityState.GetMyTemplate();
    if (Template == none)
        return "";

    Effects = Template.AbilityTargetEffects;

    MaxTier = GetHighestTierPossibleFromEffects(Effects);
    if (MaxTier <= 0)
        return "";

    StatCalc = X2AbilityToHitCalc_StatCheck(Template.AbilityToHitCalc);
    if (StatCalc == none)
        return "";

    // === HIT / MISS ===
    AbilityState.GetShotBreakdown(kTarget, kBreakdown);

    HitChance = Clamp(
        (kBreakdown.bIsMultishot ? kBreakdown.MultiShotHitChance : kBreakdown.FinalHitChance),
        0, 100
    );

    MissChance = 100 - HitChance;

    `DEBUG("HitChance:" @ HitChance);
    `DEBUG("MissChance:" @ MissChance);

    // === Attack / Defense ===
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

    // === Build effect chances (0–100 assuming HIT) ===
    BuildEffectInfos(Effects, MaxTier, TierValues, AbilityState, EffectInfos);

    // === SCALE by hit chance ===
    ScaleEffectInfosByHitChance(EffectInfos, HitChance);

    // === SMART ROUND ===
    ApplySmartRounding(EffectInfos, HitChance);

    // === FORMAT ===
    Result = FormatEffectInfos(EffectInfos);

    // === MISS ===
    if (MissChance > 0)
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

static function ScaleEffectInfosByHitChance(
    out array<StatContestEffectInfo> Infos,
    int HitChance
)
{
    local int i;

	`TRACE_ENTRY("");
    for (i = 0; i < Infos.Length; i++)
    {
        Infos[i].Chance = Infos[i].Chance * float(HitChance) / 100.0f;

        `DEBUG("Scaled:" @ Infos[i].Label @ Infos[i].Chance);
    }
	`TRACE_EXIT("");
}

static function ApplySmartRounding(
    out array<StatContestEffectInfo> Infos,
    int TargetTotal
)
{
    local int i, CurrentSum, Needed, BestIdx;
    local float BestFraction;
    local array<int> Rounded;
    local array<float> Fractions;
    local array<bool> ForcedToOne;

    `TRACE_ENTRY("");

    // === STEP 1: floor everything ===
    for (i = 0; i < Infos.Length; i++)
    {
        Rounded.AddItem(int(Infos[i].Chance));
        Fractions.AddItem(Infos[i].Chance - float(Rounded[i]));
        ForcedToOne.AddItem(false);

        `DEBUG("Initial:" @ Infos[i].Label @ "Raw:" @ Infos[i].Chance @ "Floor:" @ Rounded[i]);
    }

    // === STEP 2: enforce minimum 1% for non-zero values ===
    for (i = 0; i < Infos.Length; i++)
    {
        if (Infos[i].Chance > 0.0f && Rounded[i] == 0)
        {
            Rounded[i] = 1;
            ForcedToOne[i] = true;

            `DEBUG("Forced to 1%:" @ Infos[i].Label);
        }
    }

    // === STEP 3: compute sum ===
    CurrentSum = 0;
    for (i = 0; i < Rounded.Length; i++)
    {
        CurrentSum += Rounded[i];
    }

    Needed = TargetTotal - CurrentSum;

    `DEBUG("After min-pass Sum:" @ CurrentSum @ "Target:" @ TargetTotal @ "Needed:" @ Needed);

    // === STEP 4A: need to ADD points ? give to largest fractions ===
    while (Needed > 0)
    {
        BestIdx = -1;
        BestFraction = -1.0;

        for (i = 0; i < Infos.Length; i++)
        {
            if (Fractions[i] > BestFraction)
            {
                BestFraction = Fractions[i];
                BestIdx = i;
            }
        }

        if (BestIdx == -1)
            break;

        Rounded[BestIdx]++;
        Fractions[BestIdx] = 0;
        Needed--;

        `DEBUG("Rounding UP:" @ Infos[BestIdx].Label);
    }

    // === STEP 4B: need to REMOVE points ? take from smallest fractions ===
    while (Needed < 0)
    {
        BestIdx = -1;
        BestFraction = 999.0;

        for (i = 0; i < Infos.Length; i++)
        {
            // don't reduce forced 1% unless absolutely necessary
            if (Rounded[i] > 1 || !ForcedToOne[i])
            {
                if (Fractions[i] < BestFraction)
                {
                    BestFraction = Fractions[i];
                    BestIdx = i;
                }
            }
        }

        if (BestIdx == -1)
            break;

        Rounded[BestIdx]--;
        Needed++;

        `DEBUG("Rounding DOWN:" @ Infos[BestIdx].Label);
    }

    // === STEP 5: write back ===
    for (i = 0; i < Infos.Length; i++)
    {
        Infos[i].RoundedChance = Rounded[i];

        `DEBUG("FINAL:" @ Infos[i].Label @ Infos[i].RoundedChance);
    }

    `TRACE_EXIT("");
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
    local string Result;
    local int i;

    for (i = 0; i < Infos.Length; i++)
    {
        if (i > 0)
            Result $= " | ";

        Result $= class'UIUtilities_Text'.static.GetColoredText(
            Infos[i].Label $ ": " $ Infos[i].RoundedChance $ "%",
            GetColorForIndex(i, Infos.Length)
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