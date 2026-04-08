"""RFC 3492 dogfood fixture in Python."""


def bootstring_parameters():
    """RFC 3492 section 5 parameter values for Punycode.

    base = 36, tmin = 1, tmax = 26, skew = 38, damp = 700,
    initial_bias = 72, initial_n = 0x80, delimiter = 0x2D.
    """
    base = 36
    tmin = 1
    tmax = 26
    skew = 38
    damp = 700
    initial_bias = 72
    initial_n = 128
    delimiter = 45


def overflow_handling():
    """RFC 3492 section 6.4 overflow handling constants.

    max_int = 2147483647, ace_max_length = 256, unicode_max_length = 256.
    """
    max_int = 2147483647
    ace_max_length = 256
    unicode_max_length = 256


def decode_digit():
    """RFC 3492 appendix C decode_digit helper."""
    cp = 48
    digit = 26


def encode_digit():
    """RFC 3492 appendix C encode_digit helper."""
    digit = 0
    uppercase = 0


def adapt():
    """RFC 3492 section 6.1 bias adaptation function."""
    delta = 700
    num_points = 5
    first_time = 1


def sample_strings():
    """RFC 3492 section 7 sample strings."""
    arabic = "egbpdaj6bu4bxfgehfvwxn"
    chinese = "ihqwcrb4cv8a8dqg056pqjye"
    spanish = "PorqunopuedensimplementehablarenEspaol-fmd56a"
