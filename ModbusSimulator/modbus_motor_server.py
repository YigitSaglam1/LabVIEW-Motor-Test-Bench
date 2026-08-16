import asyncio

from pymodbus.server import ModbusTcpServer
from pymodbus.simulator import DataType, SimData, SimDevice


HOST = "127.0.0.1"
PORT = 5020
DEVICE_ID = 1
REGISTER_COUNT = 32


async def motor_update_task(server):
    while True:
        await asyncio.sleep(0.1)

        # Read commands written by LabVIEW
        commands = await server.async_getValues(
            DEVICE_ID,
            3,
            0,
            count=2,
        )

        commanded_rpm = commands[0]
        load_percent = commands[1]

        # Clamp load to a sensible range
        load_percent = min(load_percent, 100)

        load_fraction = load_percent / 100.0

        # Same simplified motor model used in LabVIEW
        torque = load_fraction * 30.0

        actual_rpm = commanded_rpm * (
            1.0 - 0.015 * load_fraction
        )

        current = 1.5 + torque * 0.35

        temperature = (
            25.0
            + 0.004 * actual_rpm
            + 25.0 * load_fraction
        )

        vibration = 0.5 + 3.0 * load_fraction

        # Status bit 0:
        # 0 = idle
        # 1 = running
        system_status = 1 if commanded_rpm > 0 else 0

        measurement_registers = [
            int(round(actual_rpm)),
            int(round(current * 10)),
            int(round(temperature * 10)),
            int(round(torque * 10)),
            int(round(vibration * 10)),
            system_status,
        ]

        # Write registers 2...7
        await server.async_setValues(
            DEVICE_ID,
            3,
            2,
            measurement_registers,
        )


async def main():
    registers = SimData(
        address=0,
        datatype=DataType.REGISTERS,
        values=[0] * REGISTER_COUNT,
    )

    device = SimDevice(
        DEVICE_ID,
        registers,
    )

    server = ModbusTcpServer(
        device,
        address=(HOST, PORT),
    )

    update_task = asyncio.create_task(
        motor_update_task(server)
    )

    print("Virtual Motor Controller")
    print(f"Address: {HOST}:{PORT}")
    print(f"Device ID: {DEVICE_ID}")
    print("Registers: 0-31")
    print("Dynamic motor simulation enabled")
    print("Press Ctrl+C to stop.")

    try:
        await server.serve_forever()
    finally:
        update_task.cancel()


if __name__ == "__main__":
    asyncio.run(main())