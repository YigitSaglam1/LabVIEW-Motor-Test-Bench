\# Automated Electric Motor Test Bench



A modular LabVIEW-based automated motor test bench developed to demonstrate test automation, data acquisition, industrial communication, safety monitoring, fault handling, and test data logging.



The application executes a multi-stage motor test sequence and evaluates simulated motor measurements against configurable acceptance and safety limits.



\## Key Features



\- Automated LabVIEW state-machine test sequence

\- 1000 RPM, 2000 RPM, and 3000 RPM test stages

\- Configurable load commands

\- Multiple measurement sources:

&#x20; - Software motor simulator

&#x20; - NI-DAQmx with simulated NI cDAQ hardware

&#x20; - Modbus TCP virtual motor controller

\- Modbus TCP command and measurement communication

\- TDMS measurement logging

\- Configurable acceptance limits

\- Independent safety-trip limits

\- Automatic system fault handling

\- Communication-loss detection

\- Controlled fault injection

\- Test failure latching

\- State-transition settling period

\- Industrial-style operator HMI



\## System Architecture



```text

&#x20;                    MotorTestBench\_Main.vi

&#x20;                             |

&#x20;             +---------------+---------------+

&#x20;             |               |               |

&#x20;             v               v               v

&#x20;       State Machine    Measurement       Test Control

&#x20;                         Selection

&#x20;                             |

&#x20;          +------------------+------------------+

&#x20;          |                  |                  |

&#x20;          v                  v                  v

&#x20;   Software Simulator     NI-DAQmx         Modbus TCP

&#x20;   MotorSimulator.vi      Acquisition      Communication

&#x20;          |                  |                  |

&#x20;          +------------------+------------------+

&#x20;                             |

&#x20;                             v

&#x20;                    MotorMeasurements.ctl

&#x20;                             |

&#x20;                             v

&#x20;                       InjectFaults.vi

&#x20;                             |

&#x20;                             v

&#x20;                   EvaluateMotorLimits.vi

&#x20;                             |

&#x20;            +----------------+----------------+

&#x20;            |                |                |

&#x20;            v                v                v

&#x20;           HMI          TDMS Logging      Fault Handling





\## Automated Test Sequence



IDLE

&#x20; |

&#x20; v

TEST\_1000\_RPM

1000 RPM / 25% Load

&#x20; |

&#x20; v

TEST\_2000\_RPM

2000 RPM / 50% Load

&#x20; |

&#x20; v

TEST\_3000\_RPM

3000 RPM / 75% Load

&#x20; |

&#x20; v

COMPLETE

