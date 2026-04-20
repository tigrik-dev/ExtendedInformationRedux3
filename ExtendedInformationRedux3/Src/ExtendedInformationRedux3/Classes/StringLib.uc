class StringLib extends Object;

static function bool IsUpper(string C)
{
    return C >= "A" && C <= "Z";
}

static function bool IsLower(string C)
{
    return C >= "a" && C <= "z";
}