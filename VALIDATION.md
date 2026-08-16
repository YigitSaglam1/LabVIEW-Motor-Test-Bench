\# Motor Test Bench Validation Matrix



| ID | Measurement Source | Fault Injection | Test | Expected Result | Status |

|---|---|---|---|---|---|

| T01 | SOFTWARE\_SIMULATOR | NONE | Full automated test sequence | COMPLETE / PASS | PASS |

| T02 | MODBUS\_TCP | NONE | Full automated test sequence | COMPLETE / PASS | PASS |

| T03 | SOFTWARE\_SIMULATOR | OVERCURRENT | Inject current above safety trip | FAULT / SYSTEM FAULT | PASS |

| T04 | SOFTWARE\_SIMULATOR | OVERTEMPERATURE | Inject temperature above safety trip | FAULT / SYSTEM FAULT | PASS |

| T05 | SOFTWARE\_SIMULATOR | HIGH\_VIBRATION | Inject vibration above safety trip | FAULT / SYSTEM FAULT | PASS |

| T06 | SOFTWARE\_SIMULATOR | RPM\_SENSOR\_FAILURE | Simulate failed RPM feedback | FAULT / SYSTEM FAULT | PASS |

| T07 | MODBUS\_TCP | NONE | Stop Modbus server during active test | FAULT / SYSTEM FAULT | PASS |

| T08 | SOFTWARE\_SIMULATOR | NONE | Reset and start second test | Each test state waits 5 s | PASS |

| T09 | MODBUS\_TCP | NONE | State transition settling test | RPM transient does not latch TEST FAILED | PASS |

