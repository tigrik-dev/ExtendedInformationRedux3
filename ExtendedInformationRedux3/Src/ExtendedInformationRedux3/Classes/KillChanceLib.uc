class KillChanceLib extends Object;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

static function int GetKillChance(ShotBreakdown kBreakdown, DamageBreakdown NormalDamage, DamageBreakdown CritDamage, AvailableTarget kTarget)
{
	local int Result;
	local float KillChance;

	`TRACE_ENTRY("");

	KillChance = GetKillChanceFloat(kBreakdown, NormalDamage, CritDamage, kTarget);
	Result = class'PercentageLib'.static.RoundPercentage(KillChance * 100);

	`TRACE_EXIT("Return:" @ Result);
	return Result;
}

static function float GetKillChanceFloat(ShotBreakdown kBreakdown, DamageBreakdown NormalDamage, DamageBreakdown CritDamage, AvailableTarget kTarget)
{
	local float Result, pCrit, pHit, pGraze, TargetHP, HitKillChance, CritKillChance, GrazeKillChance;
	local int CritChance, HitChance, GrazeChance, MissChance;
	local XComGameStateHistory History;
	local XComGameState_Unit TargetUnit;

	`TRACE_ENTRY("");

	History = `XCOMHISTORY;
    TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(kTarget.PrimaryTarget.ObjectID));

    if (TargetUnit == none)
    {
		`ERROR("TargetUnit == none");
        `TRACE_EXIT("Return: 0.0");
        return 0.0;
    }

	TargetHP		= TargetUnit.GetCurrentStat(eStat_HP);
	CritChance		= kBreakdown.ResultTable[eHit_Crit];
    HitChance		= kBreakdown.ResultTable[eHit_Success];
    GrazeChance		= kBreakdown.ResultTable[eHit_Graze];
    MissChance		= kBreakdown.ResultTable[eHit_Miss];

    pCrit			= float(CritChance)  / 100.0;
    pHit			= float(HitChance)   / 100.0;
    pGraze			= float(GrazeChance) / 100.0;

	HitKillChance	= GetDamageKillProbability(NormalDamage.Min, NormalDamage.Max, TargetHP);
	CritKillChance	= GetDamageKillProbability(NormalDamage.Min + CritDamage.Min, NormalDamage.Max + CritDamage.Max, TargetHP);
	GrazeKillChance = GetGrazeKillProbability(NormalDamage.Min, NormalDamage.Max, TargetHP);
	
	Result =
          pHit   * HitKillChance
        + pCrit  * CritKillChance
        + pGraze * GrazeKillChance;

    `DEBUG("======== Kill Chance ========");

    `DEBUG("TargetHP:" @ TargetHP);

    `DEBUG("NormalDamage.Min:" @ NormalDamage.Min);
    `DEBUG("NormalDamage.Max:" @ NormalDamage.Max);

    `DEBUG("CritDamage.Min:" @ CritDamage.Min);
    `DEBUG("CritDamage.Max:" @ CritDamage.Max);

    `DEBUG("HitChance:" @ HitChance);
    `DEBUG("CritChance:" @ CritChance);
    `DEBUG("GrazeChance:" @ GrazeChance);
    `DEBUG("MissChance:" @ MissChance);

    `DEBUG("pHit:" @ pHit);
    `DEBUG("pCrit:" @ pCrit);
    `DEBUG("pGraze:" @ pGraze);

    `DEBUG("HitKillChance:" @ HitKillChance);
    `DEBUG("CritKillChance:" @ CritKillChance);
    `DEBUG("GrazeKillChance:" @ GrazeKillChance);

    `DEBUG("KillChance = (pHit * HitKillChance) + (pCrit * CritKillChance) + (pGraze * GrazeKillChance)");

    `DEBUG("KillChance = (" $ pHit @ "*" @ HitKillChance $") + (" $ pCrit @ "*" @ CritKillChance $") + (" $ pGraze @ "*" @ GrazeKillChance $")");

    `DEBUG("KillChance RAW:" @ Result);
    `DEBUG("=============================");

    `TRACE_EXIT("Return:" @ Result);
    return Result;
}

/**
 * Calculates probability that a damage roll kills a target.
 *
 * @param MinDamage   Minimum damage roll
 * @param MaxDamage   Maximum damage roll
 * @param TargetHP    Current target HP
 *
 * @return float      Probability from 0.0 to 1.0
 */
static function float GetDamageKillProbability(int MinDamage, int MaxDamage, int TargetHP)
{
    local int Damage;
    local int KillRolls;
    local int TotalRolls;
    local float Result;

    `TRACE_ENTRY("MinDamage:" @ MinDamage $ ", MaxDamage:" @ MaxDamage $ ", TargetHP:" @ TargetHP);

    KillRolls = 0;
    TotalRolls = 0;

    for (Damage = MinDamage; Damage <= MaxDamage; Damage++)
    {
        if (Damage >= TargetHP) KillRolls++;

        TotalRolls++;
    }

    if (TotalRolls == 0)
    {
        `TRACE_EXIT("Return: 0.0 (TotalRolls == 0)");
        return 0.0;
    }

    Result = float(KillRolls) / float(TotalRolls);

    `DEBUG("DamageKillProbability = KillRolls / TotalRolls");
    `DEBUG("DamageKillProbability =" @ KillRolls @ "/" @ TotalRolls);
    `DEBUG("DamageKillProbability:" @ Result);

    `TRACE_EXIT("Return:" @ Result);
    return Result;
}

/**
 * Calculates probability that a graze damage roll kills a target.
 * Graze damage uses floor(damage * 0.5).
 *
 * @param MinDamage   Minimum base damage roll
 * @param MaxDamage   Maximum base damage roll
 * @param TargetHP    Current target HP
 *
 * @return float      Probability from 0.0 to 1.0
 */
static function float GetGrazeKillProbability(int MinDamage, int MaxDamage, int TargetHP)
{
    local int Damage;
    local int GrazeDamage;
    local int KillRolls;
    local int TotalRolls;
    local float Result;

    `TRACE_ENTRY("MinDamage:" @ MinDamage $ ", MaxDamage:" @ MaxDamage $ ", TargetHP:" @ TargetHP);

    KillRolls = 0;
    TotalRolls = 0;

    for (Damage = MinDamage; Damage <= MaxDamage; Damage++)
    {
        GrazeDamage = int(Damage * 0.5);

        if (GrazeDamage >= TargetHP) KillRolls++;

        TotalRolls++;
    }

    if (TotalRolls == 0)
    {
        `TRACE_EXIT("Return:0.0 (TotalRolls == 0)");
        return 0.0;
    }

    Result = float(KillRolls) / float(TotalRolls);

    `DEBUG("GrazeKillProbability = KillRolls / TotalRolls");
    `DEBUG("GrazeKillProbability =" @ KillRolls @ "/" @ TotalRolls);
    `DEBUG("GrazeKillProbability:" @ Result);

    `TRACE_EXIT("Return:" @ Result);
    return Result;
}