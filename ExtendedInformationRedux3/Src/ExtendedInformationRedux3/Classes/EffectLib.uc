class EffectLib extends Object;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

static function string GetFallbackEffectLabel(X2Effect Effect)
{
    local string Label;
    local int i;
    local string Char, PrevChar, NextChar;
    local string Result;

    // Strip prefix
    Label = string(Effect.Class.Name);
    Label = Repl(Label, "X2Effect_", "");

    // === NEW: validate only letters ===
    for (i = 0; i < Len(Label); i++)
    {
        Char = Mid(Label, i, 1);

        if (!IsUpper(Char) && !IsLower(Char))
        {
            return "Unknown";
        }
    }

    // === Existing formatting logic ===
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

            // Insert space rules
            if (
                (IsLower(PrevChar) && IsUpper(Char)) ||
                (IsUpper(PrevChar) && IsUpper(Char) && NextChar != "" && IsLower(NextChar))
            )
            {
                Result $= " ";
            }
        }

        Result $= Char;
    }

    return Result;
}

private static function bool IsUpper(string C)
{
    return C >= "A" && C <= "Z";
}

private static function bool IsLower(string C)
{
    return C >= "a" && C <= "z";
}