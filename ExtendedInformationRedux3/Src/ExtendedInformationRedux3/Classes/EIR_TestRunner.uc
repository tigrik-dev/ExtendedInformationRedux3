/**
 * EIR_TestRunner
 *
 * Central test runner class responsible for executing all unit tests.
 *
 * Responsibilities:
 * - Run all test classes and test functions
 * - Log test start and pass messages
 * - Organize test execution for specific modules (e.g., ExpectedDamageLib tests)
 * 
 * @author Tigrik
 */
class EIR_TestRunner extends Object;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

/**
 * Runs all registered unit tests in the framework.
 */
static function RunAllTests()
{
    `TEST("===== RUNNING ALL TESTS =====");

    RunExpectedDamageTests();

    `TEST("=================================");
}

/**
 * Marks the start of a test.
 *
 * @param TestName  Name of the test function
 */
static function BeginTest(string TestName)
{
    `TEST("START:" @ TestName);
}

/**
 * Marks the successful completion of a test.
 *
 * @param TestName  Name of the test function
 */
static function EndTest(string TestName)
{
    `TEST("PASS:" @ TestName);
}

/**
 * Runs all unit tests for ExpectedDamageLib.
 */
static function RunExpectedDamageTests()
{
    class'ExpectedDamageLib_Test'.static.Test_GetExpectedDamage_BasicHit();
    class'ExpectedDamageLib_Test'.static.Test_GetExpectedDamage_WithCrit();
    class'ExpectedDamageLib_Test'.static.Test_GetAvgGraze_GrazeCalculation();
}