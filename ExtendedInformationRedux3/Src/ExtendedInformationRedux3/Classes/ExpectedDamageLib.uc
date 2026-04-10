/**
 * ExpectedDamageLib
 *
 * Utility class responsible for calculating Expected Damage values
 * based on XCOM 2 / LWOTC hit mechanics.
 *
 * Responsibilities:
 * - Compute Expected Damage using hit/crit/graze probabilities
 * - Correctly calculate graze damage using floor(dmg * 0.5)
 * - Provide formatted output string for UI display
 * 
 * @author Tigrik
 */
class ExpectedDamageLib extends Object;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

/**
 * Calculates Expected Damage (numeric value)
 *
 * @param kBreakdown      Shot breakdown containing result probabilities
 * @param NormalDamage    Breakdown containing minimum and maximum non-crit damage
 * @param CritDamage	  Breakdown containing minimum and maximum crit damage
 *
 * @return float          Expected damage value
 */
static function float GetExpectedDamage(
    ShotBreakdown kBreakdown,
    DamageBreakdown NormalDamage,
	DamageBreakdown CritDamage
)
{
    local int ED_CritChance, ED_HitChance, ED_GrazeChance, ED_MissChance;
    local float pCrit, pHit, pGraze;
    local float AvgNormal, AvgCrit, AvgGraze;
    local float ExpectedDamage;

	`TRACE_ENTRY("NormalDamage:" @ class'DamagePreviewLib'.static.DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ class'DamagePreviewLib'.static.DamageBreakdownToString(CritDamage));

    ED_CritChance  = kBreakdown.ResultTable[eHit_Crit];
    ED_HitChance   = kBreakdown.ResultTable[eHit_Success];
    ED_GrazeChance = kBreakdown.ResultTable[eHit_Graze];
    ED_MissChance  = kBreakdown.ResultTable[eHit_Miss];

    pCrit  = float(ED_CritChance)  / 100.0;
    pHit   = float(ED_HitChance)   / 100.0;
    pGraze = float(ED_GrazeChance) / 100.0;

    AvgNormal = (NormalDamage.Min + NormalDamage.Max) / 2.0;
    AvgCrit   = AvgNormal + ((CritDamage.Min + CritDamage.Max) / 2.0);
    AvgGraze  = GetAvgGraze(NormalDamage.Min, NormalDamage.Max);

    ExpectedDamage =
          pHit  * AvgNormal
        + pCrit * AvgCrit
        + pGraze * AvgGraze;

    `DEBUG("======== Expected Damage ========");
    `DEBUG("NormalDamage.Min:" @ NormalDamage.Min);
    `DEBUG("NormalDamage.Max:" @ NormalDamage.Max);
    `DEBUG("CritDamage.Min:" @ CritDamage.Min);
	`DEBUG("CritDamage.Max:" @ CritDamage.Max);

    `DEBUG("ED_HitChance:" @ ED_HitChance);
    `DEBUG("ED_CritChance:" @ ED_CritChance);
    `DEBUG("ED_GrazeChance:" @ ED_GrazeChance);
    `DEBUG("ED_MissChance:" @ ED_MissChance);

    `DEBUG("AvgNormal:" @ AvgNormal);
    `DEBUG("AvgCrit:" @ AvgCrit);
    `DEBUG("AvgGraze:" @ AvgGraze);

	`DEBUG("ExpectedDamage = (pHit * AvgNormal) + (pCrit * AvgCrit) + (pGraze * AvgGraze)");
	`DEBUG("ExpectedDamage = (" $ pHit @ "*" @ AvgNormal $ ") + (" $ pCrit @ "*" @ AvgCrit $ ") + (" $ pGraze @ "*" @ AvgGraze $ ")");
    `DEBUG("ExpectedDamage RAW:" @ ExpectedDamage);
	`DEBUG("=================================");

	`TRACE_EXIT("ExpectedDamage:" @ ExpectedDamage);
    return ExpectedDamage;
}

/**
 * Returns formatted Expected Damage string, e.g. "4.6"
 *
 * @param kBreakdown      Shot breakdown containing result probabilities
 * @param NormalDamage    Breakdown containing minimum and maximum non-crit damage
 * @param CritDamage	  Breakdown containing minimum and maximum crit damage
 *
 * @return string         Formatted Expected Damage string
 */
static function string GetExpectedDamageString(
    ShotBreakdown kBreakdown,
    DamageBreakdown NormalDamage,
	DamageBreakdown CritDamage
)
{
    local float ExpectedDamage;
	local string ExpectedDamageString;

	`TRACE_ENTRY("NormalDamage:" @ class'DamagePreviewLib'.static.DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ class'DamagePreviewLib'.static.DamageBreakdownToString(CritDamage));

    ExpectedDamage = GetExpectedDamage(kBreakdown, NormalDamage, CritDamage);

	ExpectedDamageString = FormatExpectedDamageString(ExpectedDamage);

	`TRACE_EXIT("ExpectedDamageString:" @ ExpectedDamageString);
    return ExpectedDamageString;
}

static function string FormatExpectedDamageString(float ExpectedDamage)
{
	return class'UIUtilities'.static.FormatFloat(ExpectedDamage, 1);
}

/**
 * Computes average graze damage using correct logic:
 * graze = floor(damage * 0.5)
 *
 * Example:
 * 3-5 ? [1,2,2] ? avg = 1.6667
 *
 * @param MinDamage   Minimum weapon damage
 * @param MaxDamage   Maximum weapon damage
 *
 * @return float      Average graze damage
 */
static function float GetAvgGraze(int MinDamage, int MaxDamage)
{
    local int dmg;
    local float SumGraze;
    local int Count;
	local float AvgGraze;

	`TRACE_ENTRY("MinDamage:" @ MinDamage $ ", MaxDamage:" @ MaxDamage);

    SumGraze = 0;
    Count = 0;

    for (dmg = MinDamage; dmg <= MaxDamage; dmg++)
    {
        SumGraze += int(dmg * 0.5); // floor
        Count++;
    }

	AvgGraze = SumGraze / Count;

	`TRACE_EXIT("AvgGraze:" @ AvgGraze);
    return AvgGraze;
}