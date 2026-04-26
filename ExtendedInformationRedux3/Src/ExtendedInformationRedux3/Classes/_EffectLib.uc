/**
 * _EffectLib
 *
 * Core utility class responsible for:
 * - Resolving effect labels (localized, fallback, and hardcoded)
 * - Evaluating effect conditions (including strict ability-based checks)
 * - Formatting effect chances for UI display
 * - Applying rounding rules to probabilities
 *
 * This class is used by multiple preview systems (e.g. ApplyChance, StatContest)
 * and acts as a shared foundation for effect-related logic.
 *
 * Responsibilities:
 * - Convert X2Effect objects into readable UI labels
 * - Handle localization fallback and formatting
 * - Evaluate TargetConditions safely across different contexts
 * - Apply consistent rounding rules (including edge-case corrections)
 * - Provide helper utilities for formatting and lookup
 *
 * @author Tigrik
 */
class _EffectLib extends Object;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

var localized string sUnknownEffect;
var localized string sFuseTriggered;

/**
 * Struct representing a single effect entry with probability data
 *
 * @field Label           Display name of the effect
 * @field Chance          Raw calculated probability (float)
 * @field RoundedChance   Final rounded probability (integer)
 */
struct EffectInfo
{
    var string Label;
    var float Chance;
    var int RoundedChance;
};

/**
 * Resolves a fallback label for an effect when no explicit name is available.
 *
 * Resolution order:
 * 1. Hardcoded overrides (special cases)
 * 2. Fully-qualified localization key
 * 3. Class-only localization key
 * 4. Derived class name (with prefix stripping and formatting)
 *
 * Also performs validation and formatting (PascalCase ? spaced words).
 *
 * @param Effect       Effect object
 * @param EffectName   Optional explicit effect/event name
 * @param UnitName     Optional unit-based override identifier
 *
 * @return string      Resolved human-readable label
 */
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

/**
 * Returns hardcoded label overrides for special cases.
 *
 * Used for effects that:
 * - Depend on triggered events (e.g. Void Rift, Fuse)
 * - Require mapping to ability names
 * - Have inconsistent or missing localization
 *
 * @param Effect       Effect object
 * @param EffectName   Optional event/effect name
 * @param UnitName     Optional unit-based identifier
 *
 * @return string      Override label or empty string if not applicable
 */
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

/**
 * Checks if a localization lookup failed.
 *
 * Unreal returns "?INT?..." when localization key is missing.
 *
 * @param Value    Localization result string
 *
 * @return bool    True if localization is missing
 */
static function bool IsMissingLocalization(string Value)
{
    // Unreal returns "?INT?Package.Section.Key?" when missing
    return Left(Value, 5) == "?INT?";
}

/**
 * Determines UI color for an effect based on its index and total count.
 *
 * Colors are distributed to provide visual clarity:
 * - Good (green)
 * - Warning (yellow)
 * - Psionic (purple)
 *
 * @param Index    Position of effect in list
 * @param Total    Total number of effects
 *
 * @return EUIState    UI color state
 */
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

/**
 * Resolves the final display label for an effect.
 *
 * Uses:
 * - PersistentEffect.FriendlyName if available
 * - Otherwise falls back to GetFallbackEffectLabel()
 *
 * @param Effect       Effect object
 * @param EffectName   Optional effect/event name
 * @param UnitName     Optional unit identifier
 *
 * @return string      Final resolved label
 */
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

/**
 * Evaluates whether an effect passes all conditions.
 *
 * This is a strict version that:
 * - Always evaluates ability-based conditions (even without target)
 * - Properly handles X2Condition_AbilityProperty
 * - Safely skips target-dependent checks when no target exists
 *
 * @param Effect         Effect to evaluate
 * @param AbilityState   Ability being used
 * @param TargetUnit     Target unit (may be none)
 * @param SourceUnit     Source unit (may be none)
 * @param bHasTarget     Whether a valid target exists
 *
 * @return bool          True if all conditions pass
 */
static function bool DoesEffectPassConditionsStrict(
    X2Effect Effect,
    XComGameState_Ability AbilityState,
    XComGameState_Unit TargetUnit,
    XComGameState_Unit SourceUnit,
    bool bHasTarget
)
{
    local X2Condition Condition;
    local X2Condition_AbilityProperty AbilityCondition;
    local name RequiredAbility;
    local name Result;

	`TRACE_ENTRY("");

    foreach Effect.TargetConditions(Condition)
    {
        // === ALWAYS evaluate AbilityProperty (no target needed) ===
        AbilityCondition = X2Condition_AbilityProperty(Condition);
        if (AbilityCondition != none && SourceUnit != none && AbilityCondition.OwnerHasSoldierAbilities.Length > 0)
        {
            foreach AbilityCondition.OwnerHasSoldierAbilities(RequiredAbility)
            {
                if (!SourceUnit.HasSoldierAbility(RequiredAbility))
                {
                    `DEBUG("Condition failed: missing ability" @ RequiredAbility);
					`TRACE_EXIT("Return: false");
                    return false;
                }
				`DEBUG("Condition passed: ability found" @ RequiredAbility);
            }
        }

        // === Ability-level check (safe even without target in most cases) ===
        if (AbilityState != none)
        {
            Result = Condition.AbilityMeetsCondition(AbilityState, TargetUnit);
            if (Result != 'AA_Success')
                return false;
        }

        // === Target-dependent checks ONLY if we have a target ===
        if (bHasTarget)
        {
            if (TargetUnit != none)
            {
                Result = Condition.MeetsCondition(TargetUnit);
                if (Result != 'AA_Success')
                    return false;
            }

            if (SourceUnit != none)
            {
                Result = Condition.MeetsConditionWithSource(TargetUnit, SourceUnit);
                if (Result != 'AA_Success')
                    return false;
            }
        }
    }

	`TRACE_EXIT("Return: true");
    return true;
}

/**
 * Applies independent rounding to effect chances.
 *
 * Rules:
 * - Standard rounding (0.5 ? up)
 * - Any non-zero value < 1% ? forced to 1%
 * - Any value between 99% and 100% ? forced to 99%
 * - Final result clamped to [0, 100]
 *
 * Used for non-mutually-exclusive probabilities.
 *
 * @param Infos    Array of effect info entries (modified in-place)
 */
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

/**
 * Creates a new EffectInfo struct.
 *
 * @param Label    Effect display label
 * @param Chance   Raw probability value
 *
 * @return EffectInfo    Initialized struct
 */
static function EffectInfo MakeEffectInfo(string Label, float Chance)
{
    local EffectInfo Info;

    Info.Label = Label;
    Info.Chance = Chance;

    return Info;
}

/**
 * Formats effect infos into a UI string.
 *
 * Output format:
 * "Effect A: 50% | Effect B: 25% | Effect C: 10%"
 *
 * Applies color formatting based on position.
 *
 * @param Infos    Array of effect info entries
 *
 * @return string  Formatted UI string
 */
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

/**
 * Finds an effect entry by label.
 *
 * @param Infos    Array of effect info entries
 * @param Label    Label to search for
 *
 * @return int     Index of matching entry or INDEX_NONE
 */
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