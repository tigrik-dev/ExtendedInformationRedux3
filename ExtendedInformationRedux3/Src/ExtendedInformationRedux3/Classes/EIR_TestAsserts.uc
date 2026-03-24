/**
 * EIR_TestAsserts
 *
 * Utility class providing assertion functions for unit testing.
 * All functions return a boolean indicating pass (true) or fail (false),
 * and call FailAssert() to log assertion failures with detailed messages.
 *
 * Responsibilities:
 * - Assert numeric values, boolean expressions, integer comparisons, and string equality
 * - Provide standardized failure messages
 * - Facilitate simple one-liner assertions in test functions
 * 
 * @author Tigrik
 */
class EIR_TestAsserts extends Object;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

/**
 * Logs an assertion failure message.
 *
 * @param Message   The failure message to log
 */
static function FailAssert(string Message)
{
    `ERROR("[ASSERT FAIL]" @ Message);
}

/**
 * Asserts that two float values are within a specified tolerance.
 *
 * @param actual    The actual float value
 * @param expected  The expected float value
 * @param tol       Tolerance allowed between actual and expected
 *
 * @return bool     True if within tolerance, false otherwise
 */
static function bool AssertFloatNear(float actual, float expected, float tol)
{
    if (Abs(actual - expected) > tol)
    {
        FailAssert("ASSERT_FLOAT_NEAR failed: actual=" $ actual @ "expected=" $ expected);
        return false;
    }

    return true;
}

/**
 * Asserts that a boolean expression is true.
 *
 * @param expr      Expression to check
 * @param msg       Optional message for failure reporting
 *
 * @return bool     True if expression is true, false otherwise
 */
static function bool AssertTrue(bool expr, string msg="")
{
    if (!expr)
    {
        if (Len(msg) > 0)
            FailAssert("ASSERT_TRUE failed: " $ msg);
        else
            FailAssert("ASSERT_TRUE failed");
        return false;
    }
    return true;
}

/**
 * Asserts that a boolean expression is false.
 *
 * @param expr      Expression to check
 * @param msg       Optional message for failure reporting
 *
 * @return bool     True if expression is false, false otherwise
 */
static function bool AssertFalse(bool expr, string msg="")
{
    if (expr)
    {
        if (Len(msg) > 0)
            FailAssert("ASSERT_FALSE failed: " $ msg);
        else
            FailAssert("ASSERT_FALSE failed");
        return false;
    }
    return true;
}

/**
 * Asserts that two integer values are equal.
 *
 * @param actual    The actual integer value
 * @param expected  The expected integer value
 * @param msg       Optional message for failure reporting
 *
 * @return bool     True if equal, false otherwise
 */
static function bool AssertEqInt(int actual, int expected, string msg="")
{
    if (actual != expected)
    {
        if (Len(msg) > 0)
            FailAssert("ASSERT_EQ_INT failed: " $ actual $ " != " $ expected $ " : " $ msg);
        else
            FailAssert("ASSERT_EQ_INT failed: " $ actual $ " != " $ expected);
        return false;
    }
    return true;
}

/**
 * Asserts that two integer values are not equal.
 *
 * @param actual    The actual integer value
 * @param expected  The value that should not equal actual
 * @param msg       Optional message for failure reporting
 *
 * @return bool     True if not equal, false otherwise
 */
static function bool AssertNeqInt(int actual, int expected, string msg="")
{
    if (actual == expected)
    {
        if (Len(msg) > 0)
            FailAssert("ASSERT_NEQ_INT failed: values equal : " $ msg);
        else
            FailAssert("ASSERT_NEQ_INT failed: values equal");
        return false;
    }
    return true;
}

/**
 * Asserts that two strings are equal.
 *
 * @param actual    The actual string
 * @param expected  The expected string
 * @param msg       Optional message for failure reporting
 *
 * @return bool     True if equal, false otherwise
 */
static function bool AssertStrEq(string actual, string expected, string msg="")
{
    if (actual != expected)
    {
        if (Len(msg) > 0)
            FailAssert("ASSERT_STR_EQ failed: actual='" $ actual $ "' expected='" $ expected $ "' : " $ msg);
        else
            FailAssert("ASSERT_STR_EQ failed: actual='" $ actual $ "' expected='" $ expected $ "'");
        return false;
    }
    return true;
}