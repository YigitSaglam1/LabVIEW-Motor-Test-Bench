# Technical Architecture

This document explains the engineering structure of the LabVIEW Motor Test Bench and the decisions behind the implementation.

## 1. System Goal

The project is a software-driven electric-motor test bench intended to demonstrate a realistic automated test workflow without requiring physical motor or dynamometer hardware.

The application performs four main responsibilities:

1. sequence the test through predefined operating points,
2. acquire a common set of motor measurements from interchangeable sources,
3. evaluate both acceptance criteria and safety conditions,
4. log results and metadata for post-test review.

The design deliberately separates test-sequence behavior, measurement acquisition, fault injection, safety evaluation, and logging so each responsibility can be reasoned about independently.

## 2. High-Level Data Flow

```text
                         MotorTestBench_Main.vi
                                  |
                 +----------------+----------------+
                 |                                 |
                 v                                 v
          Test State Machine                 Command Generation
                 |                                 |
                 |                         RPM / Load Commands
                 |                                 |
                 +----------------+----------------+
                                  |
                                  v
                     Measurement Source Layer
                                  |
             +--------------------+--------------------+
             |                    |                    |
             v                    v                    v
      MotorSimulator.vi     NI-DAQmx Path       Modbus TCP Path
             |                    |                    |
             +--------------------+--------------------+
                                  |
                                  v
                        MotorMeasurements.ctl
                                  |
                                  v
                           InjectFaults.vi
                                  |
                                  v
                      Effective Measurements
                                  |
                     +------------+------------+
                     |                         |
                     v                         v
           EvaluateMotorLimits.vi     TDMS_LogMeasurements.vi
                     |
          +----------+----------+
          |                     |
          v                     v
   Acceptance Result       Safety Fault Request
          |                     |
          v                     v
   TEST FAILED latch       Global FAULT override
```

## 3. Test Executive

`MotorTestBench_Main.vi` contains the main test executive implemented as a LabVIEW state machine.

The states are:

```text
IDLE
TEST_1000_RPM
TEST_2000_RPM
TEST_3000_RPM
COMPLETE
FAULT
SHUTDOWN
```

Normal sequence:

```text
IDLE
 -> TEST_1000_RPM
 -> TEST_2000_RPM
 -> TEST_3000_RPM
 -> COMPLETE
```

Operating points:

| State | Commanded RPM | Load |
|---|---:|---:|
| TEST_1000_RPM | 1000 | 25% |
| TEST_2000_RPM | 2000 | 50% |
| TEST_3000_RPM | 3000 | 75% |

Each active test state runs for approximately five seconds.

The state machine determines commanded RPM/load and the normal next state. Safety logic is evaluated separately and can override the normal state transition by forcing the next state to `FAULT`.

This keeps normal sequence progression separate from emergency behavior.

## 4. State-Entry Detection and Timer Reset

A key implementation issue was that LabVIEW Elapsed Time Express VIs retain internal timing state between executions unless they are explicitly reset.

To make repeated tests behave correctly, the main loop stores the previous state and calculates:

```text
State Entered = Current State != Previous State
```

`State Entered` is TRUE for one loop iteration when the state changes.

That pulse resets the timing logic for the newly entered state. As a result, starting a second automated test does not inherit elapsed time from a previous run.

This behavior is covered by validation test T08.

## 5. Measurement Settling Window

The Modbus implementation introduced a realistic timing problem at operating-point changes.

When the state machine changes commanded RPM, the command is written immediately, but the returned feedback may still contain the previous operating point for one or more communication cycles. Evaluating RPM error during that short interval would create a false test failure.

The solution is a state-entry settling window.

For approximately the first 0.5 seconds after entering an active test state:

```text
Acceptance Enabled = FALSE
```

After the settling interval:

```text
Acceptance Enabled = TRUE
```

The test-failure latch therefore uses logic equivalent to:

```text
Eligible Failure = Current Sample Failed
                   AND Test Active
                   AND Acceptance Enabled
```

Safety evaluation is intentionally NOT disabled during the settling period.

This distinction is important: a normal feedback transient is allowed to settle, but an actual overcurrent, overtemperature, excessive-vibration condition, or communication error must still stop the system immediately.

This behavior is covered by validation test T09.

## 6. Common Measurement Interface

All acquisition paths produce the same `MotorMeasurements.ctl` typedef cluster.

Fields:

```text
Actual RPM
Temperature (degC)
Current (A)
Torque (Nm)
Vibration (mm/s)
```

The common typedef acts as an interface between acquisition and downstream processing.

Downstream code therefore does not need different safety, display, or logging implementations for each measurement source.

The selected source produces `Selected Measurements`, which then passes through fault injection to become `Effective Measurements`.

`Effective Measurements` is the data used by:

- safety and acceptance evaluation,
- HMI indicators,
- TDMS logging.

## 7. Measurement Sources

The application currently supports three selectable measurement sources.

### 7.1 Software Simulator

`MotorSimulator.vi` generates simplified motor behavior directly in LabVIEW.

It accepts:

```text
Commanded RPM
Load (%)
```

and produces the common measurement cluster.

The model is deliberately simple and is used to exercise the test executive, safety logic, logging, and HMI without external dependencies.

It is not intended to represent a validated physical motor model.

### 7.2 NI-DAQmx Path

The DAQ subsystem is separated into lifecycle VIs:

```text
DAQ_Initialize.vi
DAQ_ReadMeasurements.vi
SensorScaling.vi
DAQ_Shutdown.vi
```

Lifecycle:

```text
Create Task / Configure Channels
          |
          v
      Start Task
          |
          v
  Repeated DAQmx Read
          |
          v
      Stop Task
          |
          v
      Clear Task
```

Development used simulated NI hardware in NI MAX:

```text
NI cDAQ-9174
NI 9205
ai0:4
```

Channel mapping:

| Channel | Measurement |
|---|---|
| ai0 | Temperature |
| ai1 | Current |
| ai2 | Torque |
| ai3 | Vibration |
| ai4 | RPM |

`SensorScaling.vi` converts raw voltage values into engineering units using simplified transfer functions.

The NI-DAQmx path demonstrates acquisition architecture and task lifecycle. Physical NI hardware commissioning was not performed.

## 8. Modbus TCP Path

The Modbus subsystem is divided into:

```text
Modbus_Initialize.vi
Modbus_WriteCommands.vi
Modbus_ReadMeasurements.vi
Modbus_Shutdown.vi
```

The Modbus session is opened before the main loop, maintained across loop iterations, and closed during application shutdown.

Within the loop:

```text
Write RPM / Load Commands
          |
          v
Read Measurement Registers
          |
          v
Convert Register Scaling
          |
          v
MotorMeasurements.ctl
```

Development connection:

```text
IP Address : 127.0.0.1
Port       : 5020
Device ID  : 1
```

Register map:

| Address | Signal |
|---:|---|
| 0 | Commanded RPM |
| 1 | Load % |
| 2 | Actual RPM |
| 3 | Current x10 |
| 4 | Temperature x10 |
| 5 | Torque x10 |
| 6 | Vibration x10 |
| 7 | System Status |

The external virtual controller is implemented in Python with PyModbus.

A Modbus error is treated as a system-level fault only when `MODBUS_TCP` is the selected measurement source.

This prevents an inactive Modbus subsystem from incorrectly faulting a software-simulator or DAQ test.

## 9. Acceptance Logic vs Safety Logic

The project intentionally distinguishes a failed test from an unsafe system condition.

### Acceptance failure

Examples:

```text
RPM error above tolerance
Current above test acceptance limit
Temperature above test acceptance limit
Vibration above test acceptance limit
```

These conditions can latch:

```text
TEST FAILED = TRUE
```

while allowing the sequence to continue so the test can collect the remaining operating-point data.

### Safety fault

Examples:

```text
Current above safety trip
Temperature above safety trip
Vibration above safety trip
RPM sensor failure injection
Modbus communication loss
```

These conditions generate a system-fault request.

A global safety override forces:

```text
Next State = FAULT
Commanded RPM = 0
Load = 0
```

This separation allows the application to distinguish "the DUT failed a requirement" from "the test system must stop immediately."

## 10. Global Fault Arbitration

Multiple safety sources are combined into one global request.

Conceptually:

```text
Global System Fault Request =
    EvaluateMotorLimits safety request
    OR Injected System Fault
    OR Active-source Modbus Communication Fault
```

The global request is applied after the normal state-transition logic.

Conceptually:

```text
Normal Next State
       |
       v
     Select <---- Global System Fault Request
       |
       +---- FALSE -> Normal Next State
       |
       +---- TRUE  -> FAULT
```

This provides one clear arbitration point for system-level fault behavior.

## 11. Fault Injection

`InjectFaults.vi` operates between source selection and downstream evaluation.

Supported modes are defined in `FaultInjectionMode.ctl`:

```text
NONE
OVERCURRENT
OVERTEMPERATURE
HIGH_VIBRATION
RPM_SENSOR_FAILURE
```

Placing fault injection after measurement-source selection means the same safety system can be exercised regardless of where the original measurements came from.

For overcurrent, overtemperature, and high-vibration modes, the measurement is intentionally forced above the configured safety threshold and normal safety evaluation detects the trip.

RPM sensor failure forces Actual RPM to zero and also issues an injected system-fault request.

A synthetic communication-loss mode was not added because communication failure is tested by stopping the real Python Modbus server.

## 12. TDMS Logging

`TDMS_LogMeasurements.vi` receives `Effective Measurements` so logged data reflects the same values seen by the HMI and safety evaluator, including deliberately injected faults.

Logged channels:

```text
Actual_RPM
Torque_Nm
Current_A
Temperature_C
Vibration_mm_s
Timestamp
```

The application also records configuration and final-result information as TDMS properties.

The intended lifecycle is:

```text
TDMS Open
   |
   v
Repeated TDMS_LogMeasurements.vi calls
   |
   v
TDMS Set Properties
   |
   v
TDMS Close
```

Generated `.tdms` and `.tdms_index` files are ignored by Git. Evidence screenshots remain in `TestEvidence/`.

## 13. HMI Role

The front panel acts as the operator interface and provides:

- current state,
- test result,
- measurement-source selection,
- fault-injection selection,
- start/reset/stop controls,
- commanded operating point,
- live motor measurements,
- acceptance status,
- safety/fault status,
- Modbus status and configuration.

The HMI is downstream of the effective-measurement layer so displayed values match the measurements being evaluated and logged.

## 14. Error and Communication Handling

DAQ and Modbus subsystems use LabVIEW error clusters to preserve execution order and propagate failures through their lifecycle VIs.

For Modbus TCP, communication status is additionally converted into a system-fault request when Modbus is the active source.

Automatic Modbus reconnection is not implemented. After a communication-loss test, restarting the LabVIEW execution and Python server may be required to re-establish the session.

## 15. Validation Strategy

The project contains a separate [`VALIDATION.md`](VALIDATION.md) matrix rather than relying only on screenshots.

The documented scenarios cover:

1. normal software-simulator run,
2. normal Modbus TCP run,
3. overcurrent safety trip,
4. overtemperature safety trip,
5. high-vibration safety trip,
6. RPM sensor failure,
7. real Modbus communication loss,
8. repeated execution and timer reset,
9. Modbus transition settling.

This validates both normal sequencing and abnormal behavior.

## 16. Current Limitations

The project intentionally remains a portfolio-scale implementation.

Current limitations include:

- no physical motor or dynamometer,
- no physical NI DAQ commissioning,
- simplified motor and sensor models,
- no automatic Modbus reconnection,
- no CAN or EtherCAT implementation,
- no hardware-in-the-loop claim,
- acquisition subsystems may still execute even when their data is not selected,
- no production test database or report-generation backend.

These limitations are documented so the repository distinguishes implemented functionality from possible future extensions.

## 17. Possible Production Evolution

A larger production-oriented version could evolve toward:

```text
Configuration Layer
        |
        v
Test Executive
        |
        +------ Acquisition Actors / Modules
        |
        +------ DUT Communication Module
        |
        +------ Safety Supervisor
        |
        +------ Data Logger / Database
        |
        +------ Report Generator
        |
        +------ Operator HMI
```

Additional production features could include:

- configuration files for test definitions,
- automated reconnect/retry policies,
- hardware abstraction for multiple DAQ targets,
- database-backed test traceability,
- serial-number and DUT metadata handling,
- automated PDF/HTML test reports,
- unit and integration test infrastructure,
- CAN/CAN FD or EtherCAT communication where required,
- deployment to dedicated test-station hardware.

The current implementation provides the foundational concepts for those extensions while remaining small enough to understand and demonstrate end to end.
