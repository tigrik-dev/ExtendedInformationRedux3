class StatContestLib extends Object dependson(_EffectLib) config(EffectChancePreview);

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

struct RelevantEffectOverride
{
    var string PackageName;   // e.g. "ExtendedInformationRedux3"
    var string ClassName;     // e.g. "X2Effect_Dazed"
    var name AbilityName;     // optional; if empty ? wildcard
};

struct TierEffectBucket
{
    var array<string> Labels;
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

    local array<EffectInfo> EffectInfos;
    local string Result, MissLabel;
    local ShotBreakdown kBreakdown;
	local bool bMutuallyExclusive;
	local array<TierEffectBucket> TierEffectBuckets;

    `TRACE_ENTRY("");

    if (AbilityState == none || TargetRef.ObjectID == 0)
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
    BuildEffectInfos(Effects, MaxTier, TierValues, AbilityState, TargetRef, EffectInfos, TierEffectBuckets);

    // === SCALE by hit chance ===
    ScaleEffectInfosByHitChance(EffectInfos, HitChance);

    // === SMART ROUND ===
	bMutuallyExclusive = AreEffectInfosMutuallyExclusive(TierEffectBuckets);
	`DEBUG("MutuallyExclusive:" @ bMutuallyExclusive);
    ApplySmartRounding(EffectInfos, HitChance, bMutuallyExclusive);

    // === FORMAT ===
    Result = class'_EffectLib'.static.FormatEffectInfos(EffectInfos);

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
    out array<EffectInfo> Infos,
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
    out array<EffectInfo> Infos,
    int TargetTotal,
    bool bForceTotal
)
{
    local int i, CurrentSum, Needed, BestIdx;
    local float BestFraction;
    local array<int> Rounded;
    local array<float> Fractions;
    local array<bool> ForcedToOne;

    `TRACE_ENTRY("");

	if (!bForceTotal)
	{
		// Independent probabilities - just round normally, no normalization
		class'_EffectLib'.static.ApplyIndependentRounding(Infos);
		return;
	}

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
        Infos[i].RoundedChance = Max(0, Rounded[i]);

        `DEBUG("FINAL:" @ Infos[i].Label @ Infos[i].RoundedChance);
    }

    `TRACE_EXIT("");
}

static function BuildEffectInfos(
    array<X2Effect> Effects,
    int MaxTier,
    array<float> TierValues,
    XComGameState_Ability AbilityState,
	StateObjectReference TargetRef,
    out array<EffectInfo> OutInfos,
	out array<TierEffectBucket> OutTierBuckets
)
{
    local int Tier, i, Idx, CurrentEffectOrder;
    local X2Effect Effect;
    local XComGameState_Unit TargetUnit, SourceUnit;
    local string Label;

    local array<string> Labels;
    local array<float> Chances;
	local array<int> FirstSeenOrder;

    `TRACE_ENTRY("SIMULATED MODE Ability:" @ AbilityState.GetMyTemplateName());

    // === Resolve units ===
    TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetRef.ObjectID));
    SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));

    if (TargetUnit == none)
    {
        `DEBUG("No target unit - aborting");
        return;
    }

	// Initialize buckets
    OutTierBuckets.Length = MaxTier;
    for (Tier = 0; Tier < MaxTier; Tier++)
    {
        OutTierBuckets[Tier].Labels.Length = 0;
    }

    // === Iterate tiers ===
    for (Tier = 1; Tier <= MaxTier; ++Tier)
    {
        `DEBUG("=== Tier" @ Tier @ "Weight:" @ TierValues[Tier - 1]);

        for (i = 0; i < Effects.Length; i++)
		{
			Effect = Effects[i];
			CurrentEffectOrder = i;

            // 1. relevance
            if (!IsRelevant(Effect, AbilityState.GetMyTemplateName()))
                continue;

            // 2. stat contest window
            if ((Effect.MinStatContestResult != 0 && Tier < Effect.MinStatContestResult) ||
                (Effect.MaxStatContestResult != 0 && Tier > Effect.MaxStatContestResult))
                continue;

            // 3. simulate conditions
            if (!class'_EffectLib'.static.DoesEffectPassConditionsStrict(Effect, AbilityState, TargetUnit, SourceUnit, (TargetRef.ObjectID != 0)))
            {
                `DEBUG("Effect failed conditions:" @ string(Effect.Class.Name));
                continue;
            }

            // 4. resolve label
            Label = class'_EffectLib'.static.ResolveEffectLabel(Effect);

			OutTierBuckets[Tier - 1].Labels.AddItem(Label);

            // 5. accumulate probability
            Idx = Labels.Find(Label);

            if (Idx == INDEX_NONE)
            {
                Labels.AddItem(Label);
                Chances.AddItem(TierValues[Tier - 1] * 100.0f);
				FirstSeenOrder.AddItem(CurrentEffectOrder);

                `DEBUG("ADD:" @ Label @ Chances[Chances.Length - 1]);
            }
            else
            {
                Chances[Idx] += TierValues[Tier - 1] * 100.0f;

				// Preserve earliest occurrence
				if (CurrentEffectOrder < FirstSeenOrder[Idx])
				{
					FirstSeenOrder[Idx] = CurrentEffectOrder;
				}

                `DEBUG("ACCUM:" @ Label @ Chances[Idx]);
            }
        }
    }

	SortByFirstSeen(Labels, Chances, FirstSeenOrder);

    // === Convert to OutInfos ===
    for (i = 0; i < Labels.Length; i++)
    {
        OutInfos.AddItem(class'_EffectLib'.static.MakeEffectInfo(Labels[i], Chances[i]));
        `DEBUG("FINAL:" @ Labels[i] @ Chances[i]);
    }

    `TRACE_EXIT("");
}

static function bool AreEffectInfosMutuallyExclusive(
    array<TierEffectBucket> Buckets
)
{
    local int Tier;

    `TRACE_ENTRY("");

    for (Tier = 0; Tier < Buckets.Length; Tier++)
    {
        if (Buckets[Tier].Labels.Length > 1)
        {
            `DEBUG("Overlap detected in tier" @ (Tier + 1));
            return false;
        }
    }

    `TRACE_EXIT("Mutually exclusive");
    return true;
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

static function SortByFirstSeen(
    out array<string> Labels,
    out array<float> Chances,
    out array<int> Orders
)
{
    local int i, j;
    local string TempLabel;
    local float TempChance;
    local int TempOrder;

    for (i = 0; i < Orders.Length; i++)
    {
        for (j = i + 1; j < Orders.Length; j++)
        {
            if (Orders[j] < Orders[i])
            {
                TempOrder = Orders[i];
                Orders[i] = Orders[j];
                Orders[j] = TempOrder;

                TempLabel = Labels[i];
                Labels[i] = Labels[j];
                Labels[j] = TempLabel;

                TempChance = Chances[i];
                Chances[i] = Chances[j];
                Chances[j] = TempChance;
            }
        }
    }
}