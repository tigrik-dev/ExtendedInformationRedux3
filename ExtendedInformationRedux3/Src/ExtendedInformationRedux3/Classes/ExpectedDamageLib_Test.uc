/**
 * ExpectedDamageLib_Test
 *
 * Unit tests for the ExpectedDamageLib utility class.
 *
 * Responsibilities:
 * - Test expected damage calculations for various scenarios
 * - Test graze calculation correctness
 * - Verify behavior with and without critical hits
 * - Provide immediate feedback if any assertion fails
 * 
 * @author Tigrik
 */
class ExpectedDamageLib_Test extends Object;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)
`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_TestMacros.uci)

/**
 * Test case: Basic hit with 100% success.
 *
 * @return bool  True if all assertions pass, false otherwise
 */
static function bool Test_GetExpectedDamage_BasicHit()
{
    local ShotBreakdown kBreakdown;
    local float Result;
	local DamageBreakdown NormalDamage;
	local DamageBreakdown CritDamage;

	`BEGIN_TEST;

    kBreakdown.ResultTable[eHit_Success] = 100;

	NormalDamage.Min = 4;
	NormalDamage.Max = 6;
	CritDamage.Min = 0;
	CritDamage.Max = 0;

    Result = class'ExpectedDamageLib'.static.GetExpectedDamage(kBreakdown, NormalDamage, CritDamage);

	if (!class'EIR_TestAsserts'.static.AssertFloatNear(Result, 5.0, 0.01)) return false;

	`END_TEST;
}

/**
 * Test case: Hit with 50% chance of crit.
 *
 * @return bool  True if all assertions pass, false otherwise
 */
static function bool Test_GetExpectedDamage_WithCrit()
{
    local ShotBreakdown kBreakdown;
    local float Result;
	local DamageBreakdown NormalDamage;
	local DamageBreakdown CritDamage;

    `BEGIN_TEST;

    kBreakdown.ResultTable[eHit_Success] = 50;
    kBreakdown.ResultTable[eHit_Crit] = 50;

	NormalDamage.Min = 4;
	NormalDamage.Max = 6;
	CritDamage.Min = 1;
	CritDamage.Max = 3;

    Result = class'ExpectedDamageLib'.static.GetExpectedDamage(kBreakdown, NormalDamage, CritDamage);

    // AvgNormal = 5
    // AvgCrit = 7
    // Expected = 0.5*5 + 0.5*7 = 6
    if (!class'EIR_TestAsserts'.static.AssertFloatNear(Result, 6.0, 0.01)) return false;

	`END_TEST;
}

/**
 * Test case: Average graze damage calculation.
 *
 * @return bool  True if all assertions pass, false otherwise
 */
static function bool Test_GetAvgGraze_GrazeCalculation()
{
    local float Result;

    `BEGIN_TEST;

    Result = class'ExpectedDamageLib'.static.GetAvgGraze(3, 5);

    // [1,2,2] ? avg = 1.6667
    if (!class'EIR_TestAsserts'.static.AssertFloatNear(Result, 1.6667, 0.01)) return false;

	`END_TEST;
}