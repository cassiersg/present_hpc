# Performance of PRESENT hardware implementations

We compare here the two HPC implementations with DOM [1] and Faust et al. [2]
schemes.

ASIC implementations are in a 65 nm commercial technology, and do not include
randomness generation.

The parameter d is the number of shares and SER is the serialization: number of
times each S-box implementation is used per round (the number of S-boxes in the
circuit is thus 32/SER).

## ASIC area [kGE], SER=1
| d  |      DOM |   Faust-et-al. |     HPC1 |     HPC2 |
|---:|---------:|---------------:|---------:|---------:|
|  2 |  38795.7 |        48425.2 |  44800.2 |  43387.5 |
|  3 |  62168.2 |        83201.6 |  74177   |  74062.2 |
|  4 |  88715.4 |       126101   | 109204   | 111358   |
|  5 | 117747   |       175672   | 147769   | 154375   |
|  6 | 150289   |       233676   | 192843   | 201790   |
|  7 | 185654   |       299292   | 242576   | 256158   |
|  8 | 224036   |       372588   | 297062   | 317234   |

## ASIC area [kGE], SER=8
| d  |      DOM |   Faust-et-al. |     HPC1 |     HPC2 |
|---:|---------:|---------------:|---------:|---------:|
|  2 |  42197.8 |        45294.8 |  43532.1 |  43186   |
|  3 |  63973.9 |        70045.6 |  66642.6 |  66594.6 |
|  4 |  86485.5 |        96665.3 |  91038.4 |  91483.6 |
|  5 | 109565   |       124776   | 116236   | 117663   |
|  6 | 133391   |       154765   | 142869   | 144819   |
|  7 | 157892   |       186433   | 170562   | 173521   |
|  8 | 183000   |       219797   | 199257   | 203697   |

## Total randomness (kilo-bits)
| d  |   Faust-et-al. |   HPC1 |   HPC2 |   DOM |
|---:|---------------:|-------:|-------:|------:|
|  2 |           4608 |   6912 |   2304 |  2304 |
|  3 |          13824 |  13824 |   6912 |  6912 |
|  4 |          27648 |  23040 |  13824 | 13824 |
|  5 |          46080 |  34560 |  23040 | 23040 |
|  6 |          69120 |  50688 |  34560 | 34560 |
|  7 |          96768 |  69120 |  48384 | 48384 |
|  8 |         129024 |  85248 |  64512 | 64512 |

## Total latency (clock cycles)
| SER |   Faust-et-al. |   HPC1 |   HPC2 |   DOM |
|---:|---------------:|-------:|-------:|------:|
|  1 |            288 |    128 |    128 |    96 |
|  2 |            320 |    160 |    160 |   128 |
|  4 |            384 |    224 |    224 |   192 |
|  8 |            512 |    352 |    352 |   320 |

[1] H. Groß, S. Mangard, and T. Korak, “Domain-oriented masking: Compact masked hardware implementations with arbitrary pro- tection order,” IACR Cryptology ePrint Archive, vol. 2016, p. 486, 2016.

[2] S. Faust, V. Grosso, S. M. D. Pozo, C. Paglialonga, and F. Standaert,
“Composable masking schemes in the presence of physical defaults & the robust probing model,” IACR Trans. Cryptogr. Hardw.  Embed. Syst., vol. 2018, no. 3, pp. 89–120, 2018.

