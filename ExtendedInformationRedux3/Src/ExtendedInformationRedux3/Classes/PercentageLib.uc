class PercentageLib extends Object;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

static function int RoundPercentage(float Percentage)
{
	local int Rounded;

	`TRACE_ENTRY("");

	// Standard rounding first
	Rounded = int(Percentage + 0.5f);

	// === Force minimum 1% for any non-zero Percentage < 1% ===
	if (Percentage > 0.0f && Percentage < 1.0f) Rounded = 1;

	// === Force maximum 99% for any Percentage < 100 but > 99 ===
	else if (Percentage > 99.0f && Percentage < 100.0f) Rounded = 99;

	`TRACE_EXIT("");

	// Safety clamp (just in case)
	return Clamp(Rounded, 0, 100);
}