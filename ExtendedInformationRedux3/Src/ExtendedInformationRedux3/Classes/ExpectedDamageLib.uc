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
 */
class ExpectedDamageLib extends Object;

/**
 * Calculates Expected Damage (numeric value)
 *
 * @param kBreakdown      Shot breakdown containing result probabilities
 * @param MinDamage       Minimum weapon damage
 * @param MaxDamage       Maximum weapon damage
 * @param CritBonus       Additional crit damage (flat bonus)
 *
 * @return float          Expected damage value
 */
static function float GetExpectedDamage(
    ShotBreakdown kBreakdown,
    int MinDamage,
    int MaxDamage,
    int CritBonus
)
{
    local int ED_CritChance, ED_HitChance, ED_GrazeChance, ED_MissChance;
    local float pCrit, pHit, pGraze;
    local float AvgNormal, AvgCrit, AvgGraze;
    local float ExpectedDamage;

    ED_CritChance  = kBreakdown.ResultTable[eHit_Crit];
    ED_HitChance   = kBreakdown.ResultTable[eHit_Success];
    ED_GrazeChance = kBreakdown.ResultTable[eHit_Graze];
    ED_MissChance  = kBreakdown.ResultTable[eHit_Miss];

    pCrit  = float(ED_CritChance)  / 100.0;
    pHit   = float(ED_HitChance)   / 100.0;
    pGraze = float(ED_GrazeChance) / 100.0;

    AvgNormal = (MinDamage + MaxDamage) / 2.0;
    AvgCrit   = AvgNormal + CritBonus;
    AvgGraze  = GetAvgGraze(MinDamage, MaxDamage);

    ExpectedDamage =
          pHit  * AvgNormal
        + pCrit * AvgCrit
        + pGraze * AvgGraze;

    `log("===== Expected Damage Debug =====");
    `log("MinDamage: " $ MinDamage);
    `log("MaxDamage: " $ MaxDamage);
    `log("CritBonus: " $ CritBonus);

    `log("ED_HitChance: " $ ED_HitChance);
    `log("ED_CritChance: " $ ED_CritChance);
    `log("ED_GrazeChance: " $ ED_GrazeChance);
    `log("ED_MissChance: " $ ED_MissChance);

    `log("AvgNormal: " $ AvgNormal);
    `log("AvgCrit: " $ AvgCrit);
    `log("AvgGraze: " $ AvgGraze);

    `log("ExpectedDamage RAW =" @ ExpectedDamage);

    return ExpectedDamage;
}

/**
 * Returns formatted Expected Damage string, e.g. " (4.6)"
 *
 * @param kBreakdown      Shot breakdown containing result probabilities
 * @param MinDamage       Minimum weapon damage
 * @param MaxDamage       Maximum weapon damage
 * @param CritBonus       Additional crit damage (flat bonus)
 *
 * @return string         Formatted Expected Damage string
 */
static function string GetExpectedDamageString(
    ShotBreakdown kBreakdown,
    int MinDamage,
    int MaxDamage,
    int CritBonus
)
{
    local float ExpectedDamage;
    local string ExpectedDamageStr;

    ExpectedDamage = GetExpectedDamage(kBreakdown, MinDamage, MaxDamage, CritBonus);

    ExpectedDamageStr = " (" $ class'UIUtilities'.static.FormatFloat(ExpectedDamage, 1) $ ")";

    `log("ExpectedDamage formatted =" @ ExpectedDamageStr);
	`log("=================================");

    return ExpectedDamageStr;
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

    SumGraze = 0;
    Count = 0;

    for (dmg = MinDamage; dmg <= MaxDamage; dmg++)
    {
        SumGraze += int(dmg * 0.5); // floor
        Count++;
    }

    return SumGraze / Count;
}