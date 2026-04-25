class _EffectLib extends Object;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

var localized string sUnknownEffect;
var localized string sFuseTriggered;

struct EffectInfo
{
    var string Label;
    var float Chance;
    var int RoundedChance;
};

static function string GetFallbackEffectLabel(X2Effect Effect, optional name EffectName, optional name UnitName)
{
    local string Label, LocalizedLabel;
    local string FullKey, ClassKey;
    local string PackageName;
    local int i;
    local string Char, PrevChar, NextChar;
    local string Result;

    `TRACE_ENTRY("Effect.Class.Name:" @ string(Effect.Class.Name));

	// === 0. Hardcoded overrides ===
    Label = GetHardcodedEffectLabelOverride(Effect, EffectName, UnitName);
    if (Label != "")
    {
        `DEBUG("Using HARDCODED label:" @ Label);
        `TRACE_EXIT("Return (hardcoded):" @ Label);
        return Label;
    }

    // === Build keys ===
    ClassKey   = string(Effect.Class.Name);
    PackageName = string(Effect.Class.Outer.Name);
    FullKey    = PackageName $ "." $ ClassKey;

	`DEBUG("FullKey:" @ FullKey);

    // === 1. Try FULLY QUALIFIED localization ===
    LocalizedLabel = Localize("LocalizedEffectNames", FullKey, "ExtendedInformationRedux3");

    if (!IsMissingLocalization(LocalizedLabel))
    {
        `DEBUG("Using FULL localized label:" @ LocalizedLabel);
        `TRACE_EXIT("Return (localized full):" @ LocalizedLabel);
        return LocalizedLabel;
    }

    // === 2. Try CLASS-ONLY localization (fallback) ===
    LocalizedLabel = Localize("LocalizedEffectNames", ClassKey, "ExtendedInformationRedux3");

    if (!IsMissingLocalization(LocalizedLabel))
    {
        `DEBUG("Using CLASS localized label:" @ LocalizedLabel);
        `TRACE_EXIT("Return (localized class):" @ LocalizedLabel);
        return LocalizedLabel;
    }

    // === 3. Use EffectName if it exists, otherwise use classname and strip prefix ===
    Label = (EffectName != '') ? string(EffectName) : Repl(ClassKey, "X2Effect_", "");

    // === 4. Validate (letters only) ===
	// If an effect still has any non-letter characters after stripping "X2Effect_" - display a fallback "Unknown"
	// e.g. "JaysEffect_HunkerDownReduxDebug2" -> "Unknown"
    for (i = 0; i < Len(Label); i++)
    {
        Char = Mid(Label, i, 1);

        if (!class'StringLib'.static.IsUpper(Char) && !class'StringLib'.static.IsLower(Char))
        {
            `DEBUG("Invalid characters detected, returning fallback");
            `TRACE_EXIT("Return:" @ default.sUnknownEffect);
            return default.sUnknownEffect;
        }
    }

    // === 5. Insert spaces (PascalCase ? readable) ===
	// Add spaces in between words. e.g. "MindScorch" -> "Mind Scorch"
	// Don't add spaces where an acronym is detected. e.g. "LWMindScorch" -> "LW Mind Scorch"
    Result = "";

    for (i = 0; i < Len(Label); i++)
    {
        Char = Mid(Label, i, 1);

        if (i > 0)
        {
            PrevChar = Mid(Label, i - 1, 1);

            if (i < Len(Label) - 1)
                NextChar = Mid(Label, i + 1, 1);
            else
                NextChar = "";

            if (
                (class'StringLib'.static.IsLower(PrevChar) && class'StringLib'.static.IsUpper(Char)) ||
                (class'StringLib'.static.IsUpper(PrevChar) && class'StringLib'.static.IsUpper(Char) && NextChar != "" && class'StringLib'.static.IsLower(NextChar))
            )
            {
                Result $= " ";
            }
        }

        Result $= Char;
    }

    `TRACE_EXIT("Return:" @ Result);
    return Result;
}

static function string GetHardcodedEffectLabelOverride(X2Effect Effect, optional name EffectName, optional name UnitName)
{
    local name EffectClassName;
	local X2AbilityTemplateManager TemplateManager;
	local X2AbilityTemplate Template;

	`TRACE_ENTRY("Effect.Class.Name:" @ Effect.Class.Name $ ", EffectName:" @ EffectName $ ", UnitName:" @ UnitName);
    EffectClassName = Effect.Class.Name;

	if (EffectName != '')
	{
		TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
		switch (EffectName)
		{
			// VoidRiftInsanityTriggered
			case (class'X2Ability_PsiOperativeAbilitySet'.default.VoidRiftInsanityEventName):
				// Insanity
				if (TemplateManager != none)
				{
					Template = TemplateManager.FindAbilityTemplate('Insanity');
					return (Template != none) ? Template.LocFriendlyName : "";
				}
				break;
			// FuseTriggered
			case (class'X2Ability_PsiOperativeAbilitySet'.default.FuseEventName):
				// Detonation
				return default.sFuseTriggered;
		}
	}

	switch (UnitName)
	{
		case ('MZShockTherapyStunResult'):
			// Stunned
			return class'X2Effect_Stunned'.default.StunnedText;
	}

    switch (EffectClassName)
    {
        case 'X2Effect_Dazed':
			// Dazed
            return class'X2StatusEffects_XPack'.default.DazedFriendlyName;
		case 'X2Effect_Stunned':
		case 'X2Effect_ArcthrowerStunned':
			// Stunned
			return class'X2Effect_Stunned'.default.StunnedText;
    }

    return ""; // no override
}

static function bool IsMissingLocalization(string Value)
{
    // Unreal returns "?INT?Package.Section.Key?" when missing
    return Left(Value, 5) == "?INT?";
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

static function string ResolveEffectLabel(X2Effect Effect, optional name EffectName, optional name UnitName)
{
    local X2Effect_Persistent PersistentEffect;

	`TRACE_ENTRY("Effect.Class.Name:" @ Effect.Class.Name $ ", EffectName:" @ EffectName $ ", UnitName:" @ UnitName);

    PersistentEffect = X2Effect_Persistent(Effect);

    if (PersistentEffect != none && PersistentEffect.FriendlyName != "")
	{
		`DEBUG("PersistentEffect.FriendlyName is found:" @ PersistentEffect.FriendlyName);	
        return PersistentEffect.FriendlyName;
	}

	`DEBUG("PersistentEffect.FriendlyName is not found.");
    return GetFallbackEffectLabel(Effect, EffectName, UnitName);
}

static function bool DoesEffectPassConditionsStrict(
    X2Effect Effect,
    XComGameState_Ability AbilityState,
    XComGameState_Unit TargetUnit,
    XComGameState_Unit SourceUnit
)
{
    local X2Condition Condition;
    local name Result;

    foreach Effect.TargetConditions(Condition)
    {
        // 1. Ability-based check (important for AbilityProperty)
        if (AbilityState != none)
        {
            Result = Condition.AbilityMeetsCondition(AbilityState, TargetUnit);
            if (Result != 'AA_Success')
                return false;
        }

        // 2. Target-only check
        if (TargetUnit != none)
        {
            Result = Condition.MeetsCondition(TargetUnit);
            if (Result != 'AA_Success')
                return false;
        }

        // 3. Source-based check (CRITICAL for OwnerDoesNotHaveAbility)
        if (SourceUnit != none)
        {
            Result = Condition.MeetsConditionWithSource(TargetUnit, SourceUnit);
            if (Result != 'AA_Success')
                return false;
        }
    }

    return true;
}

static function ApplyIndependentRounding(out array<EffectInfo> Infos)
{
    local int i;
    local int Rounded;
    local float Chance;

    `TRACE_ENTRY("Independent rounding");

    for (i = 0; i < Infos.Length; i++)
    {
        Chance = Infos[i].Chance;

        // Standard rounding first
        Rounded = int(Chance + 0.5f);

        // === Force minimum 1% for any non-zero chance < 1% ===
        if (Chance > 0.0f && Chance < 1.0f)
        {
            Rounded = 1;
        }

        // === Force maximum 99% for any chance < 100 but > 99 ===
        else if (Chance > 99.0f && Chance < 100.0f)
        {
            Rounded = 99;
        }

        // Safety clamp (just in case)
        if (Rounded < 0)
            Rounded = 0;
        else if (Rounded > 100)
            Rounded = 100;

        Infos[i].RoundedChance = Rounded;

        `DEBUG("Independent:" @ Infos[i].Label @ Chance @ "->" @ Rounded);
    }

    `TRACE_EXIT("");
}

static function EffectInfo MakeEffectInfo(string Label, float Chance)
{
    local EffectInfo Info;

    Info.Label = Label;
    Info.Chance = Chance;

    return Info;
}

static function string FormatEffectInfos(array<EffectInfo> Infos)
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

static function int FindEffectInfoByLabel(
    array<EffectInfo> Infos,
    string Label
)
{
    local int i;

    for (i = 0; i < Infos.Length; i++)
    {
        if (Infos[i].Label == Label)
            return i;
    }

    return INDEX_NONE;
}