# Setup and Run Guide

This guide explains how to reproduce the software-only test bench environment and run the project without physical motor hardware.

## 1. Required Software

- LabVIEW 2026
- NI-DAQmx compatible with the installed LabVIEW version
- NI MAX
- Plasmionique Modbus Master for the LabVIEW Modbus TCP VIs
- Python 3
- Git

The repository records LabVIEW 2026 as the project version in `MotorTestBench.dragon`.

The Python virtual controller uses:

```text
pymodbus==3.14.0
```

## 2. Clone the Repository

```powershell
git clone https://github.com/YigitSaglam1/LabVIEW-Motor-Test-Bench.git
cd LabVIEW-Motor-Test-Bench
```

## 3. Configure the Simulated NI-DAQmx Path

The project was developed with a simulated NI CompactDAQ system in NI MAX.

Create or configure the following simulated hardware:

- NI cDAQ-9174 chassis
- NI 9205 analog-input module
- analog-input channels `ai0:4`

Expected channel mapping:

| Channel | Measurement |
|---|---|
| ai0 | Temperature |
| ai1 | Current |
| ai2 | Torque |
| ai3 | Vibration |
| ai4 | RPM |

The DAQ path is intended to validate acquisition architecture and data plumbing. The simulated NI signals do not represent calibrated physical motor measurements.

## 4. Configure the Python Modbus Virtual Controller

From the repository root:

```powershell
cd ModbusSimulator
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

Start the server:

```powershell
.\.venv\Scripts\python.exe modbus_motor_server.py
```

Default development connection:

```text
IP Address : 127.0.0.1
Port       : 5020
Device ID  : 1
```

Keep this PowerShell window open while using `MODBUS_TCP` as the measurement source.

## 5. Open the LabVIEW Project

Open:

```text
MotorTestBench.lvproj
```

Then open:

```text
MotorTestBench_Main.vi
```

The main VI is the operator-facing application and test executive.

## 6. Run with the Software Simulator

This is the simplest path because it does not require NI-DAQmx input data or the Python Modbus server.

Set:

```text
Measurement Source = SOFTWARE_SIMULATOR
Fault Injection    = NONE
```

Run the VI and press `START TEST`.

Expected sequence:

```text
IDLE
 -> TEST_1000_RPM
 -> TEST_2000_RPM
 -> TEST_3000_RPM
 -> COMPLETE
```

A normal run should finish with:

```text
Test Result = PASS
TEST FAILED = FALSE
SYSTEM FAULT = FALSE
```

## 7. Run with Modbus TCP

First start `modbus_motor_server.py` as described above.

In the LabVIEW application set:

```text
Measurement Source = MODBUS_TCP
Fault Injection    = NONE
IP Address         = 127.0.0.1
Port               = 5020
Slave / Device ID  = 1
```

Start the test.

LabVIEW writes RPM and load commands to the Python virtual controller and reads the resulting motor measurements back through Modbus TCP.

## 8. Exercise Fault Handling

With the software simulator selected, choose one of the supported fault modes:

```text
OVERCURRENT
OVERTEMPERATURE
HIGH_VIBRATION
RPM_SENSOR_FAILURE
```

Safety faults should force the test executive to `FAULT` and command RPM/load to zero.

To test a real communication failure, run in `MODBUS_TCP` mode and stop the Python server during an active test. The application should detect the communication error and enter `FAULT`.

## 9. TDMS Output

During execution the application logs motor measurements and test metadata to TDMS.

Logged channels include:

- `Actual_RPM`
- `Torque_Nm`
- `Current_A`
- `Temperature_C`
- `Vibration_mm_s`
- `Timestamp`

Generated TDMS data files are ignored by Git. Evidence screenshots are kept in `TestEvidence/`.

## 10. Validation Reference

See [`VALIDATION.md`](VALIDATION.md) for the documented validation matrix covering normal operation, safety faults, communication loss, repeated execution, and transition settling.

## Scope and Limitations

This repository demonstrates test-automation software architecture and workflow. The motor model and sensor transfer functions are simplified simulations.

Physical motor/dynamometer commissioning and physical NI DAQ hardware commissioning were not performed.