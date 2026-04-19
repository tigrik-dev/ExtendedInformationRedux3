class EffectLib extends Object;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

static function string GetFallbackEffectLabel(X2Effect Effect)
{
    local string Label, LocalizedLabel;
    local string FullKey, ClassKey;
    local string PackageName;
    local int i;
    local string Char, PrevChar, NextChar;
    local string Result;

    `TRACE_ENTRY("Effect.Class.Name:" @ string(Effect.Class.Name));

	// === 0. Hardcoded overrides ===
    Label = GetHardcodedEffectLabelOverride(Effect);
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

    // === 3. Strip prefix ===
    Label = Repl(ClassKey, "X2Effect_", "");

    // === 4. Validate (letters only) ===
	// If an effect still has any non-letter characters after stripping "X2Effect_" - display a fallback "Unknown"
	// e.g. "JaysEffect_HunkerDownReduxDebug2" -> "Unknown"
    for (i = 0; i < Len(Label); i++)
    {
        Char = Mid(Label, i, 1);

        if (!class'StringLib'.static.IsUpper(Char) && !class'StringLib'.static.IsLower(Char))
        {
            `DEBUG("Invalid characters detected, returning fallback");
            `TRACE_EXIT("Return: Unknown");
            return "Unknown";
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

static function string GetHardcodedEffectLabelOverride(X2Effect Effect)
{
    local name EffectName;

	`TRACE_ENTRY("Effect.Class.Name:" @ Effect.Class.Name);
    EffectName = Effect.Class.Name;

    switch (EffectName)
    {
        case 'X2Effect_Dazed':
            return class'X2StatusEffects_XPack'.default.DazedFriendlyName;
    }

    return ""; // no override
}

static function bool IsMissingLocalization(string Value)
{
    // Unreal returns "?INT?Package.Section.Key?" when missing
    return Left(Value, 5) == "?INT?";
}